//
//  WasWaereWennSimulationView.swift
//  Konversion von src/components/lexara/WasWaereWennSimulation.jsx (672 Zeilen) nach SwiftUI.
//  Interaktive Simulation: Argumente, Beweise oder Fristen ausblenden und Auswirkung
//  auf die Prognose beobachten. Inkl. KI-Verhandlungs-Dossier und Motiv-Analyse.
//
//  PDF-Export wurde 1:1 in einen TXT-Export umgewandelt (NSPasteboard auf macOS),
//  da kein UIKit/PDFKit verwendet werden darf. Inhalt entspricht der React-Version.
//

import SwiftUI
import AppKit

// MARK: - Lokale Modelle

fileprivate struct VerhandlungsDossier: Hashable {
    var openingStatement: String?
    var staerksteArgumente: [DossierArg] = []
    var gegnerSchwachstellen: [DossierGS] = []
    var verhandlungsziele: [DossierZiel] = []
    var roteLinien: [String] = []
}
fileprivate struct DossierArg: Identifiable, Hashable {
    let id = UUID(); var argument: String; var einsatz: String?; var formulierung: String?
}
fileprivate struct DossierGS: Identifiable, Hashable {
    let id = UUID(); var schwachstelle: String; var angriffspunkt: String?
}
fileprivate struct DossierZiel: Identifiable, Hashable {
    let id = UUID(); var ziel: String; var prioritaet: String?; var taktik: String?
}

fileprivate struct MotivAnalyse: Hashable {
    var timingAnalyse: String?
    var fristenHintergedanken: String?
    var verdeckteZiele: [String] = []
    var psychologischeTaktiken: [MotivTaktik] = []
    var naechsterSchrittGegner: String?
    var empfohleneReaktion: String?
    var roteFlaggen: [String] = []
}
fileprivate struct MotivTaktik: Identifiable, Hashable {
    let id = UUID(); var taktik: String; var beweis: String?; var intensitaet: String
}

// MARK: - Hauptansicht

struct WasWaereWennSimulationView: View {
    let args: [Argument]
    let evidence: [Evidence]
    let deadlines: [Deadline]
    let persons: [Person]
    let caseData: Case?
    let basePrognose: Int

    @EnvironmentObject var kiProvider: KIProvider

