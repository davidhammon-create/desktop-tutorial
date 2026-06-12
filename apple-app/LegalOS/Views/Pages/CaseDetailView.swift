//
//  CaseDetailView.swift
//  Detail-Ansicht eines Falls mit allen Lexara-Tabs: Fallakte, Argumente (KI),
//  Beweise, Personen, Zeitleiste, Gesamtbewertung, Verhandlung, Gegnerverhalten, Abschluss.
//  Entspricht src/pages/CaseDetail.jsx inkl. aller Lexara-Subkomponenten.
//

import SwiftUI

enum CaseTab: String, CaseIterable, Hashable {
    case fallakte       = "Fallakte"
    case argumente      = "Argumente"
    case beweise        = "Beweise"
    case personen       = "Personen"
    case zeitleiste     = "Zeitleiste"
    case gesamtbewert   = "Bewertung"
    case verhandlung    = "Verhandlung"
    case gegner         = "Gegner"
    case abschluss      = "Abschluss"

    var icon: String {
        switch self {
        case .fallakte:      return "doc.text"
        case .argumente:     return "lightbulb"
        case .beweise:       return "doc.on.doc"
        case .personen:      return "person.2"
        case .zeitleiste:    return "calendar"
        case .gesamtbewert:  return "chart.bar.xaxis"
        case .verhandlung:   return "person.2.wave.2"
        case .gegner:        return "shield.lefthalf.filled"
        case .abschluss:     return "checkmark.seal"
        }
    }
}

struct CaseDetailView: View {
    let caseId: String
    @EnvironmentObject var cloudKit: CloudKitService

