//
//  AuthService.swift
//  Eigene Authentifizierung – ohne BASE44.
//
//  Funktionen:
//  - Registrieren mit Email + Passwort (lokal SHA256 + Salt gehasht, in CloudKit gespeichert)
//  - Login per Email/Passwort
//  - Sign in with Apple (über AuthenticationServices)
//  - Session-Persistenz im Keychain
//

import Foundation
import CryptoKit
import CloudKit
import AuthenticationServices
import Combine

@MainActor
public final class AuthService: NSObject, ObservableObject {

    @Published public private(set) var currentUser: AppUser?
    @Published public private(set) var isBusy: Bool = false
    @Published public var lastError: String?

    private let keychainAccount  = "de.legalos.session"
    private let keychainService  = "LegalOS"
    private let container        = CKContainer.default()

    public override init() {
        super.init()
    }

    // MARK: - Public API

    /// Versucht eine bestehende Session aus dem Keychain wiederherzustellen.
    public func restoreSession() async {
        guard let data = Keychain.read(service: keychainService, account: keychainAccount),
              let user = try? JSONDecoder().decode(AppUser.self, from: data) else { return }
        self.currentUser = user
        // Optional: aktuellen User-Stand aus CloudKit nachladen.
        await refreshUser(id: user.id)
    }

    /// Registriert einen neuen Nutzer und speichert ihn in CloudKit.
    public func register(email: String, password: String, fullName: String?) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let salt = Self.randomSalt()
            let hash = Self.hash(password: password, salt: salt)
            var user = AppUser(email: email.lowercased())
            user.fullName = fullName
            user.passwordSalt = salt
            user.passwordHash = hash

            let record = user.toRecord()
            let saved = try await container.publicCloudDatabase.save(record)
            let stored = AppUser(record: saved)
            self.currentUser = stored
            persist(user: stored)
        } catch {
            lastError = "Registrierung fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    /// Login per Email + Passwort.
    public func login(email: String, password: String) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let predicate = NSPredicate(format: "email == %@", email.lowercased())
            let query = CKQuery(recordType: AppUser.recordType, predicate: predicate)
            let (matches, _) = try await container.publicCloudDatabase.records(matching: query, resultsLimit: 1)
            guard let first = matches.first,
                  case .success(let record) = first.1 else {
                lastError = "Benutzer nicht gefunden."
                return
            }
            let user = AppUser(record: record)
            guard let salt = user.passwordSalt,
                  let hash = user.passwordHash,
                  Self.hash(password: password, salt: salt) == hash else {
                lastError = "Passwort falsch."
                return
            }
            self.currentUser = user
            persist(user: user)
        } catch {
            lastError = "Login fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    /// Logout & Keychain-Eintrag löschen.
    public func logout() {
        currentUser = nil
        Keychain.delete(service: keychainService, account: keychainAccount)
    }

    /// Aktualisiert ein User-Profil in CloudKit.
    public func updateProfile(_ updated: AppUser) async {
        do {
            let saved = try await container.publicCloudDatabase.save(updated.toRecord())
            let stored = AppUser(record: saved)
            self.currentUser = stored
            persist(user: stored)
        } catch {
            lastError = "Profil-Update fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    /// Markiert Onboarding als abgeschlossen.
    public func completeOnboarding(jurisdiction: Jurisdiction, disclaimerAccepted: Bool) async {
        guard var u = currentUser else { return }
        u.jurisdiction = jurisdiction
        u.disclaimerAccepted = disclaimerAccepted
        u.onboardingDone = true
        await updateProfile(u)
    }

    // MARK: - Sign in with Apple

    /// Verarbeitet das Resultat von `SignInWithAppleButton`.
    public func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let err):
            lastError = "Apple Sign-In abgebrochen: \(err.localizedDescription)"
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            let appleId = credential.user
            let email   = credential.email ?? ""
            let name    = [credential.fullName?.givenName, credential.fullName?.familyName]
                            .compactMap { $0 }.joined(separator: " ")
            await loginOrCreateApple(appleUserId: appleId, email: email, fullName: name.isEmpty ? nil : name)
        }
    }

    private func loginOrCreateApple(appleUserId: String, email: String, fullName: String?) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let predicate = NSPredicate(format: "apple_user_id == %@", appleUserId)
            let query = CKQuery(recordType: AppUser.recordType, predicate: predicate)
            let (matches, _) = try await container.publicCloudDatabase.records(matching: query, resultsLimit: 1)
            if let first = matches.first, case .success(let record) = first.1 {
                let user = AppUser(record: record)
                self.currentUser = user
                persist(user: user)
                return
            }
            // Sonst: neuen User anlegen
            var user = AppUser(email: email)
            user.appleUserId = appleUserId
            user.fullName = fullName
            let saved = try await container.publicCloudDatabase.save(user.toRecord())
            let stored = AppUser(record: saved)
            self.currentUser = stored
            persist(user: stored)
        } catch {
            lastError = "Apple-Login fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private func refreshUser(id: String) async {
        do {
            let record = try await container.publicCloudDatabase.record(for: .init(recordName: id))
            let user = AppUser(record: record)
            self.currentUser = user
        } catch {
            // Schweigend: User-Cache bleibt erhalten.
        }
    }

    private func persist(user: AppUser) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        Keychain.write(service: keychainService, account: keychainAccount, data: data)
    }

    // MARK: - Crypto

    private static func randomSalt(length: Int = 16) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return Data(bytes).base64EncodedString()
    }

    private static func hash(password: String, salt: String) -> String {
        let input = (salt + password).data(using: .utf8) ?? Data()
        let digest = SHA256.hash(data: input)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Keychain Wrapper

enum Keychain {
    static func write(service: String, account: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     service,
            kSecAttrAccount as String:     account
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrService as String:  service,
            kSecAttrAccount as String:  account,
            kSecReturnData as String:   true,
            kSecMatchLimit as String:   kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrService as String:  service,
            kSecAttrAccount as String:  account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
