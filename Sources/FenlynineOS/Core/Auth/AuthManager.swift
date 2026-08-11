import Foundation
import SwiftUI

// MARK: - Auth-Manager

@MainActor
final class AuthManager: ObservableObject {
static let shared = AuthManager()

@Published var isAuthenticated: Bool = false
/// Nur beim App-Start (Session prüfen) -- nicht während Login/Register (sonst verschwindet Onboarding).
@Published var isInitializingSession: Bool = true
@Published var currentUser: User? = nil
@Published var error: String? = nil
@Published var geraeteModusAktiv: Bool = AppDefaults.geraeteModusAktiv

private let client = Base44Client.shared
private let defaults = UserDefaults.standard

private init() {
  if AppDefaults.geraeteModusAktiv {
    Task { await bootstrapGeraeteModus() }
  } else {
    Task { await checkExistingSession() }
  }
}

// MARK: - Geräte-Modus (Mac = Account, Fälle lokal, KI über Base44)

func bootstrapGeraeteModus() async {
  isInitializingSession = true
  defer { isInitializingSession = false }

  var config = Base44Config(
    appId: AppDefaults.base44AppId,
    appBaseUrl: AppDefaults.base44BaseUrl,
    accessToken: FenlynineOSKeychain.get(account: .base44AccessToken),
    functionsVersion: nil
  )
  await client.updateConfig(config)

  await LocalDataStore.shared.initialize(deviceId: DeviceIdentity.id)
  await DemoDataSeeder.seedIfNeeded()

  // Base44-Token vor UI-Start (Functions wie analyzeDocument brauchen Auth).
  await DeviceAuthService.ensureBase44Session(authManager: self)

  currentUser = Self.geraeteBenutzer()
  isAuthenticated = true
}

func refreshBase44SessionIfPossible() async {
  await client.syncConfigFromStorage()
  guard let token = FenlynineOSKeychain.get(account: .base44AccessToken), !token.isEmpty else { return }
  do {
    var config = Base44Config.load()
    config.accessToken = token
    await client.updateConfig(config)
    if let user = try? await fetchCurrentUser() {
      currentUser = user
    }
  } catch {
    FenlynineOSKeychain.delete(account: .base44AccessToken)
    var config = Base44Config.load()
    config.accessToken = nil
    await client.updateConfig(config)
  }
}

private static func geraeteBenutzer() -> User {
  User(email: DeviceIdentity.base44Email, name: DeviceIdentity.anzeigeName)
}

// MARK: - Session-Prüfung

func checkExistingSession() async {
  isInitializingSession = true
  defer { isInitializingSession = false }

  await client.syncConfigFromStorage()

  guard let token = FenlynineOSKeychain.get(account: .base44AccessToken), !token.isEmpty else {
    isAuthenticated = false
    return
  }

  do {
    var config = Base44Config.load()
    config.accessToken = token
    await client.updateConfig(config)
    let user = try await fetchCurrentUser()
    self.currentUser = user
    self.isAuthenticated = true
  } catch {
    self.isAuthenticated = false
    FenlynineOSKeychain.delete(account: .base44AccessToken)
  }
}

// MARK: - Anmelden
//
// SDK: POST /apps/{appId}/auth/login -> { access_token, user }

func login(email: String, password: String) async throws {
 error = nil
 await client.ensureReady()
 let config = Base44Config.load()

 guard !config.appId.isEmpty else {
   let msg = "Base44 App-ID fehlt. Bitte im ersten Schritt eintragen."
   error = msg
   throw Base44Error.serverError(msg)
 }

 let url = config.authURL("login")

 struct LoginRequest: Encodable {
   let email: String
   let password: String
 }

 let response: AuthLoginResponse = try await client.post(url, body: LoginRequest(email: email, password: password))

 FenlynineOSKeychain.set(response.access_token, account: .base44AccessToken)

 var newConfig = config
 newConfig.accessToken = response.access_token
 await client.updateConfig(newConfig)

 if let user = response.user {
   self.currentUser = user
 } else {
   self.currentUser = try? await fetchCurrentUser()
 }
 if !AppDefaults.geraeteModusAktiv {
   self.isAuthenticated = true
 }
}

// MARK: - Registrieren
//
// SDK: POST /apps/{appId}/auth/register -> OTP, danach loginViaEmailPassword

func register(email: String, password: String, name: String, kanzlei: String?) async throws {
 error = nil
 await client.ensureReady()
 let config = Base44Config.load()

 guard !config.appId.isEmpty else {
   let msg = "Base44 App-ID fehlt. Bitte im ersten Schritt eintragen."
   error = msg
   throw Base44Error.serverError(msg)
 }

 let url = config.authURL("register")

 struct RegisterRequest: Encodable {
   let email: String
   let password: String
   let name: String?
   let kanzlei: String?
 }

 let _: EmptyResponse = try await client.post(url, body: RegisterRequest(
   email: email, password: password, name: name.isEmpty ? nil : name, kanzlei: kanzlei
 ))

 // Nach Registrierung direkt anmelden (OTP-Flow ggf. per E-Mail)
 try await login(email: email, password: password)
}

// MARK: - Abmelden

func logout() {
 FenlynineOSKeychain.delete(account: .base44AccessToken)
 error = nil

 var config = Base44Config.load()
 config.accessToken = nil
 Task { await client.updateConfig(config) }

 if AppDefaults.geraeteModusAktiv {
   currentUser = Self.geraeteBenutzer()
   isAuthenticated = true
 } else {
   currentUser = nil
   isAuthenticated = false
 }
}

// MARK: - Passwort zurücksetzen
//
// SDK: POST /apps/{appId}/auth/reset-password-request

func resetPassword(email: String) async throws {
 await client.syncConfigFromStorage()
 let url = Base44Config.load().authURL("reset-password-request")
 struct ResetRequest: Encodable { let email: String }
 let _: EmptyResponse = try await client.post(url, body: ResetRequest(email: email))
}

// MARK: - Profil aktualisieren

func updateProfile(name: String?, kanzlei: String?) async throws {
 guard var user = currentUser, let id = user.id else { return }
 if let name { user.name = name }
 if let kanzlei { user.kanzlei = kanzlei }
 let updated = try await Services.users.update(id: id, entity: user)
 self.currentUser = updated
}

// MARK: - Hilfsmethoden

private func fetchCurrentUser() async throws -> User {
 await client.syncConfigFromStorage()
 let url = Base44Config.load().meURL
 return try await client.get(url)
}

// MARK: - Benutzer-Properties

var userEmail: String { currentUser?.email ?? "" }
var userName: String { currentUser?.name ?? currentUser?.email ?? "Benutzer" }
var userPlan: User.UserPlan { currentUser?.plan ?? .free }

var hatPremium: Bool {
 switch userPlan {
 case .professional, .enterprise: return true
 default: return false
 }
}
}

