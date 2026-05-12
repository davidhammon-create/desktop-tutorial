//
//  LexaraDashboardView.swift
//  Fall-Übersicht (Kacheln + Filter) – ersetzt src/pages/LexaraDashboard.jsx.
//

import SwiftUI

struct LexaraDashboardView: View {
    @EnvironmentObject var cloudKit: CloudKitService

    @State private var cases: [Case] = []
    @State private var folders: [CaseFolder] = []
    @State private var search: String = ""
    @State private var statusFilter: CaseStatus? = nil
    @State private var loading = false
    @State private var showNewCase = false

    private var filteredCases: [Case] {
        cases.filter { c in
            let okStatus = statusFilter == nil || c.status == statusFilter
            let okSearch = search.isEmpty
                || c.fallname.localizedCaseInsensitiveContains(search)
                || (c.aktenzeichen ?? "").localizedCaseInsensitiveContains(search)
            return okStatus && okSearch
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                filterBar
                if loading && cases.isEmpty {
                    ProgressView().padding()
                } else if filteredCases.isEmpty {
                    ContentUnavailableView("Keine Fälle gefunden",
                                           systemImage: "folder.badge.questionmark",
                                           description: Text("Lege einen neuen Fall an, um zu starten."))
                        .padding(.top, 60)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                        ForEach(filteredCases) { c in
                            NavigationLink(value: c) { CaseCardView(caseEntity: c) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("LEXARA Dashboard")
        .navigationDestination(for: Case.self) { c in CaseDetailView(caseId: c.id) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNewCase = true } label: { Label("Neuer Fall", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showNewCase) {
            NewCaseSheet { c in
                Task { _ = try? await cloudKit.save(c); await reload() }
            }
        }
        .task { await reload() }
        .refreshable { await reload() }
    }

    private var filterBar: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Fall, Aktenzeichen, Mandant…", text: $search)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))

            HStack {
                FilterChip(title: "Alle", active: statusFilter == nil) { statusFilter = nil }
                ForEach(CaseStatus.allCases, id: \.self) { s in
                    FilterChip(title: s.rawValue, active: statusFilter == s) { statusFilter = s }
                }
                Spacer()
            }
        }
    }

    @MainActor
    private func reload() async {
        loading = true
        defer { loading = false }
        cases   = (try? await cloudKit.fetch(Case.self)) ?? []
        folders = (try? await cloudKit.fetch(CaseFolder.self)) ?? []
    }
}

struct CaseCardView: View {
    let caseEntity: Case

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(caseEntity.fallname).font(.headline).lineLimit(2)
                Spacer()
                Text(caseEntity.status.rawValue).font(.caption).padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
            }
            if let az = caseEntity.aktenzeichen { Text("Az: \(az)").font(.caption).foregroundStyle(.secondary) }
            if let m  = caseEntity.mandantName { Text(m).font(.caption).foregroundStyle(.secondary) }
            if let p  = caseEntity.prognose {
                ProgressView(value: p / 100)
                    .tint(p >= 60 ? .green : (p >= 40 ? .orange : .red))
                Text("Prognose: \(Int(p)) %").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct FilterChip: View {
    let title: String
    let active: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(active ? Color.accentColor : Color.gray.opacity(0.15), in: Capsule())
                .foregroundStyle(active ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct NewCaseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var aktenzeichen = ""
    @State private var mandant = ""
    @State private var rechtsgebiet = ""
    var onCreate: (Case) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Fallname", text: $name)
                TextField("Aktenzeichen (optional)", text: $aktenzeichen)
                TextField("Mandant", text: $mandant)
                TextField("Rechtsgebiet", text: $rechtsgebiet)
            }
            .navigationTitle("Neuer Fall")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") {
                        var c = Case(fallname: name)
                        c.aktenzeichen = aktenzeichen.isEmpty ? nil : aktenzeichen
                        c.mandantName  = mandant.isEmpty ? nil : mandant
                        c.rechtsgebiet = rechtsgebiet.isEmpty ? nil : rechtsgebiet
                        onCreate(c)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}