    @State private var caseEntity: Case?
    @State private var persons:    [Person] = []
    @State private var timeline:   [TimelineEvent] = []
    @State private var deadlines:  [Deadline] = []
    @State private var gegnerVerhalten: [GegnerVerhalten] = []
    @State private var selectedTab: CaseTab = .fallakte
    @State private var loading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tabBar
            Divider()
            tabContent
        }
        .navigationTitle(caseEntity?.fallname ?? "Fall")
        .task { await reload() }
        .refreshable { await reload() }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(CaseTab.allCases, id: \.self) { t in
                    Button { selectedTab = t } label: {
                        Label(t.rawValue, systemImage: t.icon)
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(selectedTab == t
                                ? Color.accentColor.opacity(0.15)
                                : .clear,
                                in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(selectedTab == t ? .accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
        }
    }

    // MARK: - Tab Content Router

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .fallakte:
            ScrollView { fallakteView.padding() }
        case .argumente:
            TabArgumenteView(caseId: caseId, caseData: caseEntity)
        case .beweise:
            ScrollView { beweiseView.padding() }
        case .personen:
            ScrollView { personenView.padding() }
        case .zeitleiste:
            ScrollView { zeitleisteView.padding() }
        case .gesamtbewert:
            TabGesamtbewertungView(caseId: caseId, caseData: caseEntity)
        case .verhandlung:
            TabVerhandlungssimulationView(caseId: caseId, caseData: caseEntity)
        case .gegner:
            ScrollView { gegnerView.padding() }
        case .abschluss:
            ScrollView { abschlussView.padding() }
        }
    }

    // MARK: - Fallakte

    private var fallakteView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let c = caseEntity {
                GroupBox("Stammdaten") {
                    VStack(spacing: 6) {
                        infoRow(label: "Aktenzeichen",  value: c.aktenzeichen ?? "–")
                        infoRow(label: "Gericht",       value: c.gericht ?? "–")
                        infoRow(label: "Rechtsgebiet",  value: c.rechtsgebiet ?? "–")
                        infoRow(label: "Status",        value: c.status.rawValue)
                        infoRow(label: "Instanz",       value: c.instanz.rawValue)
                        if let s = c.streitwert {
                            infoRow(label: "Streitwert", value: "\(Int(s)) €")
                        }
                        if let m = c.mandantName {
                            infoRow(label: "Mandant", value: m)
                        }
                    }
                }
                if let p = c.prognose {
                    GroupBox("Erfolgsprognose") {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: p / 100).tint(p >= 60 ? .green : (p >= 40 ? .orange : .red))
                            Text("\(Int(p)) % Erfolgswahrscheinlichkeit")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                if let z = c.zentraleRechtsfrage {
                    GroupBox("Zentrale Rechtsfrage") {
                        Text(z).font(.body)
                    }
                }
                if let notes = c.notes, !notes.isEmpty {
                    GroupBox("Notizen") { Text(notes).font(.caption) }
                }
            } else if loading {
                ProgressView().padding()
            }
        }
    }

    // MARK: - Beweise (inline, kompakt)

    private var beweiseView: some View {
        BeweisInlineView(caseId: caseId)
    }

    // MARK: - Personen

    private var personenView: some View {
        PersonenInlineView(caseId: caseId)
    }

    // MARK: - Zeitleiste

    private var zeitleisteView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zeitleiste").font(.headline)
            if timeline.isEmpty {
                ContentUnavailableView("Keine Ereignisse",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Füge Ereignisse zum Fall hinzu."))
            } else {
                ForEach(timeline.sorted(by: { $0.date < $1.date })) { e in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Circle().fill(Color.accentColor).frame(width: 10, height: 10)
                            Rectangle().frame(width: 2).foregroundStyle(.secondary.opacity(0.25))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2).foregroundStyle(.secondary)
                            Text(e.title).font(.body.weight(.medium))
                            if let d = e.eventDescription {
                                Text(d).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            Divider().padding(.vertical, 4)
            Text("Fristen (\(deadlines.filter{$0.status == .offen}.count) offen)").font(.headline)
            ForEach(deadlines) { d in
                HStack {
                    Image(systemName: d.status == .offen ? "clock.badge.exclamationmark" : "checkmark.circle")
                        .foregroundStyle(d.status == .offen ? .orange : .green)
                    VStack(alignment: .leading) {
                        Text(d.title).font(.subheadline)
                        Text(d.dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(d.status.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.gray.opacity(0.15), in: Capsule())
                }
                .padding(8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Gegnerverhalten

    private var gegnerView: some View {
        GegnerVerhaltenTabView(caseId: caseId, caseEntity: caseEntity)
    }

    // MARK: - Abschluss

    private var abschlussView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Abschluss-Fragebogen").font(.headline)
            Text("Bewerte nach Verfahrensende, ob die KI-Prognose korrekt war. So verbessert LegalOS die Prognosen für künftige Fälle.")
                .font(.caption).foregroundStyle(.secondary)
            if let c = caseEntity {
                GroupBox("Fallkennzahlen") {
                    VStack(spacing: 6) {
                        infoRow(label: "Prognose",  value: "\(Int(c.prognose ?? 0)) %")
                        infoRow(label: "Status",    value: c.status.rawValue)
                        if let s = c.streitwert {
                            infoRow(label: "Streitwert", value: "\(Int(s)) €")
                        }
                    }
                }
            }
            NavigationLink("Fragebogen ausfüllen") {
                CaseFragebogenView(caseId: caseId)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Helpers

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary).frame(width: 130, alignment: .leading)
            Text(value).font(.subheadline)
            Spacer()
        }
        .font(.subheadline)
    }

    @MainActor
    private func reload() async {
        loading = true
        defer { loading = false }
        caseEntity = try? await cloudKit.fetchOne(Case.self, id: caseId)
        persons    = (try? await cloudKit.fetchForCase(Person.self,        caseId: caseId)) ?? []
        timeline   = (try? await cloudKit.fetchForCase(TimelineEvent.self, caseId: caseId)) ?? []
        deadlines  = (try? await cloudKit.fetchForCase(Deadline.self,      caseId: caseId)) ?? []
        gegnerVerhalten = (try? await cloudKit.fetchForCase(GegnerVerhalten.self, caseId: caseId)) ?? []
    }
}

// MARK: - Beweise Inline Sub-View

struct BeweisInlineView: View {
    let caseId: String
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var evidence: [Evidence] = []
    @State private var showAdd = false
    @State private var newTitle = ""
    @State private var newDesc = ""
    @State private var newType = "Dokument"
    @State private var newWeight: Double = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Beweise & Dokumente (\(evidence.count))")
                    .font(.headline)
                Spacer()
                Button { showAdd.toggle() } label: {
                    Label("Hinzufügen", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            if showAdd {
                GroupBox("Neuer Beweis") {
                    VStack(spacing: 8) {
                        TextField("Titel *", text: $newTitle)
                        TextField("Beschreibung", text: $newDesc, axis: .vertical).lineLimit(2...3)
                        HStack {
                            Picker("Typ", selection: $newType) {
                                ForEach(["Dokument","Zeuge","Vertrag","E-Mail","Foto","Gutachten","Sonstiges"],
                                        id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            Stepper("Gewicht \(newWeight, specifier: "%.0f")/10",
                                    value: $newWeight, in: 0...10, step: 1)
                        }
                        HStack {
                            Spacer()
                            Button("Abbrechen") { showAdd = false }
                            Button("Speichern") { Task { await addEvidence() } }
                                .buttonStyle(.borderedProminent)
                                .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                }
            }
            if evidence.isEmpty {
                ContentUnavailableView("Keine Beweise",
                    systemImage: "doc.badge.plus",
                    description: Text("Füge Beweise und Dokumente hinzu."))
            } else {
                ForEach(evidence) { e in
                    HStack(spacing: 12) {
                        Image(systemName: evidenceIcon(e.type))
                            .font(.title2).foregroundStyle(.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.title).font(.body.weight(.medium))
                            if let d = e.evidenceDescription {
                                Text(d).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                        }
                        Spacer()
                        if let w = e.kiWeight ?? e.weight {
                            VStack {
                                Text("\(Int(w))/10").font(.caption.weight(.semibold))
                                Text("Gewicht").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .task { await load() }
    }

    private func evidenceIcon(_ type: String?) -> String {
        switch type {
        case "Zeuge":    return "person.fill.questionmark"
        case "Vertrag":  return "doc.text.fill"
        case "E-Mail":   return "envelope.fill"
        case "Foto":     return "photo.fill"
        case "Gutachten": return "chart.bar.doc.horizontal"
        default:         return "doc.on.doc.fill"
        }
    }

    @MainActor
    private func load() async {
        let pred = NSPredicate(format: "case_id == %@", caseId)
        evidence = (try? await cloudKit.fetch(Evidence.self, predicate: pred)) ?? []
    }

    private func addEvidence() async {
        var e = Evidence(caseId: caseId, title: newTitle)
        e.evidenceDescription = newDesc.isEmpty ? nil : newDesc
        e.type = newType
        e.weight = newWeight
        _ = try? await cloudKit.save(e)
        newTitle = ""; newDesc = ""; newType = "Dokument"; newWeight = 5
        showAdd = false
        await load()
    }
}

// MARK: - Personen Inline Sub-View

struct PersonenInlineView: View {
    let caseId: String
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var persons: [Person] = []
    @State private var showAdd = false
    @State private var newName = ""
    @State private var newRole: PersonRole = .zeuge

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Beteiligte (\(persons.count))").font(.headline)
                Spacer()
                Button { showAdd.toggle() } label: {
                    Label("Person", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            if showAdd {
                GroupBox("Neue Person") {
                    VStack(spacing: 8) {
                        TextField("Name *", text: $newName)
                        Picker("Rolle", selection: $newRole) {
                            ForEach(PersonRole.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        HStack {
                            Spacer()
                            Button("Abbrechen") { showAdd = false }
                            Button("Hinzufügen") { Task { await addPerson() } }
                                .buttonStyle(.borderedProminent)
                                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                }
            }
            if persons.isEmpty {
                ContentUnavailableView("Keine Beteiligten",
                    systemImage: "person.badge.plus",
                    description: Text("Füge Beteiligte (Zeugen, Anwälte, Parteien) hinzu."))
            } else {
                ForEach(persons) { p in
                    HStack(spacing: 12) {
                        Image(systemName: roleIcon(p.role)).font(.title2)
                            .foregroundStyle(roleColor(p.role))
                        VStack(alignment: .leading) {
                            Text(p.name).font(.body.weight(.medium))
                            Text(p.role.rawValue).font(.caption).foregroundStyle(.secondary)
                            if let org = p.organization {
                                Text(org).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let g = p.glaubwuerdigkeit {
                            VStack {
                                Text("\(Int(g))%").font(.caption.weight(.semibold))
                                Text("Glaubw.").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .task { await load() }
    }

    private func roleIcon(_ r: PersonRole) -> String {
        switch r {
        case .zeuge:             return "person.fill.questionmark"
        case .anwalt:            return "briefcase.fill"
        case .richter:           return "building.columns.fill"
        case .partei:            return "person.2.fill"
        case .sachverstaendiger: return "magnifyingglass"
        case .gutachter:         return "chart.bar.doc.horizontal"
        }
    }
    private func roleColor(_ r: PersonRole) -> Color {
        switch r {
        case .anwalt:            return .purple
        case .richter:           return .orange
        case .partei:            return .red
        case .sachverstaendiger: return .blue
        default:                 return .gray
        }
    }

    @MainActor
    private func load() async {
        let pred = NSPredicate(format: "case_id == %@", caseId)
        persons = (try? await cloudKit.fetch(Person.self, predicate: pred)) ?? []
    }

    private func addPerson() async {
        var p = Person(caseId: caseId, name: newName)
        p.role = newRole
        _ = try? await cloudKit.save(p)
        newName = ""; showAdd = false
        await load()
    }
}

// MARK: - GegnerVerhalten Tab

struct GegnerVerhaltenTabView: View {
    let caseId: String
    let caseEntity: Case?
    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var items: [GegnerVerhalten] = []
    @State private var showAdd = false
    @State private var analyzing = false
    @State private var analysis: GegnerAnalysisResult?

    @State private var newTitel = ""
    @State private var newTyp: GegnerTyp = .taktik
    @State private var newBeschreibung = ""
    @State private var newReaktion: GegnerReaktion? = nil
    @State private var newDatum: Date = Date()
    @State private var newUnserAngebot: String = ""
    @State private var newGegnerAngebot: String = ""

    struct GegnerAnalysisResult {
        var muster: [String] = []
        var empfehlung: String = ""
        var staerken: [String] = []
        var schwaechen: [String] = []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Gegnerverhalten").font(.headline)
                    Text("Taktiken, Reaktionen und Verhaltensmuster der Gegenseite.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await analyzePattern() }
                } label: {
                    Label(analyzing ? "Analysiere…" : "KI-Analyse", systemImage: "brain.head.profile")
                }
                .buttonStyle(.bordered)
                .disabled(analyzing || items.isEmpty)

                Button { showAdd = true } label: {
                    Label("Eintrag", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            // KI-Analyse Ergebnis
            if let a = analysis {
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("KI-Musteranalyse", systemImage: "brain.head.profile")
                                .font(.callout).bold()
                            Spacer()
                            Button { analysis = nil } label: { Image(systemName: "xmark") }
                                .buttonStyle(.plain)
                        }
                        if !a.muster.isEmpty {
                            Text("Erkannte Muster").font(.caption).bold().foregroundStyle(.secondary)
                            ForEach(a.muster, id: \.self) {
                                Label($0, systemImage: "circle.fill").font(.caption)
                            }
                        }
                        if !a.empfehlung.isEmpty {
                            Text("Empfehlung").font(.caption).bold().foregroundStyle(.blue)
                            Text(a.empfehlung).font(.caption)
                                .padding(8)
                                .background(Color.blue.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                        }
                        HStack(alignment: .top, spacing: 12) {
                            if !a.staerken.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("Gegner-Stärken").font(.caption2).bold().foregroundStyle(.red)
                                    ForEach(a.staerken, id: \.self) {
                                        Label($0, systemImage: "exclamationmark.triangle.fill")
                                            .font(.caption2).foregroundStyle(.red)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            if !a.schwaechen.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("Gegner-Schwächen").font(.caption2).bold().foregroundStyle(.green)
                                    ForEach(a.schwaechen, id: \.self) {
                                        Label($0, systemImage: "arrow.down.circle.fill")
                                            .font(.caption2).foregroundStyle(.green)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }

            // Add Form
            if showAdd {
                GroupBox("Neues Verhalten erfassen") {
                    VStack(spacing: 8) {
                        TextField("Titel *", text: $newTitel)
                        TextField("Beschreibung", text: $newBeschreibung, axis: .vertical)
                            .lineLimit(2...4)
                        HStack {
                            Picker("Typ", selection: $newTyp) {
                                ForEach(GegnerTyp.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            DatePicker("Datum", selection: $newDatum, displayedComponents: .date)
                                .labelsHidden()
                        }
                        HStack {
                            TextField("Unser Angebot (€)", text: $newUnserAngebot)
                            TextField("Gegnerangebot (€)", text: $newGegnerAngebot)
                        }
                        Picker("Reaktion", selection: $newReaktion) {
                            Text("Keine Angabe").tag(GegnerReaktion?.none)
                            ForEach(GegnerReaktion.allCases, id: \.self) {
                                Text($0.rawValue).tag(GegnerReaktion?.some($0))
                            }
                        }
                        HStack {
                            Spacer()
                            Button("Abbrechen") { showAdd = false }
                            Button("Speichern") { Task { await addItem() } }
                                .buttonStyle(.borderedProminent)
                                .disabled(newTitel.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                }
            }

            // Liste
            if items.isEmpty && !showAdd {
                ContentUnavailableView(
                    "Kein Verhalten dokumentiert",
                    systemImage: "eye.slash",
                    description: Text("Dokumentiere Taktiken und Reaktionen der Gegenseite."))
            } else {
                let df = DateFormatter(); _ = { df.dateStyle = .medium; df.locale = Locale(identifier: "de_DE") }()
                ForEach(items) { v in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(v.typ.rawValue)
                                .font(.caption2).bold()
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(typColor(v.typ).opacity(0.15), in: Capsule())
                                .foregroundStyle(typColor(v.typ))
                            if let r = v.reaktion {
                                Text(r.rawValue)
                                    .font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1), in: Capsule())
                            }
                            Spacer()
                            if let d = v.datum {
                                Text(df.string(from: d)).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        Text(v.titel).font(.subheadline.weight(.medium))
                        if let b = v.beschreibung {
                            Text(b).font(.caption).foregroundStyle(.secondary).lineLimit(3)
                        }
                        if let u = v.unserAngebot, let g = v.gegnerAngebot {
                            HStack {
                                Label("Unser: \(Int(u)) €", systemImage: "arrow.up.circle")
                                    .font(.caption).foregroundStyle(.blue)
                                Label("Gegner: \(Int(g)) €", systemImage: "arrow.down.circle")
                                    .font(.caption).foregroundStyle(.red)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .task { await load() }
    }

    private func typColor(_ t: GegnerTyp) -> Color {
        switch t {
        case .versaeumteFrist:    return .orange
        case .vergleichsreaktion: return .blue
        case .taktik:             return .red
        case .prozessverhalten:   return .purple
        case .sonstiges:          return .gray
        }
    }

    @MainActor
    private func load() async {
        let pred = NSPredicate(format: "case_id == %@", caseId)
        items = (try? await cloudKit.fetch(GegnerVerhalten.self, predicate: pred)) ?? []
    }

    private func addItem() async {
        var v = GegnerVerhalten(caseId: caseId, typ: newTyp, titel: newTitel)
        v.beschreibung = newBeschreibung.isEmpty ? nil : newBeschreibung
        v.reaktion = newReaktion
        v.datum = newDatum
        v.unserAngebot = Double(newUnserAngebot)
        v.gegnerAngebot = Double(newGegnerAngebot)
        _ = try? await cloudKit.save(v)
        newTitel = ""; newBeschreibung = ""; newUnserAngebot = ""; newGegnerAngebot = ""
        showAdd = false
        await load()
    }

    private func analyzePattern() async {
        analyzing = true; defer { analyzing = false }
        let list = items.map { "- [\($0.typ.rawValue)] \($0.titel): \($0.beschreibung ?? "")" }
            .joined(separator: "\n")
        let prompt = """
        Analysiere das Verhaltensmuster der Gegenseite in diesem Rechtsfall.
        Fall: \(caseEntity?.fallname ?? ""), Rechtsgebiet: \(caseEntity?.rechtsgebiet ?? "")
        Dokumentierte Verhaltensweisen:
        \(list)
        Gib JSON zurück: { muster: [string], empfehlung: string, staerken: [string], schwaechen: [string] }
        """
        let schema: [String: Any] = ["type": "object",
            "properties": ["muster": ["type": "array"], "empfehlung": ["type": "string"],
                           "staerken": ["type": "array"], "schwaechen": ["type": "array"]]]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        guard case .success(let any) = res, let dict = any as? [String: Any] else { return }
        analysis = GegnerAnalysisResult(
            muster:    dict["muster"] as? [String] ?? [],
            empfehlung: dict["empfehlung"] as? String ?? "",
            staerken:  dict["staerken"] as? [String] ?? [],
            schwaechen: dict["schwaechen"] as? [String] ?? []
        )
    }
}

// MARK: - Abschluss-Fragebogen Stub

struct CaseFragebogenView: View {
    let caseId: String
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Abschluss-Fragebogen").font(.title2.weight(.semibold))
            Text("Dieser Bereich wird nach Verfahrensende ausgefüllt.")
                .font(.subheadline).foregroundStyle(.secondary)
            GroupBox("Prognose-Feedback") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("War die KI-Prognose zutreffend?").font(.caption)
                    HStack {
                        ForEach(["Ja", "Teilweise", "Nein"], id: \.self) { o in
                            Button(o) { }
                                .buttonStyle(.bordered)
                        }
                    }
                }
            }
            GroupBox("Ergebnis") {
                VStack(alignment: .leading) {
                    Text("Verfahrensausgang").font(.caption).foregroundStyle(.secondary)
                    Picker("Ergebnis", selection: .constant("Gewonnen")) {
                        ForEach(["Gewonnen","Verloren","Vergleich","Eingestellt"], id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding()
        .navigationTitle("Fragebogen")
    }
}
