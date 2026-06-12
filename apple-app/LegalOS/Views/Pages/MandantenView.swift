//
//  MandantenView.swift
//  Mandanten-/Ordner-Übersicht.
//

import SwiftUI

struct MandantenView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var folders: [CaseFolder] = []
    @State private var cases: [Case] = []
    @State private var showNew = false

    var body: some View {
        List {
            ForEach(folders) { f in
                let related = cases.filter { $0.folderId == f.id }
                Section(header: HStack {
                    Image(systemName: "person.crop.rectangle")
                    Text(f.mandantName ?? f.name)
                    Spacer()
                    Text(f.mandantTyp.rawValue).font(.caption).foregroundStyle(.secondary)
                }) {
                    if related.isEmpty {
                        Text("Keine Fälle").font(.caption).foregroundStyle(.secondary)
                    }
                    ForEach(related) { c in
                        NavigationLink(value: c) {
                            VStack(alignment: .leading) {
                                Text(c.fallname)
                                if let az = c.aktenzeichen {
                                    Text(az).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Mandanten")
        .navigationDestination(for: Case.self) { c in CaseDetailView(caseId: c.id) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNew = true } label: { Label("Neu", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showNew) {
            NewMandantSheet { folder in
                Task { _ = try? await cloudKit.save(folder); await reload() }
            }
        }
        .task { await reload() }
        .refreshable { await reload() }
    }

    @MainActor
    private func reload() async {
        folders = (try? await cloudKit.fetch(CaseFolder.self)) ?? []
        cases   = (try? await cloudKit.fetch(Case.self)) ?? []
    }
}

struct NewMandantSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var typ: MandantTyp = .privatperson
    @State private var email = ""
    var onCreate: (CaseFolder) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Picker("Typ", selection: $typ) {
                    ForEach(MandantTyp.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                TextField("E-Mail", text: $email)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    #endif
            }
            .navigationTitle("Neuer Mandant")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") {
                        var f = CaseFolder(name: name)
                        f.mandantName = name
                        f.mandantTyp = typ
                        f.mandantEmail = email.isEmpty ? nil : email
                        onCreate(f); dismiss()
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
