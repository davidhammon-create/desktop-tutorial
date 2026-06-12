//
//  MandantUpdateService.swift
//  Versendet Updates an Mandanten via System-Mailer (NSWorkspace).
//  Ersetzt base44/functions/sendMandantUpdate (kein Server, native macOS).
//

import Foundation
import AppKit

@MainActor
public enum MandantUpdateService {

    /// Öffnet das Standard-Mailprogramm mit vorausgefüllter Update-Mail.
    public static func sendUpdate(toMandant mandant: Person,
                                  caseEntity: Case,
                                  betreff: String,
                                  inhalt: String) {
        let to = (mandant.organization ?? mandant.name)
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let subj = "[\(caseEntity.fallname)] \(betreff)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = """
        Sehr geehrte/r \(mandant.name),

        \(inhalt)

        Aktueller Stand:
        - Status: \(caseEntity.status.rawValue)
        - Aktenzeichen: \(caseEntity.aktenzeichen ?? "—")
        - Gericht: \(caseEntity.gericht ?? "—")
        - Erfolgsprognose: \(Int(caseEntity.prognose ?? 0))%

        Mit freundlichen Grüßen
        Ihr Anwalt
        """.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(to)?subject=\(subj)&body=\(body)") {
            NSWorkspace.shared.open(url)
        }
    }
}
