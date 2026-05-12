//
//  CaseFolder.swift
//  Mandanten-Ordner, der mehrere Fälle gruppiert.
//

import Foundation
import CloudKit

public enum MandantTyp: String, Codable, CaseIterable, Hashable {
    case privatperson = "Privatperson"
    case unternehmen  = "Unternehmen"
    case behoerde     = "Behörde"
    case sonstiges    = "Sonstiges"
}

public struct CaseFolder: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var name: String
    public var color: String?
    public var mandantName: String?
    public var mandantEmail: String?
    public var mandantTyp: MandantTyp = .privatperson
    public var folderDescription: String?

    public init(name: String) { self.name = name }
}

public extension CaseFolder {
    static let recordType = "CaseFolder"

    init(record: CKRecord) {
        self.id            = record.recordID.recordName
        self.name          = record["name"] as? String ?? ""
        self.color         = record["color"] as? String
        self.mandantName   = record["mandant_name"] as? String
        self.mandantEmail  = record["mandant_email"] as? String
        self.mandantTyp    = MandantTyp(rawValue: record["mandant_typ"] as? String ?? "Privatperson") ?? .privatperson
        self.folderDescription = record["description"] as? String
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["name"]          = name as CKRecordValue
        r["color"]         = color as CKRecordValue?
        r["mandant_name"]  = mandantName as CKRecordValue?
        r["mandant_email"] = mandantEmail as CKRecordValue?
        r["mandant_typ"]   = mandantTyp.rawValue as CKRecordValue
        r["description"]   = folderDescription as CKRecordValue?
        return r
    }
}
