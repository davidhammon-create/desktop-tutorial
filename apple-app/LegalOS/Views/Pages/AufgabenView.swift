//
//  AufgabenView.swift
//  Globale Aufgabenliste über alle Fälle.
//

import SwiftUI

struct AufgabenView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var tasks: [LegalTask] = []
    @State private var showNew = false
    @State private var filter: TaskStatus? = nil

    private var filtered: [LegalTask] {
        guard let f = filter else { return tasks }
        return tasks.filter { $0.status == f }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                FilterChip(title: "Alle", active: filter == nil) { filter = nil }
                ForEach(TaskStatus.allCases, id: \.self) { s in
                    FilterChip(title: s.rawValue.replacingOccurrences(of: "_", with: " "),
                               active: filter == s) { filter = s }
                }
                Spacer()
            }
            .padding(.horizontal).padding(.vertical, 8)
            List {
                ForEach(filtered) { t in
                    HStack(alignment: .top) {
                        Button {
                            Task { await toggle(t) }
                        } label: {
                            Image(systemName: t.status == .erledigt ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(t.status == .erledigt ? .green : .secondary)
                        }
                        .buttonStyle(.plain)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.title).strikethrough(t.status == .erledigt)
                            if let n = t.caseName { Text(n).font(.caption).foregroundStyle(.secondary) }
                            if let d = t.dueDate {
                                Text(d.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        priorityBadge(t.priority)
                    }
                }
                .onDelete { idx in
                    Task {
                        for i in idx {
                            try? await cloudKit.delete(recordID: filtered[i].id)
                        }
                        await reload()
                    }
                }
            }
        }
        .navigationTitle("Aufgaben")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNew = true } label: { Label("Neu", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showNew) {
            NewTaskSheet { t in
                Task { _ = try? await cloudKit.save(t); await reload() }
            }
        }
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func priorityBadge(_ p: TaskPriority) -> some View {
        let color: Color = {
            switch p { case .hoch: return .red; case .mittel: return .orange; case .niedrig: return .blue }
        }()
        return Text(p.rawValue.capitalized)
            .font(.caption2)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }

    @MainActor
    private func reload() async {
        tasks = (try? await cloudKit.fetch(LegalTask.self)) ?? []
    }

    @MainActor
    private func toggle(_ t: LegalTask) async {
        var copy = t
        copy.status = (t.status == .erledigt) ? .offen : .erledigt
        _ = try? await cloudKit.save(copy)
        await reload()
    }
}

struct NewTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var dueDate: Date = Date().addingTimeInterval(7 * 86400)
    @State private var prio: TaskPriority = .mittel
    var onCreate: (LegalTask) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Titel", text: $title)
                DatePicker("Fällig am", selection: $dueDate, displayedComponents: .date)
                Picker("Priorität", selection: $prio) {
                    ForEach(TaskPriority.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
            }
            .navigationTitle("Neue Aufgabe")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") {
                        var t = LegalTask(title: title)
                        t.dueDate = dueDate
                        t.priority = prio
                        onCreate(t); dismiss()
                    }.disabled(title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}
