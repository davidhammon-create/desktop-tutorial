//
//  ZeitleisteView.swift
//  Globale Zeitleiste über alle Fälle. Entspricht src/pages/Zeitleiste.jsx.
//

import SwiftUI

struct ZeitleisteView: View {
    @EnvironmentObject var cloudKit: CloudKitService

    @State private var events: [TimelineEvent] = []
    @State private var deadlines: [Deadline] = []
    @State private var loading = false

    private var combined: [(date: Date, title: String, kind: String, color: Color)] {
        let e = events.map { (date: $0.date, title: $0.title, kind: $0.category.rawValue, color: Color.blue) }
        let d = deadlines.map { (date: $0.dueDate, title: $0.title, kind: "Frist", color: Color.orange) }
        return (e + d).sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if loading && combined.isEmpty {
                    ProgressView().padding()
                } else if combined.isEmpty {
                    ContentUnavailableView("Keine Ereignisse",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Noch keine Zeitleisten-Einträge oder Fristen vorhanden."))
                        .padding(.top, 60)
                } else {
                    ForEach(Array(combined.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 12) {
                            VStack {
                                Circle().fill(item.color).frame(width: 10, height: 10)
                                Rectangle().fill(.secondary.opacity(0.3)).frame(width: 2)
                            }
                            .frame(width: 16)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(item.title).font(.body.weight(.medium))
                                Text(item.kind).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Zeitleiste")
        .task { await reload() }
        .refreshable { await reload() }
    }

    @MainActor
    private func reload() async {
        loading = true; defer { loading = false }
        events    = (try? await cloudKit.fetch(TimelineEvent.self)) ?? []
        deadlines = (try? await cloudKit.fetch(Deadline.self)) ?? []
    }
}
