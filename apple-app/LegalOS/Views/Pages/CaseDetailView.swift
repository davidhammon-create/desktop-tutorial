//
//  CaseDetailView.swift
//  Detail-Ansicht eines Falls mit Tabs: Fallakte, Argumente, Beweise,
//  Personen, Zeitleiste, Strategie, Abschluss. Entspricht src/pages/CaseDetail.jsx.
//

import SwiftUI

enum CaseTab: String, CaseIterable, Hashable {
    case fallakte    = "Fallakte"
    case argumente   = "Argumente"
    case beweise     = "Beweise"
    case personen    = "Personen"
    case zeitleiste  = "Zeitleiste"
    case strategie   = "Strategie"
    case abschluss   = "Abschluss"

    var icon: String {
        switch self {
        case .fallakte:   return "doc.text"
        case .argumente:  return "lightbulb"
        case .beweise:    return "doc.on.doc"
        case .personen:   return "person.2"
        case .zeitleiste: return "calendar"
        case .strategie:  return "shield.lefthalf.filled"
        case .abschluss:  return "checkmark.seal"
        }
    }
}

struct CaseDetailView: View {
    let caseId: String
    @EnvironmentObject var cloudKit: CloudKitService

    @State private var caseEntity: Case?
    @State private var arguments: [Argument] = []
    @State private var evidence:  [Evidence] = []
    @State private var persons:   [Person] = []
    @State private var timeline:  [TimelineEvent] = []
    @State private var deadlines: [Deadline] = []
    @State private var selectedTab: CaseTab = .fallakte
    @State private var loading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tabBar
            Divider()
            ScrollView { tabContent.padding() }
        }
        .navigationTitle(caseEntity?.fallname ?? "Fall")
        .task { await reload() }
        .refreshable { await reload() }
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(CaseTab.allCases, id: \.self) { t in
                    Button { selectedTab = t } label: {
                        Label(t.rawValue, systemImage: t.icon)
                            .labelStyle(.titleAndIcon)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(selectedTab == t ? Color.accentColor.opacity(0.15) : .clear,
                                        in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .fallakte:   fallakteView
        case .argumente:  argumenteView
        case .beweise:    beweiseView
        case .personen:   personenView
        case .zeitleiste: zeitleisteView
        case .strategie:  strategieView
        case .abschluss:  abschlussView
        }
    }

    // MARK: - Fallakte (Stammdaten + KPIs)
    private var fallakteView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let c = caseEntity {
                infoRow(label: "Aktenzeichen", value: c.aktenzeichen ?? "–")
                infoRow(label: "Gericht",      value: c.gericht ?? "–")
                infoRow(label: "Rechtsgebiet", value: c.rechtsgebiet ?? "–")
                infoRow(label: "Status",       value: c.status.rawValue)
                infoRow(label: "Instanz",      value: c.instanz.rawValue)
                if let s = c.streitwert {
                    infoRow(label: "Streitwert", value: "\(Int(s)) €")
                }
                if let p = c.prognose {
                    VStack(alignment: .leading) {
                        Text("Prognose").font(.caption).foregroundStyle(.secondary)
                        ProgressView(value: p / 100).tint(.accentColor)
                        Text("\(Int(p)) %").font(.caption.weight(.medium))
                    }
                }
                if let z = c.zentraleRechtsfrage {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Zentrale Rechtsfrage").font(.caption).foregroundStyle(.secondary)
                        Text(z)
                    }
                }
            }
        }
    }

    // MARK: - Argumente
    private var argumenteView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Section {
                ForEach(arguments.filter { $0.side == .eigen }) { a in
                    argumentCard(a, color: .green)
                }
            } header: {
                Text("Eigene Argumente").font(.headline)
            }
            Section {
                ForEach(arguments.filter { $0.side == .gegner }) { a in
                    argumentCard(a, color: .red)
                }
            } header: {
                Text("Gegnerische Argumente").font(.headline)
            }
        }
    }

    private func argumentCard(_ a: Argument, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(a.title).font(.body.weight(.medium))
                Spacer()
                if let s = a.kiStrength ?? a.strength {
                    Text(String(format: "%.1f / 10", s))
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(.regularMaterial, in: Capsule())
                }
            }
            if let d = a.argDescription { Text(d).font(.caption).foregroundStyle(.secondary) }
            if let r = a.kiReasoning { Text(r).font(.caption2).italic().foregroundStyle(.secondary) }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Beweise
    private var beweiseView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(evidence) { e in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text(e.title).font(.body.weight(.medium))
                        Spacer()
                        if let w = e.kiWeight ?? e.weight {
                            Text(String(format: "Gewicht %.1f", w)).font(.caption)
                        }
                    }
                    if let d = e.evidenceDescription { Text(d).font(.caption).foregroundStyle(.secondary) }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Personen
    private var personenView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(persons) { p in
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill").font(.title2)
                    VStack(alignment: .leading) {
                        Text(p.name).font(.body.weight(.medium))
                        Text(p.role.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let g = p.glaubwuerdigkeit {
                        Text("\(Int(g))/10").font(.caption)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Zeitleiste
    private var zeitleisteView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(timeline.sorted(by: { $0.date < $1.date })) { e in
                HStack(alignment: .top, spacing: 12) {
                    VStack {
                        Image(systemName: "circle.fill").font(.caption2)
                        Rectangle().frame(width: 2).foregroundStyle(.secondary.opacity(0.3))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(e.date.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(.secondary)
                        Text(e.title).font(.body.weight(.medium))
                        if let d = e.eventDescription { Text(d).font(.caption).foregroundStyle(.secondary) }
                    }
                }
            }
        }
    }

    // MARK: - Strategie
    private var strategieView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let c = caseEntity {
                let prog = LegalAlgorithms.prognose(arguments: arguments)
                let progFinal = LegalAlgorithms.prognoseMitFristen(base: prog, deadlines: deadlines)
                Text("Strategische Auswertung").font(.headline)
                VStack(alignment: .leading) {
                    Text("Live-Prognose: \(Int(progFinal)) %")
                    ProgressView(value: progFinal / 100).tint(.accentColor)
                }
                if let streit = c.streitwert {
                    let emp = LegalAlgorithms.vergleichsEmpfehlung(
                        streitwert: streit,
                        gebuehren: c.gebuehrenstufe ?? 0,
                        svKosten: c.svKosten ?? 0,
                        reisekosten: c.reisekosten ?? 0,
                        prognosePct: progFinal,
                        vergleichsangebot: c.vergleichsangebot)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vergleich vs. Prozess").font(.subheadline.weight(.semibold))
                        Text("Erwartung Prozess: \(Int(emp.prozessErwartet)) €").font(.caption)
                        Text("Erwartung Vergleich: \(Int(emp.vergleichErwartet)) €").font(.caption)
                        Text(emp.empfehlung).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Abschluss
    private var abschlussView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Abschluss-Fragebogen").font(.headline)
            Text("Bewerte nach Verfahrensende, ob die KI-Prognose korrekt war. So lernt LegalOS für künftige Fälle.")
                .font(.caption).foregroundStyle(.secondary)
            NavigationLink("Fragebogen ausfüllen") {
                Text("Fragebogen-Editor (Stub)").padding()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Helpers

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary).frame(width: 140, alignment: .leading)
            Text(value)
            Spacer()
        }
        .font(.subheadline)
    }

    @MainActor
    private func reload() async {
        loading = true
        defer { loading = false }
        caseEntity = try? await cloudKit.fetchOne(Case.self, id: caseId)
        arguments  = (try? await cloudKit.fetchForCase(Argument.self, caseId: caseId)) ?? []
        evidence   = (try? await cloudKit.fetchForCase(Evidence.self, caseId: caseId)) ?? []
        persons    = (try? await cloudKit.fetchForCase(Person.self, caseId: caseId)) ?? []
        timeline   = (try? await cloudKit.fetchForCase(TimelineEvent.self, caseId: caseId)) ?? []
        deadlines  = (try? await cloudKit.fetchForCase(Deadline.self, caseId: caseId)) ?? []
    }
}
