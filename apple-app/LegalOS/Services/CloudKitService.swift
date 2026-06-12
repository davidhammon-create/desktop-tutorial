//
//  CloudKitService.swift
//  Generischer CRUD-Service auf Basis von CloudKit (iCloud).
//
//  Nutzt die Standard-Container (.default()) – bei eigenem Container die
//  Bundle-ID in Info.plist / CloudKit Capability anpassen.
//

import Foundation
import CloudKit
import Combine

/// Protocol, das jedes CloudKit-fähige Model implementieren muss.
public protocol CKMappable: Identifiable {
    static var recordType: String { get }
    init(record: CKRecord)
    func toRecord() -> CKRecord
}

extension Case:                CKMappable {}
extension AppUser:             CKMappable {}
extension Person:              CKMappable {}
extension Argument:            CKMappable {}
extension Evidence:            CKMappable {}
extension Deadline:            CKMappable {}
extension LegalDocument:       CKMappable {}
extension JudgeProfile:        CKMappable {}
extension CaseHistory:         CKMappable {}
extension StrategosScenario:   CKMappable {}
extension LegalTask:           CKMappable {}
extension TimelineEvent:       CKMappable {}
extension LegalLoophole:       CKMappable {}
extension GegnerVerhalten:     CKMappable {}
extension CaseFolder:          CKMappable {}
extension CaseQuestionnaire:   CKMappable {}
extension CaseWarning:         CKMappable {}
extension KIUsageLog:          CKMappable {}
extension JurisdictionInsight: CKMappable {}
extension AIPerformanceFeedback: CKMappable {}

public enum CloudKitScope {
    case publicScope
    case privateScope
}

@MainActor
public final class CloudKitService: ObservableObject {

    public let container: CKContainer
    @Published public var lastError: String?

    public init(containerIdentifier: String? = nil) {
        if let id = containerIdentifier {
            self.container = CKContainer(identifier: id)
        } else {
            self.container = CKContainer.default()
        }
    }

    private func db(_ scope: CloudKitScope) -> CKDatabase {
        switch scope {
        case .publicScope:  return container.publicCloudDatabase
        case .privateScope: return container.privateCloudDatabase
        }
    }

    // MARK: - CRUD

    /// Speichert (Insert oder Update) eine Entität.
    @discardableResult
    public func save<T: CKMappable>(_ entity: T, scope: CloudKitScope = .privateScope) async throws -> T {
        let record = entity.toRecord()
        let saved  = try await db(scope).save(record)
        return T(record: saved)
    }

    /// Lädt alle Records eines Typs mit optionalem Predicate (default = alle).
    public func fetch<T: CKMappable>(_ type: T.Type,
                                     predicate: NSPredicate = NSPredicate(value: true),
                                     scope: CloudKitScope = .privateScope,
                                     limit: Int = 200) async throws -> [T] {
        let query = CKQuery(recordType: T.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let (matches, _) = try await db(scope).records(matching: query, resultsLimit: limit)
        return matches.compactMap { _, result in
            guard case .success(let record) = result else { return nil }
            return T(record: record)
        }
    }

    /// Lädt eine einzelne Entität anhand ihrer ID.
    public func fetchOne<T: CKMappable>(_ type: T.Type, id: String, scope: CloudKitScope = .privateScope) async throws -> T? {
        let recordID = CKRecord.ID(recordName: id)
        do {
            let record = try await db(scope).record(for: recordID)
            return T(record: record)
        } catch {
            return nil
        }
    }

    /// Löscht eine Entität anhand ihrer ID.
    public func delete(recordID id: String, scope: CloudKitScope = .privateScope) async throws {
        try await db(scope).deleteRecord(withID: CKRecord.ID(recordName: id))
    }

    /// Convenience: alle Records eines Falls.
    public func fetchForCase<T: CKMappable>(_ type: T.Type,
                                            caseId: String,
                                            scope: CloudKitScope = .privateScope) async throws -> [T] {
        let predicate = NSPredicate(format: "case_id == %@", caseId)
        return try await fetch(type, predicate: predicate, scope: scope)
    }
}
