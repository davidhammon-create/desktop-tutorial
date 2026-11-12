import SwiftUI
import UniformTypeIdentifiers
struct TabHistoryView: View {
    let caseId: String
    @State private var eintraege: [CaseHistory] = []
    @State private var fall: LegalCase?
    @State private var laden = true
    @State private var fehler: String?
    @State private var suchtext = ""
    @State private var filterAktion = "alle"
    @State private var filterTyp = "alle"
    @State private var aufgeklappt: Set<String> = []
    @State private var expandedStep: Int?
    private static let schrittSummaries: [(Int, String, String, String)] = [
        (1, "Basisdaten", "📋", "Fallname, Gericht, Rechtsgebiet, Richter"),
        (2, "Argumente & Beweise", "⚖️", "Eigene & Gegner-Argumente mit Gewichtung"),
        (3, "Personen", "👤", "Richter, Zeugen, Sachverständige"),
        (4, "Fristen", "⏰", "Verfahrensfristen und Deadlines"),
        (5, "Strategie", "🎯", "Taktische Planung und Prognose"),
        (6, "KI-Berater", "🧠", "KI-Analyse Gegner & Verhandlungsszenarien"),
        (7, "Analyse", "📊", "Kosten-Nutzen & Rechtsprechung"),
        (8, "Risiken", "⚠️", "Risiko-Bewertung mit KI"),
        (9, "Simulation", "🎮", "Verhandlungs-Simulation"),
        (10, "Dokumente", "📄", "Hochgeladene Dokumente & Schriftsätze"),
        (11, "Gesamtbewertung", "📈", "Algorithmus + KI-Strategieanalyse"),
        (12, "Verhandlung", "🤝", "Verhandlungszeitplan & Szenarios"),
        (13, "Cockpit", "⚖️", "Live-Dashboard mit Alerts"),
        (14, "Prozess-Zeitachse", "📅", "Strategische Meilensteine"),
        (15, "Was-wäre-wenn", "🔄", "Szenario-Simulation mit Variablen"),
        (16, "Historie", "📜", "Alle Änderungen & Audit-Trail")
    ]
    private var entityTypen: [String] {
        ["alle"] + Array(Set(eintraege.compactMap(\.entity_type))).sorted()
    }
    private var gefiltert: [CaseHistory] {
        eintraege.filter { e in
            let action = e.action ?? e.change_type ?? ""
            if filterAktion != "alle" && action != filterAktion { return false }
            if filterTyp != "alle" && e.entity_type != filterTyp { return false }
            if suchtext.isEmpty { return true }
            let hay = [
                e.summary, e.details, e.entity_title, e.entity_type,
                e.field_changed, e.user_email, e.benutzer
            ].compactMap { $0 }.joined(separator: " ")
            return hay.localizedCaseInsensitiveContains(suchtext)
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Änderungsverlauf").font(.headline)
                Spacer()
                Button {
                    exportCSV()
                } label: {
                    Label("CSV", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                .disabled(gefiltert.isEmpty)
                Text("\(gefiltert.count) Einträge").font(.caption).foregroundStyle(.secondary)
            }
            schrittSummariesGrid
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.caption)
                    TextField("Suchen…", text: $suchtext).textFieldStyle(.plain).font(.caption)
                }
                .padding(8)
                .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                Picker("Aktion", selection: $filterAktion) {
                    Text("Alle").tag("alle")
                    Text("Erstellt").tag("create")
                    Text("Geändert").tag("update")
                    Text("Gelöscht").tag("delete")
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                Picker("Typ", selection: $filterTyp) {
                    ForEach(entityTypen, id: \.self) { t in
                        Text(t == "alle" ? "Alle Typen" : t).tag(t)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 130)
            }
            if fall?.ki_berater_result != nil {
                InfoHinweis(
                    titel: "KI-Berater-Ergebnis vorhanden",
                    nachricht: "Der Fall enthält gespeicherte KI-Berater-Analysedaten im Tab Gegner.",
                    symbol: "brain.head.profile"
                )
            }
            if laden {
                ProgressView("Verlauf wird geladen…").frame(maxWidth: .infinity).padding(.vertical, 40)
            } else if let fehler {
                Text(fehler).font(.caption).foregroundStyle(.red)
            } else if gefiltert.isEmpty {
                InfoHinweis(
                    titel: "Kein Verlauf",
                    nachricht: "Noch keine Änderungen für diesen Fall protokolliert.",
                    symbol: "clock.arrow.circlepath"
                )
            } else {
                ForEach(gefiltert, id: \.id) { entry in
                    historyZeile(entry)
                }
            }
        }
        .task { await ladenVerlauf() }
    }
    private var schrittSummariesGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Zusammenfassung aller 16 Schritte").font(.caption.bold())
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Self.schrittSummaries, id: \.0) { step, label, icon, desc in
                    let open = expandedStep == step
                    Button {
                        withAnimation { expandedStep = open ? nil : step }
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Text(icon).font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Schritt \(step)").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                                Text(label).font(.caption.bold())
                                Text(open ? desc : desc).font(.caption2).foregroundStyle(.secondary).lineLimit(open ? 4 : 1)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(open ? Color.blue.opacity(0.06) : Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(open ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1)))
    }
    @ViewBuilder
    private func historyZeile(_ entry: CaseHistory) -> some View {
        let id = entry.id ?? UUID().uuidString
        let action = entry.action ?? entry.change_type ?? "update"
        let expanded = aufgeklappt.contains(id)
        VStack(alignment: .leading, spacing: 0) {
            Button {
                if aufgeklappt.contains(id) { aufgeklappt.remove(id) }
                else { aufgeklappt.insert(id) }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(aktionFarbe(action))
                        .frame(width: 10, height: 10)
                        .padding(.top, 4)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(entityIcon(entry.entity_type)).font(.caption)
                            Text((entry.entity_type ?? entry.change_type ?? "Änderung").uppercased())
                                .font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                            Text(action.uppercased())
                                .font(.system(size: 9, weight: .semibold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(aktionFarbe(action).opacity(0.12), in: Capsule())
                            Spacer()
                            Text(zeitText(entry)).font(.caption2).foregroundStyle(.tertiary)
                        }
                        Text(entry.entity_title ?? entry.summary ?? entry.details ?? "—")
                            .font(.caption).fontWeight(.medium)
                        if let summary = entry.summary, summary != entry.entity_title {
                            Text(summary).font(.caption2).foregroundStyle(.secondary)
                        }
                        if let user = entry.user_email ?? entry.benutzer {
                            Text("von \(user)").font(.system(size: 9)).foregroundStyle(.tertiary)
                        }
                    }
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                .padding(12)
            }
            .buttonStyle(.plain)
            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    if let feld = entry.field_changed {
                        detailBlock(titel: "Feld", text: feld, farbe: .secondary)
                    }
                    if let alt = entry.old_value ?? entry.vorher?.stringValue {
                        detailBlock(titel: "Alter Wert", text: alt, farbe: .red)
                    }
                    if let neu = entry.new_value ?? entry.nachher?.stringValue {
                        detailBlock(titel: "Neuer Wert", text: neu, farbe: .green)
                    }
                    if let eid = entry.entity_id {
                        detailBlock(titel: "Entity ID", text: eid, farbe: .secondary)
                    }
                }
                .padding(.horizontal, 12).padding(.bottom, 12)
                .background(Color.gray.opacity(0.03))
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.1)))
    }
    private func detailBlock(titel: String, text: String, farbe: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titel.uppercased()).font(.system(size: 9, weight: .bold)).foregroundStyle(farbe)
            Text(text).font(.system(size: 10, design: .monospaced)).textSelection(.enabled)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 6))
    }
    private func ladenVerlauf() async {
        laden = true
        fehler = nil
        do {
            async let history = Services.caseHistory.filter(["case_id": caseId], sort: "-timestamp")
            async let caseData = Services.cases.get(id: caseId)
            let data = try await history
            let c = try await caseData
            await MainActor.run {
                eintraege = data.sorted { zeitDatum($0) > zeitDatum($1) }
                fall = c
                laden = false
            }
        } catch {
            await MainActor.run {
                fehler = error.localizedDescription
                laden = false
            }
        }
    }
    private func exportCSV() {
        let headers = ["Zeitstempel", "Entity-Typ", "Aktion", "Zusammenfassung", "Feld", "Nutzer"]
        let rows = gefiltert.map { h in
            [
                zeitText(h),
                h.entity_type ?? "",
                h.action ?? h.change_type ?? "",
                h.summary ?? h.details ?? "",
                h.field_changed ?? "—",
                h.user_email ?? h.benutzer ?? "—"
            ]
        }
        let csv = ([headers] + rows)
            .map { $0.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }.joined(separator: ",") }
            .joined(separator: "\n")
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Fall-Historie_\(Date().formatted(.iso8601.year().month().day())).csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try ("\u{FEFF}" + csv).write(to: url, atomically: true, encoding: .utf8)
            fehler = nil
        } catch {
            fehler = "CSV-Export fehlgeschlagen: \(error.localizedDescription)"
        }
    }
    private func zeitText(_ e: CaseHistory) -> String {
        if let ts = e.timestamp, let d = ISO8601DateFormatter().date(from: ts) {
            return d.formatted(.dateTime.day().month().hour().minute())
        }
        return (e.created_at ?? Date()).formatted(.dateTime.day().month().hour().minute())
    }
    private func zeitDatum(_ e: CaseHistory) -> Date {
        if let ts = e.timestamp, let d = ISO8601DateFormatter().date(from: ts) { return d }
        return e.created_at ?? .distantPast
    }
    private func aktionFarbe(_ action: String) -> Color {
        switch action {
        case "create": return .green
        case "delete": return .red
        default: return .blue
        }
    }
    private func entityIcon(_ type: String?) -> String {
        switch type {
        case "Argument": return "⚖️"
        case "Evidence": return "📄"
        case "Deadline": return "⏰"
        case "Person": return "👤"
        case "Document": return "📋"
        case "Case": return "📁"
        case "Risk": return "⚠️"
        default: return "•"
        }
    }
}
