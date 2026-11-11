import SwiftUI
import Charts
struct TabSimulationCockpit: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var subTab = 0
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $subTab) {
                Text("Verhandlung").tag(0)
                Text("Gesamtbewertung").tag(1)
                Text("Cockpit").tag(2)
                Text("Netzwerk").tag(3)
                Text("Stärken-Analyse").tag(4)
                Text("Strategie-Checkliste").tag(5)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 16)
            switch subTab {
            case 0: VerhandlungssimulationView(viewModel: viewModel, kiMode: kiMode)
            case 1: GesamtbewertungView(viewModel: viewModel, kiMode: kiMode)
            case 2: VerhandlungsCockpit(viewModel: viewModel, kiMode: kiMode)
            case 3: CaseInfluenceGraphView(viewModel: viewModel)
            case 4: SubstanzDiagrammeView(viewModel: viewModel)
            default: StrategieChecklisteView(viewModel: viewModel, kiMode: kiMode)
            }
        }
    }
}
struct VerhandlungsSimView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var richterStil = "Neutral"
    @State private var fokus = ""
    @State private var result: VerhandlungsResult? = nil
    @State private var laeuft = false
    @State private var fehler: String? = nil
    @State private var timeline: [TimelineEvent] = []
    @State private var neuesEreignis = false
    @State private var neuesEvTitel = ""
    @State private var neuesEvDatum = Date()
    @State private var neuesEvTyp = "schritt"
    let richterStile = ["Neutral", "Kooperativ", "Streng", "Prozessaktiv", "Vergleichsorientiert"]
    struct VerhandlungsResult {
        var szenarien: [Szenario]
        var gesamtempfehlung: String
        struct Szenario: Identifiable {
            let id = UUID()
            var titel: String
            var einwand: String
            var reaktionPrimaer: String
            var reaktionAlternativ: String
            var bewertung: String
            var taktikHinweis: String
        }
    }
    struct TimelineEvent: Identifiable, Codable {
        let id: String
        var title: String
        var date: Date
        var type: String
        var notes: String
        var done: Bool
        init(title: String, date: Date, type: String, notes: String = "") {
            id = UUID().uuidString
            self.title = title
            self.date = date
            self.type = type
            self.notes = notes
            done = false
        }
    }
    let eventTypes = [
        ("frist", "Frist", "⏰"), ("korrespondenz", "Korrespondenz", "✉️"),
        ("schritt", "Verhandlungsschritt", "⚖️"), ("termin", "Gerichtstermin", "🏛️"),
        ("massnahme", "Maßnahme", "📋")
    ]
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Verhandlungsszenarien", systemImage: "theatermasks")
                    .font(.title2.bold())
                Text("KI simuliert gegnerische Einwände und generiert Reaktionsskripte")
                    .font(.subheadline).foregroundStyle(.secondary)
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Richter-Stil").font(.caption).foregroundStyle(.secondary)
                        Picker("Stil", selection: $richterStil) {
                            ForEach(richterStile, id: \.self) { Text($0).tag($0) }
                        }
                        .labelsHidden()
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fokus / Schwerpunkt (optional)").font(.caption).foregroundStyle(.secondary)
                        TextField("z.B. Beweisantrag, §123 StPO…", text: $fokus)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                HStack(spacing: 10) {
                    let eigen = viewModel.argumente.filter { $0.side == .eigen }.count
                    let gegner = viewModel.argumente.filter { $0.side == .gegner }.count
                    Text("\(eigen) eigene · \(gegner) Gegner-Argumente geladen")
                        .font(.caption).foregroundStyle(.secondary)
                    if eigen == 0 && gegner == 0 {
                        Label("Keine Argumente – erst in Tab Substanz hinzufügen", systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(.orange)
                    }
                    Spacer()
                    if kiMode {
                        Button {
                            Task { await szenerienGenerieren() }
                        } label: {
                            if laeuft {
                                ProgressView().scaleEffect(0.7)
                                Text("Simuliere…").font(.caption)
                            } else {
                                Label("Verhandlungsszenarien generieren", systemImage: "theatermasks.fill")
                            }
                        }
                        .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                        .disabled(laeuft)
                    }
                }
                if let err = fehler {
                    Label(err, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.red)
                }
            }
            if let r = result {
                VStack(spacing: 12) {
                    ForEach(r.szenarien) { s in
                        SzenarienKarte2(szenario: s)
                    }
                    if !r.gesamtempfehlung.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "scope").foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Gesamtempfehlung").font(.system(size: 12, weight: .semibold))
                                Text(r.gesamtempfehlung).font(.system(size: 12)).lineSpacing(3)
                            }
                        }
                        .padding(12)
                        .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            } else if !laeuft {
                InfoHinweis(titel: "Szenarien simulieren", nachricht: "Die KI analysiert gegnerische Einwände und gibt präzise Reaktionsskripte mit Alternativreaktionen.", symbol: "theatermasks")
            }
            Divider()
            PrognoseTimeline(
                viewModel: viewModel,
                localEvents: $timeline,
                neuesEreignis: $neuesEreignis,
                neuesEvTitel: $neuesEvTitel,
                neuesEvDatum: $neuesEvDatum,
                neuesEvTyp: $neuesEvTyp,
                eventTypes: eventTypes
            )
        }
    }
    private func szenerienGenerieren() async {
        guard let fall = viewModel.fall else { return }
        laeuft = true; fehler = nil
        defer { laeuft = false }
        let eigene = viewModel.argumente.filter { $0.side == .eigen }
        let gegner = viewModel.argumente.filter { $0.side == .gegner }
        let prompt = """
        Du bist Verhandlungscoach für den Anwalt. Erstelle Reaktionsskripte für die Verhandlung.
        Fall: \(fall.fallname), Rechtsgebiet: \(fall.rechtsgebiet ?? ""), Prognose: \(Int(fall.prognose ?? 50))%
        Eigene Argumente (\(eigene.count)): \(eigene.prefix(5).map { "\($0.title) (Stärke \($0.strength)/10)" }.joined(separator: "; "))
        Gegner-Argumente (\(gegner.count)): \(gegner.prefix(5).map { "\($0.title) (Stärke \($0.strength)/10)" }.joined(separator: "; "))
        Richter-Stil: \(richterStil)
        \(fokus.isEmpty ? "" : "Fokus: \(fokus)")
        Erstelle 3–5 realistische Verhandlungsszenarien mit Einwand, Reaktion, Alternativreaktion, Bewertung und Taktikhinweis.
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: [
                    "type": "object",
                    "properties": [
                        "szenarien": ["type": "array", "items": ["type": "object", "properties": [
                            "titel": ["type": "string"], "einwand": ["type": "string"],
                            "reaktion_primaer": ["type": "string"], "reaktion_alternativ": ["type": "string"],
                            "bewertung": ["type": "string"], "taktik_hinweis": ["type": "string"]
                        ] as [String: Any]]],
                        "gesamtempfehlung": ["type": "string"]
                    ] as [String: Any]
                ] as [String: Any]
            )
            guard let dict = result.dictValue else {
                await MainActor.run { fehler = "KI konnte keine Szenarien generieren." }
                return
            }
            let szenarien = (dict["szenarien"] as? [[String: Any]] ?? []).map {
                VerhandlungsResult.Szenario(
                    titel: $0["titel"] as? String ?? "",
                    einwand: $0["einwand"] as? String ?? "",
                    reaktionPrimaer: $0["reaktion_primaer"] as? String ?? "",
                    reaktionAlternativ: $0["reaktion_alternativ"] as? String ?? "",
                    bewertung: $0["bewertung"] as? String ?? "neutral",
                    taktikHinweis: $0["taktik_hinweis"] as? String ?? ""
                )
            }
            await MainActor.run {
                self.result = VerhandlungsResult(szenarien: szenarien, gesamtempfehlung: dict["gesamtempfehlung"] as? String ?? "")
            }
        } catch {
            await MainActor.run { fehler = "Fehler bei der KI-Analyse. Bitte erneut versuchen." }
        }
    }
}
struct SzenarienKarte2: View {
    let szenario: VerhandlungsSimView.VerhandlungsResult.Szenario
    var bewertungFarbe: Color {
        switch szenario.bewertung {
        case "günstig": return .green
        case "ungünstig": return .red
        default: return .gray
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(szenario.titel).font(.system(size: 13, weight: .bold))
                Spacer()
                if !szenario.bewertung.isEmpty {
                    Text(szenario.bewertung.capitalized)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(bewertungFarbe.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                        .foregroundStyle(bewertungFarbe)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                if !szenario.einwand.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Text("⚔️").font(.system(size: 11))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Einwand Gegenseite").font(.system(size: 10, weight: .semibold)).foregroundStyle(.red)
                            Text("\u{201E}\(szenario.einwand)\u{201C}").font(.system(size: 11)).italic()
                        }
                    }
                }
                if !szenario.reaktionPrimaer.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Text("✅").font(.system(size: 11))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Primäre Reaktion").font(.system(size: 10, weight: .semibold)).foregroundStyle(.green)
                            Text(szenario.reaktionPrimaer).font(.system(size: 11))
                        }
                    }
                }
                if !szenario.reaktionAlternativ.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Text("↩").font(.system(size: 11))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Alternativreaktion").font(.system(size: 10, weight: .semibold)).foregroundStyle(.blue)
                            Text(szenario.reaktionAlternativ).font(.system(size: 11))
                        }
                    }
                }
                if !szenario.taktikHinweis.isEmpty {
                    HStack(spacing: 4) {
                        Text("💡").font(.system(size: 10))
                        Text("Taktik: \(szenario.taktikHinweis)").font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(bewertungFarbe.opacity(0.2), lineWidth: 1))
    }
}
struct PrognoseTimeline: View {
    let viewModel: CaseDetailViewModel
    @Binding var localEvents: [VerhandlungsSimView.TimelineEvent]
    @Binding var neuesEreignis: Bool
    @Binding var neuesEvTitel: String
    @Binding var neuesEvDatum: Date
    @Binding var neuesEvTyp: String
    let eventTypes: [(String, String, String)]
    @State private var aufgeklappt = true
    var allItems: [TimelineItemU] {
        let fromFristen = viewModel.fristen.map { f in
            TimelineItemU(id: f.id ?? UUID().uuidString, title: f.title, date: f.due_date, type: "frist", notes: f.frist_type.rawValue, done: f.status == .erledigt, source: "db")
        }
        let fromLocal = localEvents.map { e in
            TimelineItemU(id: e.id, title: e.title, date: e.date, type: e.type, notes: e.notes, done: e.done, source: "local")
        }
        return (fromFristen + fromLocal).sorted { $0.date < $1.date }
    }
    struct TimelineItemU: Identifiable {
        var id: String
        var title: String
        var date: Date
        var type: String
        var notes: String
        var done: Bool
        var source: String
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { aufgeklappt.toggle() }
            } label: {
                HStack {
                    Label("Interaktive Prozess-Timeline", systemImage: "calendar")
                        .font(.system(size: 12, weight: .semibold))
                    Text("(\(allItems.count) Ereignisse)").font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        neuesEreignis.toggle()
                    } label: {
                        Label("Ereignis", systemImage: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                    .controlSize(.mini)
                    Image(systemName: aufgeklappt ? "chevron.up" : "chevron.down").font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            if neuesEreignis {
                HStack(spacing: 8) {
                    TextField("Titel", text: $neuesEvTitel)
                        .textFieldStyle(.roundedBorder)
                    DatePicker("", selection: $neuesEvDatum, displayedComponents: .date).labelsHidden()
                    Picker("", selection: $neuesEvTyp) {
                        ForEach(eventTypes, id: \.0) { t in Text(t.1).tag(t.0) }
                    }.labelsHidden().frame(maxWidth: 130)
                    Button("Add") {
                        if !neuesEvTitel.isEmpty {
                            localEvents.append(VerhandlungsSimView.TimelineEvent(title: neuesEvTitel, date: neuesEvDatum, type: neuesEvTyp))
                            neuesEvTitel = ""
                            neuesEreignis = false
                        }
                    }.buttonStyle(FenlynineOSGlassProminentButtonStyle()).controlSize(.small)
                    Button("×") { neuesEreignis = false }.buttonStyle(.plain).foregroundStyle(.secondary)
                }
            }
            if aufgeklappt {
                let now = Date()
                let future = allItems.filter { $0.date >= now }
                let past = allItems.filter { $0.date < now }
                if !future.isEmpty {
                    Text("⏭ AUSSTEHEND").font(.system(size: 9, weight: .heavy)).foregroundStyle(.secondary)
                    ForEach(future) { item in timelineZeile(item, now: now) }
                }
                if !past.isEmpty {
                    Text("📁 VERGANGEN").font(.system(size: 9, weight: .heavy)).foregroundStyle(.secondary)
                    ForEach(past.reversed()) { item in timelineZeile(item, now: now) }
                }
                if allItems.isEmpty {
                    Text("Keine Ereignisse – Fristen erscheinen hier automatisch.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
    @ViewBuilder
    private func timelineZeile(_ item: TimelineItemU, now: Date) -> some View {
        let days = Calendar.current.dateComponents([.day], from: now, to: item.date).day ?? 0
        let typeInfo = eventTypes.first { $0.0 == item.type }
        HStack(spacing: 10) {
            Text(typeInfo?.2 ?? "📌").font(.system(size: 12))
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title).font(.system(size: 12, weight: .medium))
                    .strikethrough(item.done)
                HStack(spacing: 4) {
                    let timeLabel = item.date >= now ? (days == 0 ? "Heute" : "in \(days)d") : "\(abs(days))d vergangen"
                    let timeColor: Color = days < 0 ? .secondary : days < 3 ? .red : days < 14 ? .orange : .green
                    Text(timeLabel)
                        .font(.caption2).foregroundStyle(timeColor)
                    Text("· \(item.date.formatted(date: .abbreviated, time: .omitted))").font(.caption2).foregroundStyle(.tertiary)
                    if !item.notes.isEmpty { Text("· \(item.notes)").font(.caption2).foregroundStyle(.tertiary) }
                }
            }
            Spacer()
            if item.source == "local" && !item.done {
                Button {
                    if let idx = localEvents.firstIndex(where: { $0.id == item.id }) {
                        localEvents[idx].done = true
                    }
                } label: {
                    Image(systemName: "checkmark.circle").font(.caption)
                }
                .buttonStyle(.plain).foregroundStyle(.green)
                Button {
                    localEvents.removeAll { $0.id == item.id }
                } label: {
                    Image(systemName: "xmark").font(.caption)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
struct TabAktionVoll: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var subTab = 0
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $subTab) {
                Text("Aktionsplan").tag(0)
                Text("Schriftsatz-Generator").tag(1)
                Text("Verhandlungsszenarien").tag(2)
                Text("Argumentketten").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 16)
            switch subTab {
            case 0:
                TabAktion(viewModel: viewModel)
            case 1:
                SchriftsatzGeneratorView(viewModel: viewModel, kiMode: kiMode)
            case 2:
                VerhandlungsSimView(viewModel: viewModel, kiMode: kiMode)
            default:
                ArgumentationskettenView(viewModel: viewModel, kiMode: kiMode)
            }
        }
    }
}
struct SchriftsatzGeneratorView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    enum SchriftsatzTyp: String, CaseIterable {
        case klage = "Klageschrift"
        case berufung = "Berufungsschrift"
        case revision = "Revisionsbegründung"
        case einspruch = "Einspruch gegen Versäumnisurteil"
        case beschwerde = "Beschwerdeschrift"
        case antrag = "Antrag auf einstweilige Verfügung"
        case stellungnahme = "Stellungnahme / Erwiderung"
        case vergleich = "Vergleichsvorschlag"
        case widerspruch = "Widerspruchsbegründung"
        case sonstige = "Sonstige Schriftsatz"
    }
    @State private var typ: SchriftsatzTyp = .stellungnahme
    @State private var zusatzhinweise = ""
    @State private var generiert: String? = nil
    @State private var laeuft = false
    @State private var schriftsatzFehler: String?
    var body: some View {
        VStack(spacing: 16) {
            if let err = schriftsatzFehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            HStack {
                Label("KI-Schriftsatz-Generator", systemImage: "doc.text.below.ecg.fill")
                    .font(.title2.bold())
                Spacer()
                Button {
                    Task { await schriftsatzGenerieren() }
                } label: {
                    if laeuft {
                        ProgressView().scaleEffect(0.7)
                        Text("Generiere…").font(.caption)
                    } else {
                        Label("Schriftsatz generieren", systemImage: "wand.and.stars")
                    }
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .disabled(laeuft || !kiMode)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Schriftsatz-Typ").font(.caption).foregroundStyle(.secondary)
                    Picker("Typ", selection: $typ) {
                        ForEach(SchriftsatzTyp.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Zusätzliche Hinweise (optional)").font(.caption).foregroundStyle(.secondary)
                    TextField("z.B. Fokus auf §123, bestimmte Beweise…", text: $zusatzhinweise)
                        .textFieldStyle(.roundedBorder)
                }
            }
            if let text = generiert {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Generierter Schriftsatz", systemImage: "doc.text").font(.system(size: 12, weight: .semibold))
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(text, forType: .string)
                        } label: {
                            Label("Kopieren", systemImage: "doc.on.clipboard")
                        }
                        .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                        .controlSize(.small)
                        Button {
                            exportAlsPDF(text: text)
                        } label: {
                            Label("PDF", systemImage: "arrow.down.doc")
                        }
                        .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                        .controlSize(.small)
                    }
                    ScrollView {
                        Text(text)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(10)
                    }
                    .frame(maxHeight: 500)
                    .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                }
            } else if !laeuft {
                InfoHinweis(
                    titel: "Juristischer Schriftsatz-Generator",
                    nachricht: "Die KI erstellt einen vollständigen Schriftsatz basierend auf den erfassten Falldaten, Argumenten und Beweisen — fertig zum Überarbeiten und Einreichen.",
                    symbol: "doc.text.below.ecg.fill"
                )
            }
        }
    }
    private func schriftsatzGenerieren() async {
        guard let fall = viewModel.fall else { return }
        laeuft = true
        schriftsatzFehler = nil
        defer { laeuft = false }
        let eigene = viewModel.argumente.filter { $0.side == .eigen }
        let gegnerArgs = viewModel.argumente.filter { $0.side == .gegner }
        let argBlock = eigene.enumerated().map { i, a in
            let evList = viewModel.beweise.filter { ($0.linked_argument_ids ?? []).contains(a.id ?? "") }
            return "\(i + 1). \(a.title) (Stärke: \(a.strength)/10)\n   \(a.description ?? "")\n   Beweise: \(evList.map { "[\($0.title)]" }.joined(separator: ", "))"
        }.joined(separator: "\n\n")
        let prompt = """
        Du bist ein erfahrener deutscher Rechtsanwalt und verfasst juristische Schriftsätze im professionellen deutschen Kanzleistil.
        Erstelle einen vollständigen \(typ.rawValue) mit folgenden Angaben:
        FALLDATEN:
        - Fallname: \(fall.fallname)
        - Aktenzeichen: \(fall.aktenzeichen ?? "[Aktenzeichen]")
        - Gericht: \(fall.gericht ?? "[Gericht]")
        - Rechtsgebiet: \(fall.rechtsgebiet ?? "[Rechtsgebiet]")
        - Zentrale Rechtsfrage: \(fall.zentrale_rechtsfrage ?? "[Rechtsfrage]")
        - Prozessziel: \(fall.prozessziel ?? "[Prozessziel]")
        - Prognose: \(Int(fall.prognose ?? 50))%
        EIGENE ARGUMENTE UND BEWEISE:
        \(argBlock.isEmpty ? "Keine Argumente vorhanden" : argBlock)
        GEGNER-ARGUMENTE (zum Entkräften):
        \(gegnerArgs.map { "- \($0.title): \($0.description ?? "")" }.joined(separator: "\n"))
        \(zusatzhinweise.isEmpty ? "" : "ZUSÄTZLICHE ANWEISUNGEN:\n\(zusatzhinweise)")
        ANFORDERUNGEN:
        - Verwende professionellen juristischen deutschen Kanzleistil
        - Füge Platzhalter [ANLAGE X] für Beweisdokumente ein
        - Gliedere in: Rubrum, Antrag, Sachverhalt, Rechtliche Würdigung, Beweisangebote, Schluss
        - Zitiere relevante Normen (§§)
        - Markiere Platzhalter für variable Daten mit [...]
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: ["type": "object", "properties": [
                    "schriftsatz": ["type": "string"],
                    "anlagen_liste": ["type": "array", "items": ["type": "string"]],
                    "hinweise": ["type": "string"]
                ]] as [String: Any],
                model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId,
                logKiName: "Schriftsatz — \(typ.rawValue)"
            )
            if let dict = result.dictValue, let text = dict["schriftsatz"] as? String {
                await MainActor.run { generiert = text }
            }
        } catch {
            await MainActor.run { schriftsatzFehler = error.localizedDescription }
        }
    }
    private func exportAlsPDF(text: String) {
        guard let fall = viewModel.fall else { return }
        let dateStr = Date().formatted(date: .abbreviated, time: .omitted)
        let filename = "\(fall.fallname)_Schriftsatz_\(dateStr).txt"
        guard let basis = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            schriftsatzFehler = "Downloads-Ordner nicht gefunden."
            return
        }
        let url = basis.appendingPathComponent(filename)
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            NSWorkspace.shared.open(url)
        } catch {
            schriftsatzFehler = "Export fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}
struct TabAbschluss: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var subTab = 0
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $subTab) {
                Text("Abschluss").tag(0)
                Text("KI-Protokoll").tag(1)
                Text("Zeitstrahl").tag(2)
                Text("Prognose-Vergleich").tag(3)
                Text("Risiko").tag(4)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 16)
            switch subTab {
            case 0: TabAbschlussInhalt(viewModel: viewModel, kiMode: kiMode)
            case 1: TabKIProtokoll(viewModel: viewModel)
            case 2: TabZeitstrahlView(viewModel: viewModel, kiMode: kiMode)
            case 3: TabPrognoseVergleichView(viewModel: viewModel, kiMode: kiMode)
            default: TabAbschlussRisikoView(viewModel: viewModel, kiMode: kiMode)
            }
        }
    }
}
struct TabAbschlussRisikoView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    var body: some View {
        VStack(spacing: 20) {
            TabRisiko(viewModel: viewModel)
            KIRisikoMatrixView(viewModel: viewModel, kiMode: kiMode)
        }
    }
}
struct TabAbschlussInhalt: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var ergebnis = ""
    @State private var urteilArt = "Urteil"
    @State private var urteilDatum = Date()
    @State private var entschaedigung = ""
    @State private var lehren = ""
    @State private var kiAbschluss: AnyCodable?
    @State private var laeuft = false
    @State private var gespeichert = false
    @State private var abschlussFehler: String?
    let urteilArten = ["Urteil", "Vergleich", "Einigung außergerichtlich", "Klagerücknahme", "Sonstiges"]
    var body: some View {
        VStack(spacing: 20) {
            AbschlussMonteCarloView(viewModel: viewModel, kiMode: kiMode)
            if let kiDict = viewModel.fall?.ki_berater_result?.dictValue {
                DokumentKiBeraterPanel(ki: kiDict)
            }
            HStack {
                Label("Fallabschluss & Dokumentation", systemImage: "checkmark.seal.fill")
                    .font(.title2.bold())
                Spacer()
                if let fall = viewModel.fall, fall.status == .abgeschlossen {
                    Label("Abgeschlossen", systemImage: "checkmark.seal.fill")
                        .font(.caption).foregroundStyle(.green)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Art des Abschlusses").font(.caption).foregroundStyle(.secondary)
                        Picker("Art", selection: $urteilArt) {
                            ForEach(urteilArten, id: \.self) { Text($0).tag($0) }
                        }.labelsHidden()
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Datum").font(.caption).foregroundStyle(.secondary)
                        DatePicker("", selection: $urteilDatum, displayedComponents: .date).labelsHidden()
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ergebnis / Tenor des Urteils *").font(.caption).foregroundStyle(.secondary)
                    TextField("z.B. Klage abgewiesen, Schadensersatz 15.000 €…", text: $ergebnis, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Entschädigung / Kosten").font(.caption).foregroundStyle(.secondary)
                    TextField("z.B. Kosten trägt Beklagte, 3.500 € erstattet…", text: $entschaedigung)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lessons Learned / Erkenntnisse").font(.caption).foregroundStyle(.secondary)
                    TextField("Was kann man aus diesem Fall für künftige Fälle mitnehmen?", text: $lehren, axis: .vertical)
                        .lineLimit(2...5)
                        .textFieldStyle(.roundedBorder)
                }
                HStack {
                    Button {
                        Task { await kiAbschlussErstellen() }
                    } label: {
                        if laeuft {
                            ProgressView().scaleEffect(0.7)
                            Text("Analysiere…").font(.caption)
                        } else {
                            Label("KI-Abschlussanalyse", systemImage: "brain")
                        }
                    }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                    .disabled(laeuft || ergebnis.isEmpty || !kiMode)
                    Spacer()
                    Button(gespeichert ? "✓ Gespeichert" : "Fall abschließen") {
                        Task { await fallAbschliessen() }
                    }
                    .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                    .disabled(ergebnis.isEmpty || gespeichert)
                }
            }
            .padding(14)
            .background(Color.green.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.15), lineWidth: 1))
            if let err = abschlussFehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            if let ki = kiAbschluss?.dictValue {
                AbschlussKIAnalyseView(analyse: ki)
            }
            if let fall = viewModel.fall {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Fallstatistiken").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        AbschlussKachel(symbol: "doc.text", titel: "Argumente", wert: "\(viewModel.argumente.count)")
                        AbschlussKachel(symbol: "photo.fill", titel: "Beweise", wert: "\(viewModel.beweise.count)")
                        AbschlussKachel(symbol: "person.2.fill", titel: "Personen", wert: "\(viewModel.personen.count)")
                        AbschlussKachel(symbol: "clock.fill", titel: "Fristen", wert: "\(viewModel.fristen.count)")
                    }
                    if let erstellt = fall.created_at {
                        let dauer = Calendar.current.dateComponents([.day], from: erstellt, to: Date()).day ?? 0
                        HStack {
                            Image(systemName: "calendar").foregroundStyle(.secondary)
                            Text("Falldauer: \(dauer) Tage (seit \(erstellt.formatted(date: .abbreviated, time: .omitted)))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    private func fallAbschliessen() async {
        guard let fall = viewModel.fall, let id = fall.id else { return }
        var updated = fall
        updated.status = .abgeschlossen
        updated.urteil = ergebnis
        do {
            let saved = try await Services.cases.update(id: id, entity: updated)
            await MainActor.run {
                viewModel.fall = saved
                gespeichert = true
                abschlussFehler = nil
            }
        } catch {
            await MainActor.run { abschlussFehler = error.localizedDescription }
        }
    }
    private func kiAbschlussErstellen() async {
        guard let fall = viewModel.fall else { return }
        laeuft = true
        abschlussFehler = nil
        defer { laeuft = false }
        let prompt = """
        Erstelle eine professionelle Abschlussanalyse für folgenden Fall:
        Fall: \(fall.fallname) | \(fall.rechtsgebiet ?? "") | Instanz: \(fall.instanz.rawValue)
        Abschluss: \(urteilArt) vom \(urteilDatum.formatted(date: .abbreviated, time: .omitted))
        Ergebnis: \(ergebnis)
        Entschädigung/Kosten: \(entschaedigung.isEmpty ? "—" : entschaedigung)
        Lessons Learned (Nutzer): \(lehren.isEmpty ? "—" : lehren)
        Ausgangsprognose: \(Int(fall.prognose ?? 50))%
        Argumente: \(viewModel.argumente.count) | Beweise: \(viewModel.beweise.count)
        Analysiere strukturiert:
        1) Was erklärt das Ergebnis?
        2) War die Prognose realistisch?
        3) Was hätte man anders machen können?
        4) Welche strategischen Lehren lassen sich ziehen?
        5) Wie klassifiziert sich dieses Ergebnis im Rechtsgebiet?
        TRANSPARENZ: Erkläre die Methodik deiner Bewertung.
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: [
                    "type": "object",
                    "properties": [
                        "ergebnis_analyse": ["type": "string"],
                        "prognose_bewertung": ["type": "string"],
                        "alternative_strategien": ["type": "array", "items": ["type": "string"]],
                        "strategische_lehren": ["type": "array", "items": ["type": "string"]],
                        "rechtsgebiet_einordnung": ["type": "string"],
                        "gesamtfazit": ["type": "string"]
                    ] as [String: Any]
                ] as [String: Any],
                model: "claude_sonnet_4_6"
            )
            await MainActor.run { kiAbschluss = result }
            if let dict = result.dictValue {
                let ausgabe = (dict["gesamtfazit"] as? String ?? "") + "\n" + (dict["ergebnis_analyse"] as? String ?? "")
                await KIProtokollService.log(
                    caseId: viewModel.caseId,
                    kiName: "KI-Abschlussanalyse",
                    eingabe: prompt,
                    ausgabe: ausgabe,
                    modell: "claude_sonnet_4_6"
                )
            }
        } catch {
            await MainActor.run { abschlussFehler = error.localizedDescription }
        }
    }
}
struct AbschlussKIAnalyseView: View {
    let analyse: [String: Any]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("KI-Abschlussanalyse", systemImage: "brain")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.purple)
            if let text = analyse["ergebnis_analyse"] as? String, !text.isEmpty {
                AbschlussKISection(titel: "Ergebnisanalyse", text: text)
            }
            if let text = analyse["prognose_bewertung"] as? String, !text.isEmpty {
                AbschlussKISection(titel: "Prognose-Bewertung", text: text)
            }
            if let items = analyse["alternative_strategien"] as? [String], !items.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alternative Strategien").font(.caption.bold()).foregroundStyle(.secondary)
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•").foregroundStyle(.orange)
                            Text(item).font(.system(size: 12))
                        }
                    }
                }
            }
            if let items = analyse["strategische_lehren"] as? [String], !items.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Strategische Lehren").font(.caption.bold()).foregroundStyle(.secondary)
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 6) {
                            Text("✓").foregroundStyle(.green)
                            Text(item).font(.system(size: 12))
                        }
                    }
                }
            }
            if let text = analyse["rechtsgebiet_einordnung"] as? String, !text.isEmpty {
                AbschlussKISection(titel: "Rechtsgebiet-Einordnung", text: text)
            }
            if let text = analyse["gesamtfazit"] as? String, !text.isEmpty {
                Text(text)
                    .font(.system(size: 12, weight: .medium))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
        .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
}
struct AbschlussKISection: View {
    let titel: String
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titel).font(.caption.bold()).foregroundStyle(.secondary)
            Text(text).font(.system(size: 12)).lineSpacing(3)
        }
    }
}
struct AbschlussKachel: View {
    let symbol: String
    let titel: String
    let wert: String
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: symbol).font(.system(size: 16)).foregroundStyle(.blue)
            Text(wert).font(.system(size: 18, weight: .bold, design: .rounded))
            Text(titel).font(.system(size: 9)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
}
struct VerhandlungssimulationView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    struct ChatMessage: Identifiable {
        let id = UUID()
        var role: String // "user" | "ki"
        var content: String
        var rolleLabel: String?
    }
    private let rollen = [
        ("anwalt_gegner", "Gegnerischer Anwalt", "Aggressiv, taktisch, sucht Schwachstellen", "⚖️"),
        ("richter", "Kritischer Richter", "Hinterfragt beide Seiten, skeptisch, präzise", "🧑‍⚖️"),
        ("verhandlungsfuehrer", "Verhandlungsführer (Harvard)", "Win-Win orientiert, sachlich, lösungsfokussiert", "🤝"),
        ("mandant_gegner", "Gegnerischer Mandant", "Emotional, stur, will maximalen Druck", "😤")
    ]
    private let szenarien = [
        ("eroefffnung", "Verhandlungseröffnung", "Erste Positionierung und Weichenstellung"),
        ("beweisangriff", "Beweisangriff", "Gegner greift Ihre Hauptbeweise an"),
        ("vergleich", "Vergleichsverhandlung", "Annäherung auf einen Vergleich"),
        ("kreuzverhoer", "Kreuzverhör Zeuge", "Glaubwürdigkeit eines Zeugen testen"),
        ("plaedoyer", "Schlussplädoyer", "Finale Argumentation vor Urteilsfindung")
    ]
    @State private var gewaehltRolle = "anwalt_gegner"
    @State private var gewaehltSzenario = "eroefffnung"
    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    @State private var started = false
    @State private var laeuft = false
    @State private var feedback: [String: Any]? = nil
    @State private var showFeedback = false
    @State private var urteilsAnalyse: [String: Any]? = nil
    @State private var showUrteil = false
    @State private var urteilLoading = false
    @State private var simFehler: String?
    var body: some View {
        VStack(spacing: 16) {
            if let err = simFehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            if !started {
                setupView
            } else {
                chatView
            }
        }
    }
    @ViewBuilder
    private var setupView: some View {
        VStack(spacing: 0) {
            Button {
                if urteilsAnalyse != nil && showUrteil {
                    showUrteil = false
                } else {
                    Task { await urteilsAnalyseStarten() }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles").foregroundStyle(.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("KI-Urteilsprognose & Gegenargumente")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Erfolgswahrscheinlichkeit + spezifische Gegenargumente der Gegenseite")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if urteilLoading { ProgressView().scaleEffect(0.7) }
                    else {
                        Image(systemName: showUrteil ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
            }
            .buttonStyle(.plain)
            .disabled(!kiMode || urteilLoading)
            if showUrteil, let ua = urteilsAnalyse {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Text("\(ua["erfolgswahrscheinlichkeit"] as? Int ?? Int(ua["erfolgswahrscheinlichkeit"] as? Double ?? 0))%")
                            .font(.title2.bold()).foregroundStyle(.blue)
                        Text("Erfolgswahrscheinlichkeit").font(.caption).foregroundStyle(.secondary)
                    }
                    if let b = KIJson.string(in: ua, keys: "begruendung", "beguendung") {
                        Text(b).font(.caption).lineSpacing(3)
                    }
                    if let gegen = ua["gegenargumente"] as? [[String: Any]], !gegen.isEmpty {
                        Text("Gegenargumente der Gegenseite").font(.caption.bold())
                        ForEach(Array(gegen.enumerated()), id: \.offset) { _, g in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(g["argument"] as? String ?? "").font(.caption)
                                if let z = g["zielt_auf"] as? String, !z.isEmpty {
                                    Text("Zielt auf: \(z)").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            .padding(8)
                            .background(Color.red.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    if let angriffe = ua["beweisangriffe"] as? [[String: Any]], !angriffe.isEmpty {
                        Text("Mögliche Beweisangriffe").font(.caption.bold())
                        ForEach(Array(angriffe.enumerated()), id: \.offset) { _, a in
                            Text("\(a["beweis"] as? String ?? ""): \(a["angriff"] as? String ?? "")")
                                .font(.caption2)
                        }
                    }
                    if let fragen = ua["richter_fragen"] as? [String], !fragen.isEmpty {
                        Text("Kritische Richterfragen").font(.caption.bold())
                        ForEach(fragen, id: \.self) { f in
                            Text("• \(f)").font(.caption2)
                        }
                    }
                }
                .padding([.horizontal, .bottom], 12)
            }
        }
        .background(Color.gray.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.12), lineWidth: 1))
        HStack {
            Label("Verhandlungssimulation", systemImage: "theatermasks.fill")
                .font(.title2.bold())
            Spacer()
        }
        Text("1. Gegenrolle wählen").font(.caption.bold())
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(rollen, id: \.0) { id, label, desc, emoji in
                Button {
                    gewaehltRolle = id
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(emoji) \(label)").font(.caption2.bold())
                        Text(desc).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(gewaehltRolle == id ? Color.primary.opacity(0.08) : Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        Text("2. Szenario wählen").font(.caption.bold())
        ForEach(szenarien, id: \.0) { id, label, desc in
            Button {
                gewaehltSzenario = id
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label).font(.caption)
                        Text(desc).font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if gewaehltSzenario == id { Image(systemName: "checkmark.circle.fill") }
                }
                .padding(8)
                .background(gewaehltSzenario == id ? Color.blue.opacity(0.08) : Color.gray.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        if kiMode {
            Button {
                Task { await simulationStarten() }
            } label: {
                if laeuft { ProgressView().scaleEffect(0.7) }
                else { Label("Simulation starten", systemImage: "play.fill") }
            }
            .buttonStyle(FenlynineOSGlassProminentButtonStyle())
            .disabled(laeuft)
        }
    }
    @ViewBuilder
    private var chatView: some View {
        HStack {
            Text(rollen.first { $0.0 == gewaehltRolle }?.1 ?? "").font(.caption.bold())
            Spacer()
            if messages.count >= 4 && kiMode {
                Button { Task { await feedbackAnfordern() } } label: {
                    Label("Feedback", systemImage: "chart.bar.doc.horizontal")
                }
                .buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.small)
            }
            Button { reset() } label: { Text("Neu").font(.caption) }.buttonStyle(.plain)
        }
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(messages) { m in
                    HStack {
                        if m.role == "ki" { Text("🤖").font(.caption) }
                        Text(m.content).font(.system(size: 12))
                            .padding(8)
                            .background(m.role == "user" ? Color.blue.opacity(0.08) : Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                        if m.role == "user" { Spacer() }
                    }
                }
                if laeuft { ProgressView().scaleEffect(0.7) }
            }
        }
        .frame(maxHeight: 300)
        HStack {
            TextField("Ihre Antwort…", text: $input)
                .textFieldStyle(.roundedBorder)
            Button {
                Task { await nachrichtSenden() }
            } label: {
                Image(systemName: "paperplane.fill")
            }
            .buttonStyle(FenlynineOSGlassProminentButtonStyle())
            .disabled(input.isEmpty || laeuft || !kiMode)
        }
        if showFeedback, let fb = feedback {
            VStack(alignment: .leading, spacing: 6) {
                Text("Coach-Feedback — Note: \(KIJson.intValue(fb["gesamtnote"]) ?? 0)/10")
                    .font(.caption.bold())
                if let staerken = fb["staerken"] as? [String], !staerken.isEmpty {
                    Text("Stärken: \(staerken.joined(separator: "; "))").font(.caption2)
                }
                if let schwaechen = fb["schwaechen"] as? [String], !schwaechen.isEmpty {
                    Text("Schwächen: \(schwaechen.joined(separator: "; "))").font(.caption2).foregroundStyle(.orange)
                }
                if let verpasst = fb["verpasste_chancen"] as? [String], !verpasst.isEmpty {
                    Text("Verpasste Chancen: \(verpasst.joined(separator: "; "))").font(.caption2).foregroundStyle(.red)
                }
                if let empfehlungen = fb["empfehlungen"] as? [String], !empfehlungen.isEmpty {
                    Text("Empfehlungen: \(empfehlungen.joined(separator: "; "))").font(.caption2)
                }
                if let fazit = fb["fazit"] as? String { Text(fazit).font(.caption) }
            }
            .padding(8)
            .background(Color.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }
    }
    private func fallKontext() -> String {
        guard let fall = viewModel.fall else { return "" }
        let eigene = viewModel.argumente.filter { $0.side == .eigen }
        let gegner = viewModel.argumente.filter { $0.side == .gegner }
        let streitwert = fall.streitwert.map { "\(Int($0))€" } ?? "unbekannt"
        return """
        Fall: \(fall.fallname) | \(fall.rechtsgebiet ?? "") | Streitwert: \(streitwert) | Prognose: \(Int(fall.prognose ?? 50))%
        Eigene Argumente: \(eigene.isEmpty ? "keine" : eigene.map { "\($0.title) (\($0.strength)/10)" }.joined(separator: ", "))
        Gegnerargumente: \(gegner.isEmpty ? "keine" : gegner.map { "\($0.title) (\($0.strength)/10)" }.joined(separator: ", "))
        """
    }
    private func simulationStarten() async {
        guard viewModel.fall != nil else { return }
        guard let rolle = rollen.first(where: { $0.0 == gewaehltRolle }),
              let szenario = szenarien.first(where: { $0.0 == gewaehltSzenario }) else {
            simFehler = "Rolle oder Szenario ist nicht mehr verfügbar."
            return
        }
        laeuft = true
        started = true
        simFehler = nil
        defer { laeuft = false }
        let prompt = """
        Du spielst die Rolle: \(rolle.1) (\(rolle.2)).
        Szenario: \(szenario.1) – \(szenario.2)
        Fallkontext: \(fallKontext())
        Beginne die Verhandlungssimulation mit deiner Eröffnung. Bleibe strikt in deiner Rolle, sei konkret auf den Fall bezogen und herausfordernd für den Anwalt. Maximal 3-4 Sätze als Einstieg.
        """
        do {
            let opening = try await LLMService.shared.invokeText(
                prompt: prompt,
                logCaseId: viewModel.caseId,
                logKiName: "Verhandlungssimulation — Eröffnung"
            )
            await MainActor.run {
                messages = [ChatMessage(role: "ki", content: opening, rolleLabel: rolle.1)]
            }
        } catch {
            await MainActor.run { simFehler = error.localizedDescription }
        }
    }
    private func nachrichtSenden() async {
        let userMsg = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMsg.isEmpty, let fall = viewModel.fall else { return }
        input = ""
        await MainActor.run { messages.append(ChatMessage(role: "user", content: userMsg)) }
        guard let rolle = rollen.first(where: { $0.0 == gewaehltRolle }),
              let szenario = szenarien.first(where: { $0.0 == gewaehltSzenario }) else {
            simFehler = "Rolle oder Szenario ist nicht mehr verfügbar."
            return
        }
        laeuft = true
        simFehler = nil
        defer { laeuft = false }
        let eigene = viewModel.argumente.filter { $0.side == .eigen }
        let gegner = viewModel.argumente.filter { $0.side == .gegner }
        let verlauf = messages.map { "\($0.role == "user" ? "ANWALT" : rolle.1): \($0.content)" }.joined(separator: "\n")
        let prompt = """
        Du spielst die Rolle: \(rolle.1) (\(rolle.2)).
        Szenario: \(szenario.1) – \(szenario.2)
        Fallkontext: Fall "\(fall.fallname)", \(fall.rechtsgebiet ?? ""), Prognose \(Int(fall.prognose ?? 50))%.
        Eigene Argumente: \(eigene.isEmpty ? "keine" : eigene.map { "\($0.title) (\($0.strength)/10)" }.joined(separator: ", "))
        Gegnerargumente: \(gegner.isEmpty ? "keine" : gegner.map { "\($0.title) (\($0.strength)/10)" }.joined(separator: ", "))
        BISHERIGER VERLAUF:
        \(verlauf)
        ANWALT: \(userMsg)
        Antworte als \(rolle.1). Bleibe in der Rolle, sei konkret, herausfordernd und beziehe dich auf die konkreten Argumente des Falls. Maximal 3-4 Sätze.
        """
        do {
            let res = try await LLMService.shared.invokeText(
                prompt: prompt,
                logCaseId: viewModel.caseId,
                logKiName: "Verhandlungssimulation — Dialog"
            )
            await MainActor.run { messages.append(ChatMessage(role: "ki", content: res, rolleLabel: rolle.1)) }
        } catch {
            await MainActor.run { simFehler = error.localizedDescription }
        }
    }
    private func feedbackAnfordern() async {
        guard let fall = viewModel.fall else { return }
        showFeedback = true
        laeuft = true
        simFehler = nil
        defer { laeuft = false }
        let szenarioLabel = szenarien.first { $0.0 == gewaehltSzenario }?.1 ?? ""
        let verlauf = messages.map { "\($0.role == "user" ? "ANWALT" : "GEGNER"): \($0.content)" }.joined(separator: "\n")
        let prompt = """
        Du bist ein erfahrener Anwalts-Coach. Analysiere folgende Verhandlungssimulation und gib konstruktives Feedback:
        SZENARIO: \(szenarioLabel)
        FALL: \(fall.fallname), \(fall.rechtsgebiet ?? "")
        VERLAUF:
        \(verlauf)
        Bewerte: Argumentationsqualität, taktisches Vorgehen, Reaktion auf Angriffe, Verhandlungsführung. Sei konkret und konstruktiv.
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: ["type": "object", "properties": [
                    "gesamtnote": ["type": "number"],
                    "staerken": ["type": "array", "items": ["type": "string"]],
                    "schwaechen": ["type": "array", "items": ["type": "string"]],
                    "verpasste_chancen": ["type": "array", "items": ["type": "string"]],
                    "empfehlungen": ["type": "array", "items": ["type": "string"]],
                    "fazit": ["type": "string"]
                ]] as [String: Any],
                logCaseId: viewModel.caseId,
                logKiName: "Verhandlungssimulation — Feedback"
            )
            let d = try KIJson.requireObject(result, kontext: "Verhandlungssimulation Feedback")
            await MainActor.run { feedback = d }
        } catch {
            await MainActor.run { simFehler = error.localizedDescription }
        }
    }
    private func urteilsAnalyseStarten() async {
        guard let fall = viewModel.fall else { return }
        urteilLoading = true
        showUrteil = true
        simFehler = nil
        defer { urteilLoading = false }
        let eigene = viewModel.argumente.filter { $0.side == .eigen }
        let gegner = viewModel.argumente.filter { $0.side == .gegner }
        let streitwert = fall.streitwert.map { "\(Int($0))€" } ?? "unbekannt"
        let prompt = """
        Du bist ein erfahrener Richter und Prozessstratege. Analysiere diesen Fall:
        Fall: "\(fall.fallname)" | \(fall.rechtsgebiet ?? "") | Gericht: \(fall.gericht ?? "")
        Streitwert: \(streitwert)
        Eigene Argumente: \(eigene.isEmpty ? "keine" : eigene.map { "\"\($0.title)\" (manuell:\($0.strength), KI:\($0.ki_strength.map { String(Int($0)) } ?? "n/a"))" }.joined(separator: ", "))
        Gegnerargumente: \(gegner.isEmpty ? "keine" : gegner.map { "\"\($0.title)\" (manuell:\($0.strength), KI:\($0.ki_strength.map { String(Int($0)) } ?? "n/a"))" }.joined(separator: ", "))
        Beweise: \(viewModel.beweise.isEmpty ? "keine" : viewModel.beweise.map { "\"\($0.title)\" Typ:\($0.type.rawValue) (manuell:\($0.weight), KI:\($0.ki_weight.map { String(Int($0)) } ?? "n/a"))" }.joined(separator: ", "))
        Berechne:
        1. Wahrscheinlichkeit eines erfolgreichen Urteils für uns (%)
        2. Liste spezifischer Gegenargumente der Gegenseite (mind. 5, direkt auf unsere Argumente bezogen)
        3. Welche Beweise könnte die Gegenseite angreifen und wie?
        4. Kritische Rechtsfragen die der Richter stellen wird
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: ["type": "object", "properties": [
                    "erfolgswahrscheinlichkeit": ["type": "number"],
                    "begruendung": ["type": "string"],
                    "gegenargumente": ["type": "array", "items": ["type": "object", "properties": [
                        "argument": ["type": "string"], "zielt_auf": ["type": "string"], "staerke": ["type": "number"]
                    ]]],
                    "beweisangriffe": ["type": "array", "items": ["type": "object", "properties": [
                        "beweis": ["type": "string"], "angriff": ["type": "string"]
                    ]]],
                    "richter_fragen": ["type": "array", "items": ["type": "string"]]
                ]] as [String: Any],
                logCaseId: viewModel.caseId,
                logKiName: "Verhandlungssimulation — Urteilsprognose"
            )
            let d = try KIJson.requireObject(result, kontext: "Urteilsprognose Simulation")
            await MainActor.run { urteilsAnalyse = d }
        } catch {
            await MainActor.run { simFehler = error.localizedDescription }
        }
    }
    private func reset() {
        messages = []
        started = false
        feedback = nil
        showFeedback = false
        urteilsAnalyse = nil
        showUrteil = false
    }
}
