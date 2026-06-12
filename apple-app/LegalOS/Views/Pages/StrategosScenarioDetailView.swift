//
//  StrategosScenarioDetailView.swift
//  6-stufiger Enterprise-Wizard für Strategos-Szenarien.
//  1:1 Port der base44 EnterpriseShell + Strategos-Wizard-Steps.
//  Steps: 1=Unternehmenskontext · 2=Situationsanalyse · 3=Szenario-Matrix
//         4=Aktionsplan · 5=Strategos-Empfehlung · 6=LEXARA-Sync
//

import SwiftUI

// MARK: - Datenstrukturen für Wizard-Steps

private struct Unternehmenskontext: Codable {
    var branche: String = ""
    var umsatz: String = ""
    var mitarbeiter: String = ""
    var beschreibung: String = ""
    var schluesselRisiken: [String] = []
    var rechtsgebiet: String = ""
    var gegner: String = ""
    var ausgangslage: String = ""
}

private struct SzenarioOption: Identifiable, Codable {
    var id: String = UUID().uuidString
    var buchstabe: String    // A, B, C
    var titel: String = ""
    var beschreibung: String = ""
    var vorteile: [String] = []
    var nachteile: [String] = []
    var erfolgswahrscheinlichkeit: Double = 50
    var kosten: String = ""
    var zeitrahmen: String = ""
    var empfohlen: Bool = false
}

private struct Aktionsschritt: Identifiable, Codable {
    var id: String = UUID().uuidString
    var prioritaet: Int = 1   // 1=Hoch, 2=Mittel, 3=Niedrig
    var titel: String = ""
    var verantwortlich: String = ""
    var frist: String = ""
    var status: String = "offen"
    var notizen: String = ""
}

private struct StrategosEmpfehlung: Codable {
    var empfohleneOption: String = ""
    var begruendung: String = ""
    var risikobewertung: String = ""
    var naechsteSchritte: [String] = []
    var warnhinweise: [String] = []
    var erfolgsprognose: Double = 50
}

private struct SituationsAnalyseResult: Codable {
    var staerken: [String] = []
    var schwaechen: [String] = []
    var chancen: [String] = []
    var risiken: [String] = []
    var zusammenfassung: String = ""
    var kritischeFaktoren: [String] = []
}

// MARK: - Hauptansicht

struct StrategosScenarioDetailView: View {
    @Binding var scenario: StrategosScenario
    var onSave: (StrategosScenario) -> Void

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider
    @EnvironmentObject var auth: AuthService

    @State private var currentStep: Int = 1
    @State private var kontext = Unternehmenskontext()
    @State private var situationsAnalyse: SituationsAnalyseResult?
    @State private var optionA = SzenarioOption(buchstabe: "A", titel: "Aggressive Strategie")
    @State private var optionB = SzenarioOption(buchstabe: "B", titel: "Moderate Strategie")
    @State private var optionC = SzenarioOption(buchstabe: "C", titel: "Konservative Strategie")
    @State private var aktionsplan: [Aktionsschritt] = []
    @State private var empfehlung: StrategosEmpfehlung?
    @State private var linkedCases: [Case] = []
    @State private var allCases: [Case] = []
    @State private var loading = false
    @State private var newRisiko = ""
    @State private var newSchritt = Aktionsschritt()