    @State private var hiddenIds: Set<String> = []
    @State private var exportLoading = false
    @State private var dossierLoading = false
    @State private var dossier: VerhandlungsDossier?
    @State private var motives: MotivAnalyse?
    @State private var loadingMotives = false
    @State private var motiveError: String?
    @State private var expandedSection: String? = "args_e"
    @State private var alertMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                if let d = dossier { dossierCard(d) }
                toggleLists
                motiveCard
            }
            .padding()
        }
        .navigationTitle("Was-wäre-wenn-Simulation")
        .alert("Hinweis",
               isPresented: Binding(get: { alertMessage != nil }, set: { _ in alertMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: { Text(alertMessage ?? "") }
    }

    // MARK: - Berechnung

    /// Lokale Prognose (1:1 zur React-Funktion `computePrognose`).
    private func computeSimPrognose(hidden: Set<String>) -> Int {
        let activeArgs = args.filter { !hidden.contains($0.id) }
        let activeEv = evidence.filter { !hidden.contains($0.id) }
        let activeDl = deadlines.filter { !hidden.contains($0.id) }

        let eigene = activeArgs.filter { $0.side == .eigen }
        let gegner = activeArgs.filter { $0.side == .gegner }
        let eigenStaerke = eigene.reduce(0.0) { $0 + ($1.strength ?? 5) }
        let gegnerStaerke = gegner.reduce(0.0) { $0 + ($1.strength ?? 5) }
        let argBasis: Double = (eigene.count > 0 || gegner.count > 0)
            ? max(0, ((eigenStaerke / Double(max(1, eigene.count))) -
                      (gegnerStaerke / Double(max(1, gegner.count)))) * 5 + 50)
            : 50
        let avgEvidW: Double = activeEv.isEmpty ? 5 :
            activeEv.reduce(0.0) { $0 + ($1.weight ?? 5) } / Double(activeEv.count)
        let beweisBoost = 1 + (avgEvidW / 10) * 0.5
        let contradictions = activeArgs.filter { $0.isContradiction }.count
        let kantenEffekt = max(0.2, 1 - Double(contradictions) * 0.2)
        let judges = persons.filter { $0.role == .richter }
        let avgGlaubw: Double = judges.isEmpty ? 80 :
            judges.reduce(0.0) { $0 + ($1.glaubwuerdigkeit ?? 80) } / Double(judges.count)
        let zeugenMult = 0.70 + (avgGlaubw / 100) * 0.30
        let richterRate = judges.first?.klaegerRate ?? caseData?.richterKlaegerRate ?? 50
        let richterAdj = 1 + (richterRate - 50) / 100 * 0.15
        let versaeumt = activeDl.filter { $0.status == .versaeumt }.count
        let fristenFaktor = max(0.5, 1 - Double(versaeumt) * 0.30)
        let raw = argBasis * beweisBoost * kantenEffekt * zeugenMult * richterAdj * fristenFaktor
        return min(99, max(1, Int(raw.rounded())))
    }

    private var baseSim: Int { computeSimPrognose(hidden: []) }
    private var simNow: Int { computeSimPrognose(hidden: hiddenIds) }
    private var delta: Int { simNow - baseSim }

    private var eigenArgs: [Argument] { args.filter { $0.side == .eigen } }
    private var gegnerArgs: [Argument] { args.filter { $0.side == .gegner } }

    // MARK: - Sub-Views

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("🔮 Was-wäre-wenn-Simulation").bold()
                    Text("Blende Elemente aus, um ihre Auswirkung zu messen.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { hiddenIds.removeAll() } label: {
                    Label("Zurücksetzen", systemImage: "arrow.counterclockwise")
                }
                Button {
                    Task { await generateDossier() }
                } label: {
                    Label(dossierLoading ? "Erstelle…" : "Verhandlungs-Dossier", systemImage: "book")
                }
                .disabled(dossierLoading)
                Button {
                    Task { await exportProzessnotiz() }
                } label: {
                    Label(exportLoading ? "Erstelle…" : "Prozessnotiz exportieren", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .disabled(exportLoading)
            }
            HStack(spacing: 24) {
                prognoseBar("Basis (alle aktiv)", value: baseSim, delta: nil)
                prognoseBar("Simuliert", value: simNow, delta: delta)
            }
            if hiddenIds.count > 0 {
                Label(deltaInfoText, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(deltaColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(deltaColor)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var deltaColor: Color {
        delta > 0 ? .green : (delta < 0 ? .red : .gray)
    }
    private var deltaInfoText: String {
        let n = hiddenIds.count
        if delta > 0 { return "\(n) ausgeblendet → Prognose steigt um \(delta)% wenn wir diese Elemente gewinnen" }
        if delta < 0 { return "\(n) ausgeblendet → Prognose sinkt um \(abs(delta))% ohne diese Elemente" }
        return "\(n) ausgeblendet → Kein Einfluss"
    }

    private func prognoseBar(_ label: String, value: Int, delta: Int?) -> some View {
        let color: Color = value >= 60 ? .green : (value >= 40 ? .orange : .red)
        return VStack(alignment: .leading) {
            HStack {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(value)%").bold()
                if let d = delta, d != 0 {
                    Text("\(d > 0 ? "+" : "")\(d)%").font(.caption).bold()
                        .foregroundStyle(d > 0 ? .green : .red)
                }
            }
            ProgressView(value: Double(value), total: 100).tint(color)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func dossierCard(_ d: VerhandlungsDossier) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Verhandlungs-Dossier", systemImage: "book.closed.fill").bold()
                    Spacer()
                    Button("✕") { dossier = nil }.buttonStyle(.plain)
                }
                if let s = d.openingStatement {
                    VStack(alignment: .leading) {
                        Text("📢 ERÖFFNUNGSSTATEMENT").font(.caption).bold().foregroundStyle(.blue)
                        Text("„\(s)"")
                            .font(.subheadline).italic()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.9), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                }
                if !d.staerksteArgumente.isEmpty {
                    Text("💪 STÄRKSTE EIGENE ARGUMENTE").font(.caption).bold().foregroundStyle(.secondary)
                    ForEach(d.staerksteArgumente) { a in
                        VStack(alignment: .leading) {
                            Text(a.argument).bold().font(.caption)
                            if let e = a.einsatz { Text("Einsatz: \(e)").font(.caption2).foregroundStyle(.secondary) }
                            if let f = a.formulierung { Text("„\(f)"").font(.caption2).italic() }
                        }
                        .padding(8).background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                if !d.gegnerSchwachstellen.isEmpty {
                    Text("⚔️ GEGNERISCHE SCHWACHSTELLEN").font(.caption).bold().foregroundStyle(.secondary)
                    ForEach(d.gegnerSchwachstellen) { s in
                        VStack(alignment: .leading) {
                            Text(s.schwachstelle).bold().font(.caption)
                            if let a = s.angriffspunkt { Text("→ \(a)").font(.caption2) }
                        }
                        .padding(8).background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                if !d.verhandlungsziele.isEmpty {
                    Text("🎯 DIE 3 WICHTIGSTEN VERHANDLUNGSZIELE").font(.caption).bold().foregroundStyle(.secondary)
                    ForEach(Array(d.verhandlungsziele.prefix(3).enumerated()), id: \.element.id) { (i, z) in
                        HStack(alignment: .top) {
                            Text("\(i+1)").bold().font(.caption2)
                                .padding(6).background(Circle().fill(.black)).foregroundStyle(.white)
                            VStack(alignment: .leading) {
                                Text(z.ziel).bold().font(.caption)
                                if let p = z.prioritaet {
                                    Text(p).font(.caption2).bold().foregroundStyle(p == "hoch" ? .red : .orange)
                                }
                                if let t = z.taktik { Text(t).font(.caption2).foregroundStyle(.secondary) }
                            }
                            Spacer()
                        }
                    }
                }
                if !d.roteLinien.isEmpty {
                    VStack(alignment: .leading) {
                        Text("🛑 ROTE LINIEN").font(.caption).bold().foregroundStyle(.red)
                        ForEach(d.roteLinien, id: \.self) { Text("• \($0)").font(.caption) }
                    }
                    .padding()
                    .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                }
            }
        }
    }

    @ViewBuilder
    private var toggleLists: some View {
        GroupBox {
            VStack(spacing: 6) {
                section(id: "args_e", label: "✅ Eigene Argumente (\(eigenArgs.count))") {
                    if eigenArgs.isEmpty { Text("Keine").font(.caption).foregroundStyle(.secondary) }
                    ForEach(eigenArgs) { a in
                        toggleRow(id: a.id, title: a.title,
                                  badge: "\(Int(a.strength ?? 5))/10", color: .green)
                    }
                }
                section(id: "args_g", label: "⚔️ Gegner-Argumente (\(gegnerArgs.count))") {
                    if gegnerArgs.isEmpty { Text("Keine").font(.caption).foregroundStyle(.secondary) }
                    ForEach(gegnerArgs) { a in
                        toggleRow(id: a.id, title: a.title,
                                  badge: "\(Int(a.strength ?? 5))/10", color: .red)
                    }
                }
                section(id: "evidence", label: "🔍 Beweise (\(evidence.count))") {
                    if evidence.isEmpty { Text("Keine").font(.caption).foregroundStyle(.secondary) }
                    ForEach(evidence) { e in
                        toggleRow(id: e.id, title: e.title,
                                  badge: "\(Int(e.weight ?? 5))/10", color: .blue)
                    }
                }
                section(id: "deadlines", label: "⏰ Fristen (\(deadlines.count))") {
                    if deadlines.isEmpty { Text("Keine").font(.caption).foregroundStyle(.secondary) }
                    ForEach(deadlines) { d in
                        toggleRow(id: d.id, title: d.title,
                                  badge: d.side.rawValue,
                                  color: d.side == .gegner ? .red : .gray)
                    }
                }
            }
        }
    }

    private func section<Content: View>(id: String, label: String,
                                        @ViewBuilder content: @escaping () -> Content) -> some View {
        DisclosureGroup(
            isExpanded: Binding(get: { expandedSection == id },
                                set: { expandedSection = $0 ? id : nil })
        ) {
            VStack(spacing: 4) { content() }
                .padding(.top, 4)
        } label: {
            Text(label).font(.caption).bold().foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func toggleRow(id: String, title: String, badge: String, color: Color) -> some View {
        let isHidden = hiddenIds.contains(id)
        return HStack {
            Button {
                if isHidden { hiddenIds.remove(id) } else { hiddenIds.insert(id) }
            } label: {
                Image(systemName: isHidden ? "eye.slash" : "eye").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            Text(title).font(.caption)
                .strikethrough(isHidden)
                .foregroundStyle(isHidden ? .secondary : .primary)
            Spacer()
            Text(badge).font(.caption2).bold()
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(color.opacity(0.15), in: Capsule())
                .foregroundStyle(color)
        }
        .padding(6)
        .background(isHidden ? Color.gray.opacity(0.1) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6))
    }

    @ViewBuilder
    private var motiveCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Label("Hintergedanken & Timing-Analyse", systemImage: "brain")
                            .bold()
                        Text("Warum argumentiert / setzt der Gegner JETZT Fristen?")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        Task { await runMotiveAnalysis() }
                    } label: {
                        Label(loadingMotives ? "Analysiere…" : "Motive aufdecken", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(loadingMotives)
                }
                if let err = motiveError {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red).font(.caption)
                }
                if let m = motives { motiveContent(m) }
            }
        }
    }

    @ViewBuilder
    private func motiveContent(_ m: MotivAnalyse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !m.roteFlaggen.isEmpty {
                VStack(alignment: .leading) {
                    Text("🚩 Rote Flaggen").font(.caption).bold().foregroundStyle(.red)
                    ForEach(m.roteFlaggen, id: \.self) { Text("• \($0)").font(.caption) }
                }
                .padding(8).background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
            if let t = m.timingAnalyse {
                labeled("⏰ Warum JETZT?", t, .orange)
            }
            if let f = m.fristenHintergedanken {
                labeled("📅 Fristen-Hintergedanken", f, .orange)
            }
            if !m.verdeckteZiele.isEmpty {
                VStack(alignment: .leading) {
                    Text("🎭 Verdeckte Ziele").font(.caption).bold().foregroundStyle(.secondary)
                    ForEach(m.verdeckteZiele, id: \.self) {
                        Label($0, systemImage: "arrow.right").font(.caption2)
                    }
                }
            }
            if !m.psychologischeTaktiken.isEmpty {
                VStack(alignment: .leading) {
                    Text("🧠 Psychologische Taktiken").font(.caption).bold().foregroundStyle(.secondary)
                    ForEach(m.psychologischeTaktiken) { t in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(t.taktik).font(.caption).bold()
                                Spacer()
                                Text(t.intensitaet).font(.caption2).bold()
                                    .foregroundStyle(t.intensitaet == "hoch" ? .red :
                                                     t.intensitaet == "mittel" ? .orange : .blue)
                            }
                            if let b = t.beweis { Text(b).font(.caption2).foregroundStyle(.secondary) }
                        }
                        .padding(6)
                        .background(.background, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            if let n = m.naechsterSchrittGegner {
                labeled("🔮 Nächster Schritt des Gegners", n, .gray)
            }
            if let r = m.empfohleneReaktion {
                VStack(alignment: .leading) {
                    Text("✅ Empfohlene Reaktion").font(.caption).bold().foregroundStyle(.green)
                    Text(r).font(.caption)
                }
                .padding()
                .background(Color.green.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)
            }
        }
    }

    private func labeled(_ title: String, _ text: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).bold().foregroundStyle(.secondary)
            Text(text).font(.caption)
        }
        .padding(8)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - KI-Funktionen

    /// Generiert eine kompakte Verhandlungsmappe aus aktuellen Argumenten.
    private func generateDossier() async {
        dossierLoading = true; defer { dossierLoading = false }
        let activeEigen = eigenArgs.filter { !hiddenIds.contains($0.id) }
        let activeGegner = gegnerArgs.filter { !hiddenIds.contains($0.id) }

        let prompt = """
        Du bist ein erfahrener Prozessanwalt. Erstelle ein kompaktes Verhandlungs-Dossier
        für die nächste Sitzung.

        Fall: \(caseData?.fallname ?? "") | AZ: \(caseData?.aktenzeichen ?? "")
        Aktuelle Prognose: \(simNow)% (Basis: \(baseSim)%)

        STARKE EIGENE ARGUMENTE:
        \(activeEigen.filter { ($0.strength ?? 5) >= 6 }.map { "- \($0.title)" }.joined(separator: "\n"))

        GEGNERISCHE SCHWACHSTELLEN:
        \(activeGegner.filter { ($0.strength ?? 5) < 6 }.map { "- \($0.title)" }.joined(separator: "\n"))
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "staerkste_argumente": ["type": "array"],
                "gegner_schwachstellen": ["type": "array"],
                "verhandlungsziele": ["type": "array"],
                "opening_statement": ["type": "string"],
                "rote_linien": ["type": "array", "items": ["type": "string"]]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseData?.id)
        guard case .success(let any) = res, let dict = any as? [String: Any] else {
            alertMessage = "Dossier konnte nicht erstellt werden."
            return
        }
        var d = VerhandlungsDossier()
        d.openingStatement = dict["opening_statement"] as? String
        d.roteLinien = dict["rote_linien"] as? [String] ?? []
        if let arr = dict["staerkste_argumente"] as? [[String: Any]] {
            d.staerksteArgumente = arr.map {
                DossierArg(argument: $0["argument"] as? String ?? "",
                           einsatz: $0["einsatz"] as? String,
                           formulierung: $0["formulierung"] as? String)
            }
        }
        if let arr = dict["gegner_schwachstellen"] as? [[String: Any]] {
            d.gegnerSchwachstellen = arr.map {
                DossierGS(schwachstelle: $0["schwachstelle"] as? String ?? "",
                          angriffspunkt: $0["angriffspunkt"] as? String)
            }
        }
        if let arr = dict["verhandlungsziele"] as? [[String: Any]] {
            d.verhandlungsziele = arr.map {
                DossierZiel(ziel: $0["ziel"] as? String ?? "",
                            prioritaet: $0["prioritaet"] as? String,
                            taktik: $0["taktik"] as? String)
            }
        }
        dossier = d
    }

    /// KI-Analyse des gegnerischen Verhaltens und Timings.
    private func runMotiveAnalysis() async {
        loadingMotives = true; defer { loadingMotives = false }
        motiveError = nil
        let prompt = """
        Du bist Prozessanwalt + Verhaltensstratege (Sun Tzu + Machiavelli).
        Analysiere die TIMING-STRATEGIE der Gegenseite.

        Fall: \(caseData?.fallname ?? "") | Rechtsgebiet: \(caseData?.rechtsgebiet ?? "")
        Zentrale Frage: \(caseData?.zentraleRechtsfrage ?? "")
        Gegnerargumente: \(gegnerArgs.count) | Eigene: \(eigenArgs.count)
        Fristen Gegenseite: \(deadlines.filter { $0.side == .gegner }.count)
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "timing_analyse": ["type": "string"],
                "fristen_hintergedanken": ["type": "string"],
                "verdeckte_ziele": ["type": "array", "items": ["type": "string"]],
                "psychologische_taktiken": ["type": "array"],
                "naechster_schritt_gegner": ["type": "string"],
                "empfohlene_reaktion": ["type": "string"],
                "rote_flaggen": ["type": "array", "items": ["type": "string"]]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseData?.id)
        switch res {
        case .failure(let e):
            motiveError = e.localizedDescription
        case .success(let any):
            guard let dict = any as? [String: Any] else { motiveError = "Ungültige Antwort"; return }
            var m = MotivAnalyse()
            m.timingAnalyse = dict["timing_analyse"] as? String
            m.fristenHintergedanken = dict["fristen_hintergedanken"] as? String
            m.verdeckteZiele = dict["verdeckte_ziele"] as? [String] ?? []
            m.naechsterSchrittGegner = dict["naechster_schritt_gegner"] as? String
            m.empfohleneReaktion = dict["empfohlene_reaktion"] as? String
            m.roteFlaggen = dict["rote_flaggen"] as? [String] ?? []
            if let arr = dict["psychologische_taktiken"] as? [[String: Any]] {
                m.psychologischeTaktiken = arr.map {
                    MotivTaktik(taktik: $0["taktik"] as? String ?? "",
                                beweis: $0["beweis"] as? String,
                                intensitaet: $0["intensitaet"] as? String ?? "mittel")
                }
            }
            motives = m
        }
    }

    /// Erstellt eine Prozessnotiz als TXT-Datei und kopiert in die Zwischenablage.
    /// (Kein PDF-Export, da PDFKit/UIKit auf macOS nicht erlaubt ist.)
    private func exportProzessnotiz() async {
        exportLoading = true; defer { exportLoading = false }
        let prompt = """
        Erstelle eine vollständige taktische Analyse für folgendes Verfahren.
        Fall: \(caseData?.fallname ?? "") | AZ: \(caseData?.aktenzeichen ?? "")
        Eigene Argumente (\(eigenArgs.count)):
        \(eigenArgs.map { "- \($0.title) (\(Int($0.strength ?? 5))/10)" }.joined(separator: "\n"))
        Gegnerargumente (\(gegnerArgs.count)):
        \(gegnerArgs.map { "- \($0.title) (\(Int($0.strength ?? 5))/10)" }.joined(separator: "\n"))

        Erstelle eine Prozessnotiz mit:
        1. Strategien der Gegenseite + Gegenmaßnahme
        2. Timing-Analyse
        3. Psychologische Taktiken
        4. Verhandlungsführung
        5. Warnsignale
        6. Gesamtempfehlung
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "zusammenfassung": ["type": "string"],
                "gegner_strategien": ["type": "array"],
                "timing_analyse": ["type": "string"],
                "psychologische_taktiken": ["type": "array"],
                "verhandlungsfuehrung": ["type": "string"],
                "warnsignale": ["type": "array", "items": ["type": "string"]],
                "gesamtempfehlung": ["type": "string"]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseData?.id)
        guard case .success(let any) = res, let dict = any as? [String: Any] else {
            alertMessage = "Export fehlgeschlagen."; return
        }

        var txt = "PROZESSNOTIZ — TAKTISCHE ANALYSE\n"
        txt += "Fall: \(caseData?.fallname ?? "") | AZ: \(caseData?.aktenzeichen ?? "")\n"
        txt += "Erstellt: \(Date().formatted(date: .abbreviated, time: .omitted))\n"
        txt += "VERTRAULICH — Anwaltsgeheimnis § 203 StGB\n\n"

        if let z = dict["zusammenfassung"] as? String { txt += "EXECUTIVE SUMMARY\n\(z)\n\n" }
        if let arr = dict["gegner_strategien"] as? [[String: Any]] {
            txt += "STRATEGIEN DER GEGENSEITE\n"
            for (i, s) in arr.enumerated() {
                txt += "\(i+1). \(s["strategie"] as? String ?? "")\n"
                if let d = s["beschreibung"] as? String { txt += "   \(d)\n" }
                if let g = s["gegenmasnahme"] as? String { txt += "   → GEGENMASSNAHME: \(g)\n" }
            }
            txt += "\n"
        }
        if let t = dict["timing_analyse"] as? String { txt += "TIMING-ANALYSE\n\(t)\n\n" }
        if let arr = dict["psychologische_taktiken"] as? [[String: Any]] {
            txt += "PSYCHOLOGISCHE TAKTIKEN\n"
            for t in arr {
                txt += "- \(t["taktik"] as? String ?? "")\n"
                if let b = t["beschreibung"] as? String { txt += "  \(b)\n" }
                if let g = t["gegenmasnahme"] as? String { txt += "  → \(g)\n" }
            }
            txt += "\n"
        }
        if let v = dict["verhandlungsfuehrung"] as? String { txt += "VERHANDLUNGSFÜHRUNG\n\(v)\n\n" }
        if let warn = dict["warnsignale"] as? [String] {
            txt += "WARNSIGNALE\n"
            warn.forEach { txt += "⚠ \($0)\n" }
            txt += "\n"
        }
        if let g = dict["gesamtempfehlung"] as? String { txt += "GESAMTEMPFEHLUNG\n\(g)\n" }

        // In Zwischenablage kopieren (macOS-konform)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(txt, forType: .string)
        alertMessage = "Prozessnotiz wurde in die Zwischenablage kopiert."
    }
}
