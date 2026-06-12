//
//  DeadlineAlertService.swift
//  Native macOS Notifications via UserNotifications für anstehende Fristen.
//  Ersetzt base44/functions/deadlineEmailAlert (Email → System-Push).
//

import Foundation
import UserNotifications

@MainActor
public enum DeadlineAlertService {

    /// Fragt einmalig die Notification-Berechtigung an.
    public static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Plant für jede offene Frist eine lokale Notification 3 / 1 / 0 Tage vorher.
    public static func scheduleAlerts(for deadlines: [Deadline], caseName: String) async {
        let center = UNUserNotificationCenter.current()
        for d in deadlines where d.status == .offen {
            for offsetDays in [3, 1, 0] {
                guard let trigger = makeTrigger(for: d.dueDate, offsetDays: offsetDays) else { continue }
                let content = UNMutableNotificationContent()
                content.title = "⚖️ \(d.title)"
                content.subtitle = caseName
                content.body = offsetDays == 0
                    ? "HEUTE fällig!"
                    : "Fällig in \(offsetDays) Tag\(offsetDays == 1 ? "" : "en") – \(formattedDate(d.dueDate))"
                content.sound = .default
                let id = "deadline-\(d.id)-\(offsetDays)"
                let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                try? await center.add(req)
            }
        }
    }

    /// Entfernt ggf. alte geplante Notifications für eine Frist.
    public static func cancelAlerts(for deadlineId: String) {
        let ids = [3, 1, 0].map { "deadline-\(deadlineId)-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func makeTrigger(for date: Date, offsetDays: Int) -> UNCalendarNotificationTrigger? {
        guard let target = Calendar.current.date(byAdding: .day, value: -offsetDays, to: date),
              target > Date() else { return nil }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: target)
        comps.hour = 9; comps.minute = 0
        return UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
    }

    private static func formattedDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium; f.locale = Locale(identifier: "de_DE")
        return f.string(from: d)
    }
}