    private let stepTitles = [
        "Unternehmenskontext",
        "Situationsanalyse",
        "Szenario-Matrix",
        "Aktionsplan",
        "Strategos-Empfehlung",
        "LEXARA-Sync"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Step-Progressbar
            stepHeader

            Divider()

            // Aktiver Step-Inhalt
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch currentStep {
                    case 1: step1Kontext
                    case 2: step2Situationsanalyse
                    case 3: step3SzenarioMatrix
                    case 4: step4Aktionsplan
                    case 5: step5Empfehlung
                    case 6: step6LexaraSync
                    default: EmptyView()
                    }
                }
                .padding()
                .animation(.default, value: currentStep)
            }

            Divider()

            // Navigationsleiste
            stepFooter
        }
        .navigationTitle(scenario.title)
        .task {
            loadFromScenario()
            allCases = (try? await cloudKit.fetch(Case.self)) ?? []
        }
    }

    // MARK: - Step Header

    private var stepHeader: some View {
        VStack(spacing: 8) {
            // Schritt-Indikatoren
            HStack(spacing: 4) {
                ForEach(1...6, id: \.self) { s in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(stepCircleColor(s))
                            .frame(width: 28, height: 28)
                            .overlay {
                                if s < currentStep {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                } else {
                                    Text("\(s)").font(.caption.weight(.bold))
                                        .foregroundStyle(s == currentStep ? .white : .secondary)
                                }
                            }
                        Text(stepTitles[s-1])
                            .font(.system(size: 9))
                            .foregroundStyle(s == currentStep ? .primary : .secondary)
                            .lineLimit(1)
                            .frame(width: 80, alignment: .center)
                    }
                    if s < 6 {
                        Rectangle()
                            .fill(s < currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(height: 2)
                            .padding(.bottom, 20)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            // Aktueller Schritt-Titel
            Text("Schritt \(currentStep) von 6: \(stepTitles[currentStep-1])")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
        }
        .background(.regularMaterial)
    }

    private func stepCircleColor(_ s: Int) -> Color {
        if s < currentStep { return .green }
        if s == currentStep { return .accentColor }
        return Color.gray.opacity(0.25)
    }

    // MARK: - Step Footer

    private var stepFooter: some View {
        HStack {
            if currentStep > 1 {
                Button {
                    withAnimation { currentStep -= 1 }
                } label: {
                    Label("Zurück", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
            }
            Spacer()
            Text("\(Int(Double(currentStep-1)/5.0 * 100))%").font(.caption).foregroundStyle(.secondary)
            Spacer()
            if currentStep < 6 {
                Button {
                    saveToScenario()
                    withAnimation { currentStep += 1 }
                } label: {
                    Label("Weiter", systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    saveToScenario()
                    onSave(scenario)
                } label: {
                    Label("Abschließen", systemImage: "checkmark.seal.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.regularMaterial)
    }

    // MARK: - Step 1: Unternehmenskontext

    private var step1Kontext: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Unternehmens- und Fallkontext",
                          sub: "Grundlegende Informationen für die Strategie-Analyse.")

            GroupBox("Basisdaten") {
                VStack(spacing: 10) {
                    labeledField("Branche / Rechtsgebiet", text: $kontext.branche)
                    labeledField("Jahresumsatz (optional)", text: $kontext.umsatz)
                    labeledField("Mitarbeiterzahl (optional)", text: $kontext.mitarbeiter)
                    labeledField("Rechtsgebiet", text: $kontext.rechtsgebiet)
                }
            }

            GroupBox("Ausgangslage") {
                VStack(spacing: 10) {
                    labeledField("Gegner / Gegenpartei", text: $kontext.gegner)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ausgangslage & Sachverhalt").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $kontext.ausgangslage)
                            .frame(minHeight: 100)
                            .padding(6)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unternehmensbeschreibung").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $kontext.beschreibung)
                            .frame(minHeight: 80)
                            .padding(6)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            GroupBox("Schlüssel-Risiken") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(kontext.schluesselRisiken.enumerated()), id: \.offset) { (i, r) in
                        HStack {
                            Label(r, systemImage: "exclamationmark.triangle")
                                .font(.subheadline)
                            Spacer()
                            Button { kontext.schluesselRisiken.remove(at: i) } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(6)
                        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                    }
                    HStack {
                        TextField("Risiko hinzufügen…", text: $newRisiko)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            let r = newRisiko.trimmingCharacters(in: .whitespaces)
                            if !r.isEmpty { kontext.schluesselRisiken.append(r); newRisiko = "" }
                        } label: {
                            Image(systemName: "plus.circle.fill").foregroundStyle(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Step 2: Situationsanalyse

    private var step2Situationsanalyse: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Situationsanalyse (SWOT)",
                          sub: "KI analysiert Stärken, Schwächen, Chancen und Risiken.")

            Button {
                Task { await runSituationsanalyse() }
            } label: {
                Label(loading ? "Analysiere…" : "KI-Situationsanalyse starten",
                      systemImage: "brain.head.profile")
            }
            .buttonStyle(.borderedProminent)
            .disabled(loading || kontext.ausgangslage.isEmpty)

            if kontext.ausgangslage.isEmpty {
                Label("Bitte zuerst die Ausgangslage in Schritt 1 ausfüllen.",
                      systemImage: "arrow.left.circle")
                    .font(.caption).foregroundStyle(.orange)
            }

            if let sa = situationsAnalyse {
                if !sa.zusammenfassung.isEmpty {
                    GroupBox("Zusammenfassung") {
                        Text(sa.zusammenfassung).font(.body)
                    }
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    swotCard("Stärken", items: sa.staerken, color: .green,
                             icon: "arrow.up.circle.fill")
                    swotCard("Schwächen", items: sa.schwaechen, color: .orange,
                             icon: "arrow.down.circle.fill")
                    swotCard("Chancen", items: sa.chancen, color: .blue,
                             icon: "lightbulb.fill")
                    swotCard("Risiken", items: sa.risiken, color: .red,
                             icon: "exclamationmark.triangle.fill")
                }
                if !sa.kritischeFaktoren.isEmpty {
                    GroupBox("Kritische Erfolgsfaktoren") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(sa.kritischeFaktoren, id: \.self) { f in
                                Label(f, systemImage: "star.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                }
            }
        }
    }

    private func swotCard(_ title: String, items: [String], color: Color, icon: String) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                Label(title, systemImage: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
                if items.isEmpty {
                    Text("–").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(items, id: \.self) { item in
                        Text("• \(item)").font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Step 3: Szenario-Matrix

    private var step3SzenarioMatrix: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Szenario-Matrix",
                          sub: "Drei strategische Optionen mit KI-bewerteten Vor- und Nachteilen.")

            Button {
                Task { await runSzenarioMatrix() }
            } label: {
                Label(loading ? "Generiere…" : "KI-Szenario-Matrix generieren",
                      systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .disabled(loading)

            ForEach([$optionA, $optionB, $optionC], id: \.buchstabe) { $opt in
                optionCard(opt: $opt)
            }
        }
    }

    private func optionCard(opt: Binding<SzenarioOption>) -> some View {
        let o = opt.wrappedValue
        return GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(o.buchstabe)
                        .font(.title2.weight(.black))
                        .frame(width: 36, height: 36)
                        .background(
                            o.buchstabe == "A" ? Color.red :
                            o.buchstabe == "B" ? Color.blue : Color.green,
                            in: Circle()
                        )
                        .foregroundStyle(.white)
                    VStack(alignment: .leading) {
                        TextField("Titel", text: opt.titel)
                            .font(.headline)
                        if o.empfohlen {
                            Label("Empfohlen", systemImage: "star.fill")
                                .font(.caption2).foregroundStyle(.yellow)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(Int(o.erfolgswahrscheinlichkeit))%")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(o.erfolgswahrscheinlichkeit >= 60 ? .green :
                                             o.erfolgswahrscheinlichkeit >= 40 ? .orange : .red)
                        Text("Erfolg").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                TextField("Beschreibung", text: opt.beschreibung, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                HStack(spacing: 16) {
                    if !o.vorteile.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Vorteile").font(.caption.weight(.bold)).foregroundStyle(.green)
                            ForEach(o.vorteile, id: \.self) {
                                Text("+ \($0)").font(.caption2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !o.nachteile.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nachteile").font(.caption.weight(.bold)).foregroundStyle(.red)
                            ForEach(o.nachteile, id: \.self) {
                                Text("− \($0)").font(.caption2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                HStack {
                    if !o.kosten.isEmpty {
                        Label(o.kosten, systemImage: "eurosign").font(.caption2)
                    }
                    if !o.zeitrahmen.isEmpty {
                        Label(o.zeitrahmen, systemImage: "clock").font(.caption2)
                    }
                }
            }
        }
    }

    // MARK: - Step 4: Aktionsplan

    private var step4Aktionsplan: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Aktionsplan",
                          sub: "Priorisierte Maßnahmen für die Umsetzung.")

            HStack {
                Button {
                    Task { await generateAktionsplan() }
                } label: {
                    Label(loading ? "Generiere…" : "KI-Aktionsplan", systemImage: "sparkles")
                }
                .buttonStyle(.bordered)
                .disabled(loading)

                Button {
                    aktionsplan.append(Aktionsschritt())
                } label: {
                    Label("Manuell", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            if aktionsplan.isEmpty {
                ContentUnavailableView("Kein Aktionsplan",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Generiere einen KI-Aktionsplan oder füge Schritte manuell hinzu."))
            } else {
                ForEach($aktionsplan) { $s in
                    aktionsschrittRow(schritt: $s)
                }
            }
        }
    }

    private func aktionsschrittRow(schritt: Binding<Aktionsschritt>) -> some View {
        let s = schritt.wrappedValue
        return HStack(alignment: .top, spacing: 12) {
            // Prioritäts-Badge
            ZStack {
                Circle().fill(prioritaetColor(s.prioritaet))
                    .frame(width: 28, height: 28)
                Text("\(s.prioritaet)").font(.caption.weight(.bold)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                TextField("Maßnahme", text: schritt.titel)
                    .font(.subheadline.weight(.medium))
                    .textFieldStyle(.roundedBorder)
                HStack {
                    TextField("Verantwortlich", text: schritt.verantwortlich)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                    TextField("Frist", text: schritt.frist)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                    Picker("Status", selection: schritt.status) {
                        ForEach(["offen","in Bearbeitung","erledigt"], id: \.self) { Text($0).tag($0) }
                    }
                    .font(.caption)
                    .pickerStyle(.menu)
                }
            }
            Spacer()
            Button {
                aktionsplan.removeAll { $0.id == s.id }
            } label: {
                Image(systemName: "trash").foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private func prioritaetColor(_ p: Int) -> Color {
        switch p {
        case 1: return .red
        case 2: return .orange
        default: return .gray
        }
    }

    // MARK: - Step 5: Strategos-Empfehlung

    private var step5Empfehlung: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Strategos-Empfehlung",
                          sub: "Finale KI-gestützte strategische Empfehlung.")

            Button {
                Task { await generateEmpfehlung() }
            } label: {
                Label(loading ? "Generiere…" : "Finale Empfehlung generieren",
                      systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .disabled(loading)

            if let emp = empfehlung {
                // Empfohlene Option
                if !emp.empfohleneOption.isEmpty {
                    GroupBox {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Empfohlene Option").font(.caption).foregroundStyle(.secondary)
                                Text("Option \(emp.empfohleneOption)")
                                    .font(.title.weight(.bold)).foregroundStyle(.accentColor)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(Int(emp.erfolgsprognose))%")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.green)
                                Text("Erfolgsprognose").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Begründung
                if !emp.begruendung.isEmpty {
                    GroupBox("Begründung") {
                        Text(emp.begruendung).font(.body)
                    }
                }

                // Risikobewertung
                if !emp.risikobewertung.isEmpty {
                    GroupBox("Risikobewertung") {
                        Text(emp.risikobewertung).font(.subheadline)
                            .padding(8)
                            .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }

                // Nächste Schritte
                if !emp.naechsteSchritte.isEmpty {
                    GroupBox("Nächste Schritte") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(emp.naechsteSchritte.enumerated()), id: \.offset) { (i, s) in
                                HStack(alignment: .top) {
                                    Text("\(i+1).")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.accentColor)
                                    Text(s).font(.subheadline)
                                }
                            }
                        }
                    }
                }

                // Warnhinweise
                if !emp.warnhinweise.isEmpty {
                    GroupBox("Warnhinweise") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(emp.warnhinweise, id: \.self) { w in
                                Label(w, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption).foregroundStyle(.orange)
                            }
                        }
                    }
                }
            } else {
                Text("Generiere die finale Strategos-Empfehlung um alle vorherigen Schritte zusammenzufassen.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Step 6: LEXARA-Sync

    private var step6LexaraSync: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("LEXARA-Sync",
                          sub: "Verknüpfe dieses Szenario mit konkreten Falldateien in LEXARA.")

            GroupBox("Zusammenfassung") {
                VStack(alignment: .leading, spacing: 6) {
                    infoRow2("Szenario", scenario.title)
                    infoRow2("Typ", scenario.szenarioTyp.label)
                    infoRow2("Status", scenario.status.rawValue)
                    if let emp = empfehlung, !emp.empfohleneOption.isEmpty {
                        infoRow2("Empfehlung", "Option \(emp.empfohleneOption) (\(Int(emp.erfolgsprognose))%)")
                    }
                    infoRow2("Aktionsschritte", "\(aktionsplan.count)")
                }
            }

            if allCases.isEmpty {
                Text("Keine Fälle vorhanden. Lege erst Fälle in LEXARA an.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                GroupBox("Mit Fällen verknüpfen") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(allCases) { c in
                            let linked = linkedCases.contains(where: { $0.id == c.id })
                            HStack {
                                Image(systemName: linked
                                    ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(linked ? .green : .secondary)
                                VStack(alignment: .leading) {
                                    Text(c.fallname).font(.subheadline)
                                    Text(c.rechtsgebiet ?? c.status.rawValue)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let p = c.prognose {
                                    Text("\(Int(p))%").font(.caption)
                                        .foregroundStyle(p >= 60 ? .green : .orange)
                                }
                            }
                            .padding(8)
                            .background(linked ? Color.green.opacity(0.06) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if linked {
                                    linkedCases.removeAll { $0.id == c.id }
                                } else {
                                    linkedCases.append(c)
                                }
                            }
                        }
                    }
                }
            }

            if !linkedCases.isEmpty {
                Label("\(linkedCases.count) Fall/Fälle verknüpft", systemImage: "link")
                    .font(.caption).foregroundStyle(.green)
            }

            GroupBox("Export") {
                HStack(spacing: 12) {
                    Button {
                        exportPDF()
                    } label: {
                        Label("PDF exportieren", systemImage: "arrow.down.doc.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func infoRow2(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary).frame(width: 120, alignment: .leading)
            Text(value).font(.subheadline)
            Spacer()
        }
        .font(.subheadline)
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title2.weight(.semibold))
            Text(sub).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private func labeledField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextField(label, text: text).textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Daten laden / speichern

    private func loadFromScenario() {
        currentStep = max(1, scenario.enterpriseStep)
        if let data = scenario.unternehmenskontextJSON?.data(using: .utf8),
           let k = try? JSONDecoder().decode(Unternehmenskontext.self, from: data) {
            kontext = k
        }
        if let data = scenario.situationsanalyseJSON?.data(using: .utf8),
           let sa = try? JSONDecoder().decode(SituationsAnalyseResult.self, from: data) {
            situationsAnalyse = sa
        }
        if let data = scenario.szenarioMatrixJSON?.data(using: .utf8),
           let opts = try? JSONDecoder().decode([SzenarioOption].self, from: data) {
            for opt in opts {
                if opt.buchstabe == "A" { optionA = opt }
                else if opt.buchstabe == "B" { optionB = opt }
                else if opt.buchstabe == "C" { optionC = opt }
            }
        }
        if let data = scenario.aktionsplanJSON?.data(using: .utf8),
           let plan = try? JSONDecoder().decode([Aktionsschritt].self, from: data) {
            aktionsplan = plan
        }
        if let data = scenario.strategosEmpfehlungJSON?.data(using: .utf8),
           let emp = try? JSONDecoder().decode(StrategosEmpfehlung.self, from: data) {
            empfehlung = emp
        }
    }

    private func saveToScenario() {
        scenario.enterpriseStep = currentStep
        scenario.ausgangslage = kontext.ausgangslage
        scenario.fragestellung = kontext.beschreibung
        if let data = try? JSONEncoder().encode(kontext) {
            scenario.unternehmenskontextJSON = String(data: data, encoding: .utf8)
        }
        if let sa = situationsAnalyse,
           let data = try? JSONEncoder().encode(sa) {
            scenario.situationsanalyseJSON = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode([optionA, optionB, optionC]) {
            scenario.szenarioMatrixJSON = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(aktionsplan) {
            scenario.aktionsplanJSON = String(data: data, encoding: .utf8)
        }
        if let emp = empfehlung,
           let data = try? JSONEncoder().encode(emp) {
            scenario.strategosEmpfehlungJSON = String(data: data, encoding: .utf8)
        }
        if !linkedCases.isEmpty,
           let data = try? JSONEncoder().encode(linkedCases.map { $0.id }) {
            scenario.lexaraSyncJSON = String(data: data, encoding: .utf8)
        }
    }

    // MARK: - KI-Operationen

    @MainActor
    private func runSituationsanalyse() async {
        loading = true; defer { loading = false }
        let prompt = """
        Führe eine professionelle SWOT-Analyse für folgenden Rechtsfall durch:
        Branche/Rechtsgebiet: \(kontext.branche), Ausgangslage: \(kontext.ausgangslage)
        Gegner: \(kontext.gegner), Risiken: \(kontext.schluesselRisiken.joined(separator: ", "))

        Gib JSON zurück: { staerken: [string], schwaechen: [string], chancen: [string], risiken: [string],
        zusammenfassung: string, kritischeFaktoren: [string] }
        """
        let schema: [String: Any] = ["type": "object", "properties": [
            "staerken": ["type": "array"], "schwaechen": ["type": "array"],
            "chancen": ["type": "array"], "risiken": ["type": "array"],
            "zusammenfassung": ["type": "string"], "kritischeFaktoren": ["type": "array"]
        ]]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, context: "Strategos.SWOT")
        guard case .success(let any) = res, let d = any as? [String: Any] else { return }
        situationsAnalyse = SituationsAnalyseResult(
            staerken: d["staerken"] as? [String] ?? [],
            schwaechen: d["schwaechen"] as? [String] ?? [],
            chancen: d["chancen"] as? [String] ?? [],
            risiken: d["risiken"] as? [String] ?? [],
            zusammenfassung: d["zusammenfassung"] as? String ?? "",
            kritischeFaktoren: d["kritischeFaktoren"] as? [String] ?? []
        )
    }

    @MainActor
    private func runSzenarioMatrix() async {
        loading = true; defer { loading = false }
        let prompt = """
        Erstelle eine Szenario-Matrix mit 3 strategischen Optionen (A=aggressiv, B=moderat, C=konservativ) für:
        Fall: \(scenario.title), Rechtsgebiet: \(kontext.branche)
        Ausgangslage: \(kontext.ausgangslage)
        Gegner: \(kontext.gegner)
        SWOT: Stärken \(situationsAnalyse?.staerken.prefix(3).joined(separator: ", ") ?? "")

        JSON-Antwort: { optionen: [{ buchstabe: "A"|"B"|"C", titel, beschreibung, vorteile: [string],
        nachteile: [string], erfolgswahrscheinlichkeit: number, kosten: string, zeitrahmen: string,
        empfohlen: bool }] }
        """
        let schema: [String: Any] = ["type": "object", "properties": ["optionen": ["type": "array"]]]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, context: "Strategos.Matrix")
        guard case .success(let any) = res,
              let d = any as? [String: Any],
              let opts = d["optionen"] as? [[String: Any]] else { return }
        for opt in opts {
            guard let b = opt["buchstabe"] as? String else { continue }
            var o = SzenarioOption(buchstabe: b)
            o.titel = opt["titel"] as? String ?? ""
            o.beschreibung = opt["beschreibung"] as? String ?? ""
            o.vorteile = opt["vorteile"] as? [String] ?? []
            o.nachteile = opt["nachteile"] as? [String] ?? []
            o.erfolgswahrscheinlichkeit = opt["erfolgswahrscheinlichkeit"] as? Double ?? 50
            o.kosten = opt["kosten"] as? String ?? ""
            o.zeitrahmen = opt["zeitrahmen"] as? String ?? ""
            o.empfohlen = opt["empfohlen"] as? Bool ?? false
            if b == "A" { optionA = o }
            else if b == "B" { optionB = o }
            else if b == "C" { optionC = o }
        }
    }

    @MainActor
    private func generateAktionsplan() async {
        loading = true; defer { loading = false }
        let empfOpt = empfehlung?.empfohleneOption ?? "B"
        let prompt = """
        Erstelle einen priorisierten Aktionsplan für die Umsetzung von Strategie-Option \(empfOpt).
        Fall: \(scenario.title), Rechtsgebiet: \(kontext.branche)
        Ausgangslage: \(kontext.ausgangslage)

        JSON: { schritte: [{ prioritaet: 1|2|3, titel: string, verantwortlich: string,
        frist: string, status: "offen", notizen: string }] }
        Maximal 8 Schritte, sortiert nach Priorität.
        """
        let schema: [String: Any] = ["type": "object", "properties": ["schritte": ["type": "array"]]]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, context: "Strategos.Aktionsplan")
        guard case .success(let any) = res,
              let d = any as? [String: Any],
              let schritte = d["schritte"] as? [[String: Any]] else { return }
        aktionsplan = schritte.map { s in
            var schritt = Aktionsschritt()
            schritt.prioritaet = s["prioritaet"] as? Int ?? 2
            schritt.titel = s["titel"] as? String ?? ""
            schritt.verantwortlich = s["verantwortlich"] as? String ?? ""
            schritt.frist = s["frist"] as? String ?? ""
            schritt.status = s["status"] as? String ?? "offen"
            schritt.notizen = s["notizen"] as? String ?? ""
            return schritt
        }
    }

    @MainActor
    private func generateEmpfehlung() async {
        loading = true; defer { loading = false }
        let optionen = [optionA, optionB, optionC].map {
            "Option \($0.buchstabe): \($0.titel) – Erfolg \(Int($0.erfolgswahrscheinlichkeit))%"
        }.joined(separator: "\n")
        let prompt = """
        Erstelle eine finale strategische Empfehlung für:
        Szenario: \(scenario.title)
        Optionen:
        \(optionen)
        Aktionsschritte: \(aktionsplan.count) geplant
        Ausgangslage: \(kontext.ausgangslage)
        Gegner: \(kontext.gegner)

        JSON: { empfohleneOption: "A"|"B"|"C", begruendung: string, risikobewertung: string,
        naechsteSchritte: [string], warnhinweise: [string], erfolgsprognose: number }
        """
        let schema: [String: Any] = ["type": "object", "properties": [
            "empfohleneOption": ["type": "string"],
            "begruendung": ["type": "string"],
            "risikobewertung": ["type": "string"],
            "naechsteSchritte": ["type": "array"],
            "warnhinweise": ["type": "array"],
            "erfolgsprognose": ["type": "number"]
        ]]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, context: "Strategos.Empfehlung")
        guard case .success(let any) = res, let d = any as? [String: Any] else { return }
        empfehlung = StrategosEmpfehlung(
            empfohleneOption: d["empfohleneOption"] as? String ?? "",
            begruendung: d["begruendung"] as? String ?? "",
            risikobewertung: d["risikobewertung"] as? String ?? "",
            naechsteSchritte: d["naechsteSchritte"] as? [String] ?? [],
            warnhinweise: d["warnhinweise"] as? [String] ?? [],
            erfolgsprognose: d["erfolgsprognose"] as? Double ?? 50
        )
    }

    private func exportPDF() {
        // PDF-Export via GegnerVerhaltenPDFExportService analog
        // (In production: collect data and export to PDF)
    }
}
