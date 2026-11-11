import Foundation
import UserNotifications
import EventKit
import CoreSpotlight
import UniformTypeIdentifiers
@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()
    private let notificationCenter = UNUserNotificationCenter.current()
    private let eventStore = EKEventStore()
    @Published var kalenderZugriff = false
    @Published var benachrichtigungsZugriff = false
    private init() {
        Task { await berechtigungenAnfordern() }
    }
    func berechtigungenAnfordern() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            benachrichtigungsZugriff = granted
        } catch {}
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .notDetermined {
            do {
                kalenderZugriff = try await eventStore.requestFullAccessToEvents()
            } catch {}
        } else {
            kalenderZugriff = status == .fullAccess
        }
    }
    func fristAlarmPlanen(frist: Deadline, tageVorher: Int = 3) async {
        guard benachrichtigungsZugriff else { return }
        if let id = frist.id {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        }
        guard frist.status == .offen else { return }
        let alarmdatum = Calendar.current.date(
            byAdding: .day,
            value: -tageVorher,
            to: frist.due_date
        ) ?? frist.due_date
        guard alarmdatum > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "⚖️ Frist naht: \(frist.title)"
        content.body = "Fällig am \(frist.due_date.formatted(date: .abbreviated, time: .omitted)). Noch \(frist.tageVerbleibend) Tage."
        content.sound = .default
        content.categoryIdentifier = "FRIST_ALARM"
        content.userInfo = [
            "case_id": frist.case_id,
            "deadline_id": frist.id ?? ""
        ]
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alarmdatum)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: frist.id ?? UUID().uuidString,
            content: content,
            trigger: trigger
        )
        try? await notificationCenter.add(request)
    }
    func alleAlarmeNeuPlanen(fristen: [Deadline]) async {
        notificationCenter.removeAllPendingNotificationRequests()
        for frist in fristen where frist.status == .offen {
            await fristAlarmPlanen(frist: frist)
        }
    }
    func fristInKalenderEintragen(frist: Deadline, fallname: String) async throws {
        guard kalenderZugriff else {
            throw NotificationFehler.kalenderZugriffVerweigert
        }
        let event = EKEvent(eventStore: eventStore)
        event.title = "⚖️ \(frist.title)"
        event.notes = """
        Fall: \(fallname)
        Fristtyp: \(frist.frist_type.rawValue)
        Wichtigkeit: \(frist.wichtigkeit.rawValue)
        Erstellt von FenlynineOS
        """
        event.startDate = frist.due_date
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: frist.due_date)
        event.addAlarm(EKAlarm(relativeOffset: -3 * 24 * 3600))
        event.addAlarm(EKAlarm(relativeOffset: -24 * 3600))
        event.calendar = eventStore.defaultCalendarForNewEvents
        try eventStore.save(event, span: .thisEvent)
    }
    func allesFristenInKalender(fristen: [Deadline], fallname: String) async throws {
        for frist in fristen where frist.status == .offen {
            try await fristInKalenderEintragen(frist: frist, fallname: fallname)
        }
    }
    func icalDateiExportieren(fristen: [Deadline]) -> String {
        var ical = "BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//Håmmon & Partner//FenlynineOS Legal Suite//DE\n"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime, .withTimeZone]
        for frist in fristen {
            ical += "BEGIN:VEVENT\n"
            ical += "UID:\(frist.id ?? UUID().uuidString)\n"
            guard let ende = Calendar.current.date(byAdding: .hour, value: 1, to: frist.due_date) else { continue }
            ical += "DTSTART:\(formatter.string(from: frist.due_date))\n"
            ical += "DTEND:\(formatter.string(from: ende))\n"
            ical += "SUMMARY:⚖️ \(frist.title)\n"
            ical += "DESCRIPTION:Fristtyp: \(frist.frist_type.rawValue)\\nWichtigkeit: \(frist.wichtigkeit.rawValue)\n"
            ical += "END:VEVENT\n"
        }
        ical += "END:VCALENDAR"
        return ical
    }
    func fallIndexieren(fall: LegalCase) {
        guard let id = fall.id else { return }
        let attributeSet = CSSearchableItemAttributeSet(contentType: .item)
        attributeSet.title = fall.fallname
        attributeSet.contentDescription = [
            fall.aktenzeichen.map { "Az: \($0)" },
            fall.rechtsgebiet,
            fall.gericht,
            fall.status.rawValue
        ].compactMap { $0 }.joined(separator: " · ")
        attributeSet.keywords = [
            fall.rechtsgebiet,
            fall.status.rawValue,
            fall.instanz.rawValue,
            fall.mandant_name
        ].compactMap { $0 }
        let item = CSSearchableItem(
            uniqueIdentifier: "fenlynineos.fall.\(id)",
            domainIdentifier: "com.fenlynineos.faelle",
            attributeSet: attributeSet
        )
        item.expirationDate = .distantFuture
        CSSearchableIndex.default().indexSearchableItems([item]) { _ in }
    }
    func fallAusIndexEntfernen(id: String) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: ["fenlynineos.fall.\(id)"]
        ) { _ in }
    }
    func alleFaelleIndexieren(faelle: [LegalCase]) {
        faelle.forEach { fallIndexieren(fall: $0) }
    }
    func badgeAktualisieren(kritischeFristen: Int) {
        Task {
            try? await UNUserNotificationCenter.current().setBadgeCount(kritischeFristen)
        }
    }
}
enum NotificationFehler: LocalizedError {
    case kalenderZugriffVerweigert
    case benachrichtigungsZugriffVerweigert
    var errorDescription: String? {
        switch self {
        case .kalenderZugriffVerweigert: return "Kein Zugriff auf Kalender. Bitte in den Systemeinstellungen freigeben."
        case .benachrichtigungsZugriffVerweigert: return "Benachrichtigungen deaktiviert. Bitte in Systemeinstellungen aktivieren."
        }
    }
}
