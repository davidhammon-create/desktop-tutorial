//
//  IcalExportService.swift
//  Generiert iCal-Datei (.ics) für alle Fristen eines Falls oder global.
//  1:1 Port von base44/functions/exportIcal/entry.ts.
//  Zusätzlich: direkter Apple-Kalender-Import via EventKit.
//

import Foundation
import EventKit
import AppKit

@MainActor
public enum IcalExportService {

    /// Erstellt einen iCal-String (.ics) aus einer Liste von Fristen.
    public static func generate(deadlines: [Deadline], caseName: String? = nil) -> String {
        let now = Date()
        let stamp = utcCompactDateTime(now)

        let calName = caseName.map { "Fristen – \($0)" } ?? "Alle Rechtsfristen"

        var ics = ""
        ics += "BEGIN:VCALENDAR\r\n"
        ics += "VERSION:2.0\r\n"
        ics += "PRODID:-//LegalOS//DE\r\n"
        ics += "CALSCALE:GREGORIAN\r\n"
        ics += "METHOD:PUBLISH\r\n"
        ics += "X-WR-CALNAME:\(escape(calName))\r\n"
        ics += "X-WR-CALDESC:Automatisch generiert von LegalOS\r\n"

        for d in deadlines {
            let uid = "frist-\(d.id)@legalos"
            let dateStr = utcCompactDate(d.dueDate)
            let alarmDate = Calendar.current.date(byAdding: .day, value: -3, to: d.dueDate) ?? d.dueDate
            let alarmStr = utcCompactDate(alarmDate)

            let statusEmoji: String = {
                switch d.status {
                case .erledigt: return " ✓"
                case .versaeumt: return " ⚠"
                case .offen:    return ""
                }
            }()
            let summary = escape("⚖️ \(d.title)\(statusEmoji)")

            var descParts: [String] = []
            if let v = d.fristType    { descParts.append("Typ: \(v)") }
            if let v = d.paragraph    { descParts.append("Paragraph: \(v)") }
            if let v = d.responsible  { descParts.append("Verantwortlich: \(v)") }
            descParts.append("Seite: \(d.side.rawValue)")
            descParts.append("Status: \(d.status.rawValue)")
            if let v = d.prognoseabzug { descParts.append("Prognoseabzug: \(v)") }
            let desc = escape(descParts.joined(separator: "\\n"))

            let icalStatus = d.status == .erledigt ? "COMPLETED" : "CONFIRMED"

            ics += "BEGIN:VEVENT\r\n"
            ics += "UID:\(uid)\r\n"
            ics += "DTSTAMP:\(stamp)\r\n"
            ics += "DTSTART;VALUE=DATE:\(dateStr)\r\n"
            ics += "DTEND;VALUE=DATE:\(dateStr)\r\n"
            ics += "SUMMARY:\(summary)\r\n"
            ics += "DESCRIPTION:\(desc)\r\n"
            ics += "STATUS:\(icalStatus)\r\n"
            ics += "BEGIN:VALARM\r\n"
            ics += "TRIGGER;VALUE=DATE-TIME:\(alarmStr)T090000Z\r\n"
            ics += "ACTION:DISPLAY\r\n"
            ics += "DESCRIPTION:Erinnerung: \(summary)\r\n"
            ics += "END:VALARM\r\n"
            ics += "END:VEVENT\r\n"
        }
        ics += "END:VCALENDAR\r\n"
        return ics
    }

    /// Speichert iCal-Datei via NSSavePanel.
    public static func saveToFile(_ ics: String, defaultName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.calendarEvent]
        panel.nameFieldStringValue = defaultName
        if panel.runModal() == .OK, let url = panel.url {
            try? ics.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    /// Direkt-Import in Apple Kalender via EventKit.
    public static func importIntoAppleCalendar(deadlines: [Deadline]) async throws {
        let store = EKEventStore()
        let granted = try await store.requestFullAccessToEvents()
        guard granted else { return }
        guard let cal = store.defaultCalendarForNewEvents else { return }

        for d in deadlines {
            let event = EKEvent(eventStore: store)
            event.title = "⚖️ \(d.title)"
            event.startDate = d.dueDate
            event.endDate   = d.dueDate.addingTimeInterval(3600)
            event.isAllDay  = true
            event.calendar  = cal
            event.notes = [
                d.fristType.map    { "Typ: \($0)" },
                d.paragraph.map    { "Paragraph: \($0)" },
                d.responsible.map  { "Verantwortlich: \($0)" },
                "Status: \(d.status.rawValue)",
                "Seite: \(d.side.rawValue)"
            ].compactMap { $0 }.joined(separator: "\n")

            // Alarm 3 Tage vorher
            event.addAlarm(EKAlarm(relativeOffset: -3 * 24 * 3600))
            try store.save(event, span: .thisEvent)
        }
    }

    // MARK: - Helpers
    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: ";", with: "\\;")
         .replacingOccurrences(of: ",", with: "\\,")
         .replacingOccurrences(of: "\n", with: "\\n")
    }

    private static func utcCompactDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"; f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: d)
    }
    private static func utcCompactDateTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"; f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: d)
    }
}
