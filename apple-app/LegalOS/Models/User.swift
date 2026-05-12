//
//  User.swift
//  Benutzer-Entität – kombiniert Auth-Daten (Email, Passwort-Hash) und
//  Profil-Daten (Jurisdiction, KI-Credits, Onboarding-Status).
//

import Foundation
import CloudKit

public enum UserRole: String, Codable, Hashable {
    case admin
    case user
}

public enum Jurisdiction: String, Codable, CaseIterable, Hashable {
    case dach          = "DACH"
    case us            = "US"
    case eu            = "EU"
    case international = "International"
}

public struct AppUser: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var email: String
    /// SHA256(salt + password)
    public var passwordHash: String?
    /// Salt für lokales Passwort-Hashing.
    public var passwordSalt: String?
    /// Apple-Sub-ID, falls Sign in with Apple genutzt wurde.
    public var appleUserId: String?
    public var fullName: String?
    public var role: UserRole = .user
    public var language: String = "de"
    public var jurisdiction: Jurisdiction = .dach
    public var usState: String = ""
    public var disclaimerAccepted: Bool = false
    public var onboardingDone: Bool = false
    public var hasModuleAccess: Bool = false
    public var kiCredits: Int = 50
    public var createdAt: Date = Date()

    public init(email: String) {
        self.email = email
    }
}

public extension AppUser {
    static let recordType = "User"

    init(record: CKRecord) {
        self.id                 = record.recordID.recordName
        self.email              = record["email"] as? String ?? ""
        self.passwordHash       = record["password_hash"] as? String
        self.passwordSalt       = record["password_salt"] as? String
        self.appleUserId        = record["apple_user_id"] as? String
        self.fullName           = record["full_name"] as? String
        self.role               = UserRole(rawValue: record["role"] as? String ?? "user") ?? .user
        self.language           = record["language"] as? String ?? "de"
        self.jurisdiction       = Jurisdiction(rawValue: record["jurisdiction"] as? String ?? "DACH") ?? .dach
        self.usState            = record["us_state"] as? String ?? ""
        self.disclaimerAccepted = (record["disclaimer_accepted"] as? Int ?? 0) == 1
        self.onboardingDone     = (record["onboarding_done"] as? Int ?? 0) == 1
        self.hasModuleAccess    = (record["has_module_access"] as? Int ?? 0) == 1
        self.kiCredits          = record["ki_credits"] as? Int ?? 0
        self.createdAt          = record.creationDate ?? Date()
    }

    func toRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["email"]               = email as CKRecordValue
        record["password_hash"]       = passwordHash as CKRecordValue?
        record["password_salt"]       = passwordSalt as CKRecordValue?
        record["apple_user_id"]       = appleUserId as CKRecordValue?
        record["full_name"]           = fullName as CKRecordValue?
        record["role"]                = role.rawValue as CKRecordValue
        record["language"]            = language as CKRecordValue
        record["jurisdiction"]        = jurisdiction.rawValue as CKRecordValue
        record["us_state"]            = usState as CKRecordValue
        record["disclaimer_accepted"] = (disclaimerAccepted ? 1 : 0) as CKRecordValue
        record["onboarding_done"]     = (onboardingDone ? 1 : 0) as CKRecordValue
        record["has_module_access"]   = (hasModuleAccess ? 1 : 0) as CKRecordValue
        record["ki_credits"]          = kiCredits as CKRecordValue
        return record
    }
}
