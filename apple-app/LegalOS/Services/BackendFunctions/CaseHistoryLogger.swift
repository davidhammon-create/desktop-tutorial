//
//  CaseHistoryLogger.swift
//  Schreibt Audit-Trail-Einträge (CaseHistory) für jeden Fall-Wechsel.
//  1:1 Port von base44/functions/logCaseChange/entry.ts.
//

import Foundation

@MainActor
public final class CaseHistoryLogger: ObservableObject {
    private let cloudKit: CloudKitService
    private let auth:     AuthService
    public init(cloudKit: CloudKitService, auth: AuthService) {
        self.cloudKit = cloudKit; self.auth = auth
    }

    public func log(caseId: String,
                    entityType: CaseHistoryEntityType,
                    action: CaseHistoryAction,
                    entityId: String? = nil,
                    entityTitle: String? = nil,
                    fieldChanged: String? = nil,
                    oldValue: String? = nil,
                    newValue: String? = nil,
                    summary: String? = nil) async {
        var hist = CaseHistory(caseId: caseId, entityType: entityType, action: action)
        hist.entityId = entityId
        hist.entityTitle = entityTitle
        hist.fieldChanged = fieldChanged
        hist.oldValue = oldValue
        hist.newValue = newValue
        hist.summary = summary
        hist.userEmail = auth.currentUser?.email
        hist.timestamp = Date()
        _ = try? await cloudKit.save(hist)
    }
}
