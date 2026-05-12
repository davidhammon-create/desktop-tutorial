//
//  RichterProfileView.swift
//  Verwaltung von Richter-, Anwalts- und Kanzlei-Profilen.
//

import SwiftUI

struct RichterProfileView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var profiles: [JudgeProfile] = []
    @State private var search = ""
    @State private var showNew = false

    private var filtered: [JudgeProfile] {
        guard !search.isEmpty else { return profiles }
        return profiles.filter {
            $0.name.localizedCaseInsensitiveContains(search) ||
            $0.gericht.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        List {
            ForEach(filtered) { p in
                NavigationLink {
                    JudgeDetailView(profile: p)
                } label: {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(p.name).font(.body.weight(.medium))
                            Spacer()
                            Text(p.kategorie.rawValue).font(.caption).foregroundStyle(.secondary)
                        }
                        Text(p.gericht).font(.caption).foregroundStyle(.secondary)
                        if let k = p.klaegerRate {
                            Text("Klägerquote: \(Int(k)) %").font(.caption2)
                        }
                    }
                }
            }
        }
        .searchable(text: $search)
        .navigationTitle("Richter-Profile")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNew = true } label: { Label("Neu", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showNew) {
            NewJudgeSheet { j in
                Task { _ = try? await cloudKit.save(j); await reload() }
            }
        }
        .task { await reload() }
        .refreshable { await reload() }
    }

    @MainActor
    private func reload() async {
        profiles = (try? await cloudKit.fetch(JudgeProfile.self)) ?? []
    }
}

struct JudgeDetailView: View {
    let profile: JudgeProfile
    var body: some View {
        Form {
            Section("Stammdaten") {
                LabeledContent("Name", value: profile.name)
                LabeledContent("Kategorie", value: profile.kategorie.rawValue)
                LabeledContent("Gericht", value: profile.gericht)
                if let k = profile.kammer { LabeledContent("Kammer", value: k) }
                if let r = profile.rechtsgebiet { LabeledContent("Rechtsgebiet", value: r) }
                if let s = profile.stil { LabeledContent("Stil", value: s.rawValue) }
            }
            Section("Kennzahlen") {
                if let k = profile.klaegerRate { LabeledContent("Klägerquote", value: "\(Int(k)) %") }
                if let v = profile.vergleichRate { LabeledContent("Vergleichsrate", value: "\(Int(v)) %") }
                if let d = profile.durchschnittDauerMonate { LabeledContent("Ø Dauer", value: "\(Int(d)) Mon.") }
                if let u = profile.urteileGesamt { LabeledContent("Urteile", value: "\(Int(u))") }
            }
            if let n = profile.notizen, !n.isEmpty {
                Section("Notizen") { Text(n) }
            }
        }
        .navigationTitle(profile.name)
    }
}

struct NewJudgeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var gericht = ""
    @State private var kategorie: JudgeKategorie = .richter
    var onCreate: (JudgeProfile) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Gericht / Institution", text: $gericht)
                Picker("Kategorie", selection: $kategorie) {
                    ForEach(JudgeKategorie.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
            }
            .navigationTitle("Neues Profil")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") {
                        var p = JudgeProfile(name: name, gericht: gericht)
                        p.kategorie = kategorie
                        onCreate(p); dismiss()
                    }.disabled(name.isEmpty || gericht.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
            }
        }
    }
}
