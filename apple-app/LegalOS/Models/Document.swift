//
//  Document.swift
//  Dokument-Entität (Schriftsatz, Vertrag, Beweis-Datei).
//

import Foundation
import CloudKit

public struct LegalDocument: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var title: String
    public var fileUrl: String?
    public var fileType: String?
    public var docDescription: String?
    public var aiSummary: String?
    public var extractedArguments: [String] = []
    /// KI-Rohdaten als JSON-String.
    public var aiRawJSON: String?

    public init(caseId: String, title: String) {
        self.caseId = caseId
        self.title = title
    }
}

public extension LegalDocument {
    static let recordType = "Document"

    init(record: CKRecord) {
        self.id                 = record.recordID.recordName
        self.caseId             = record["case_id"] as? String ?? ""
        self.title              = record["title"] as? String ?? ""
        self.fileUrl            = record["file_url"] as? String
        self.fileType           = record["file_type"] as? String
        self.docDescription     = record["description"] as? String
        self.aiSummary          = record["ai_summary"] as? String
        self.extractedArguments = record["extracted_arguments"] as? [String] ?? []
        self.aiRawJSON          = record["ai_raw"] as? String
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]             = caseId as CKRecordValue
        r["title"]               = title as CKRecordValue
        r["file_url"]            = fileUrl as CKRecordValue?
        r["file_type"]           = fileType as CKRecordValue?
        r["description"]         = docDescription as CKRecordValue?
        r["ai_summary"]          = aiSummary as CKRecordValue?
        r["extracted_arguments"] = extractedArguments as CKRecordValue
        r["ai_raw"]              = aiRawJSON as CKRecordValue?
        return r
    }
}