// MARK: - Auth API Antwort (robust gegen User-Decode-Fehler)

private struct AuthLoginResponse: Decodable {
let access_token: String
let user: User?

init(from decoder: Decoder) throws {
 let c = try decoder.container(keyedBy: CodingKeys.self)
 access_token = try c.decode(String.self, forKey: .access_token)
 user = try? c.decode(User.self, forKey: .user)
}

enum CodingKeys: String, CodingKey {
 case access_token, user
}
}

// MARK: - App-State (globaler Zustand)

@MainActor
final class AppState: ObservableObject {
static let shared = AppState()

@Published var selectedJurisdiction: String = UserDefaults.standard.string(forKey: "jurisdiction") ?? "DE"
@Published var selectedSprache: String = UserDefaults.standard.string(forKey: "sprache") ?? "de"
@Published var isDarkMode: Bool = UserDefaults.standard.bool(forKey: "dark_mode")
@Published var selectedCaseId: String? = nil
@Published var navigationPfad: [NavigationsZiel] = []
@Published var globalError: String? = nil
@Published var globalSuccess: String? = nil

enum NavigationsZiel: Hashable {
 case dashboard
 case lexara
 case fall(String)
 case richterprofile
 case analytik
 case cockpit
 case strategos
 case kiChat
 case aufgaben
 case zeitleiste
 case compliance
 case einstellungen
}

func navigateToCase(_ id: String) {
 selectedCaseId = id
 NotificationCenter.default.post(name: .navigateToCase, object: id)
}

func navigateToSidebar(_ eintrag: SeitenleistenEintrag) {
 NotificationCenter.default.post(name: .navigateToSidebar, object: eintrag.rawValue)
}

func setJurisdiction(_ code: String) {
 selectedJurisdiction = code
 UserDefaults.standard.set(code, forKey: "jurisdiction")
}

func showError(_ message: String) {
 globalError = message
 Task {
   try? await Task.sleep(for: .seconds(4))
   globalError = nil
 }
}

func showSuccess(_ message: String) {
 globalSuccess = message
 Task {
   try? await Task.sleep(for: .seconds(3))
   globalSuccess = nil
 }
}
}

