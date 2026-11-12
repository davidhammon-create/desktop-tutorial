import SwiftUI
struct TabFallsubstanz: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var subTab = 0
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $subTab) {
                Text("Argumente & Beweise").tag(0)
                Text("Zeitstrahl").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 16)
            if subTab == 0 {
                TabArgumenteBeweiseView(viewModel: viewModel, kiMode: kiMode)
            } else {
                TabZeitstrahlView(viewModel: viewModel, kiMode: kiMode)
            }
        }
    }
}
struct TabZeitstrahlView: View {
    let viewModel: CaseDetailViewModel
    let kiMode: Bool
    @State private var laeuft = false
    @State private var ergebnis: String? = nil
    @State private var zeitstrahlFehler: String?
    var body: some View {
        VStack(spacing: 16) {
            if let err = zeitstrahlFehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            HStack {
                Label("Zeitstrahl", systemImage: "calendar")
                    .font(.title2.bold())
                Spacer()
                if kiMode {
                    Button { Task { await ausDokumentenGenerieren() } } label: {
                        if laeuft { ProgressView().scaleEffect(0.7) }
                        else { Label("Aus Dokumenten generieren", systemImage: "doc.text.magnifyingglass") }
                    }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                    .controlSize(.small)
                    .disabled(laeuft)
                    Button { Task { await fotosVideosAnalysieren() } } label: {
                        Label("Fotos & Videos mit KI analysieren", systemImage: "photo.on.rectangle.angled")
                    }
                    .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                    .controlSize(.small)
                    .disabled(laeuft)
                }
            }
            if !viewModel.timeline.isEmpty {
                ForEach(viewModel.timeline) { ev in
                    HStack {
                        Text(ev.datum.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(.secondary)
                        Text(ev.title).font(.system(size: 12, weight: .medium))
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            if let text = ergebnis {
                Text(text).font(.system(size: 12)).lineSpacing(4)
                    .padding(10)
                    .background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
            } else if viewModel.timeline.isEmpty {
                InfoHinweis(titel: "Zeitstrahl", nachricht: "Generieren Sie Ereignisse aus Dokumenten oder analysieren Sie Fotos/Videos mit KI.", symbol: "calendar")
            }
        }
    }
    private func ausDokumentenGenerieren() async {
        guard let fall = viewModel.fall else { return }
        laeuft = true
        zeitstrahlFehler = nil
        defer { laeuft = false }
        let docs = viewModel.dokumente
        guard !docs.isEmpty else {
            await MainActor.run { ergebnis = "Keine Dokumente vorhanden — bitte zuerst Dokumente hochladen." }
            return
        }
        let docsText = docs.map { "- \($0.title): \($0.ai_summary ?? "keine Zusammenfassung")" }.joined(separator: "\n")
        let prompt = """
        Analysiere die folgenden Falldokumente und extrahiere alle relevanten Ereignisse für einen Zeitstrahl.
        Fall: \(fall.fallname)
        Rechtsgebiet: \(fall.rechtsgebiet ?? "")
        Dokumente:
        \(docsText)
        Erkenne auch Vertragsvereinbarungen mit Fristen und ob sie eingehalten wurden.
        Erstelle separate Ereignisse für Dokument vs. Foto vs. Video wenn erkennbar.
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: ["type": "object", "properties": [
                    "ereignisse": ["type": "array", "items": ["type": "object", "properties": [
                        "date": ["type": "string"],
                        "title": ["type": "string"],
                        "description": ["type": "string"],
                        "category": ["type": "string"],
                        "importance": ["type": "string"]
                    ]]]
                ]] as [String: Any],
                model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId,
                logKiName: "Zeitstrahl aus Dokumenten"
            )
            guard let dict = result.dictValue,
                  let liste = dict["ereignisse"] as? [[String: Any]] else { return }
            var created = 0
            var speicherFehler: String?
            for ev in liste {
                guard let title = ev["title"] as? String, !title.isEmpty else { continue }
                let dateStr = ev["date"] as? String ?? ""
                let event = TimelineEvent(
                    case_id: viewModel.caseId,
                    title: title,
                    description: ev["description"] as? String,
                    datum: parseKIDatum(dateStr),
                    typ: mapTimelineTyp(ev["category"] as? String),
                    wichtigkeit: mapWichtigkeit(ev["importance"] as? String)
                )
                do {
                    let saved = try await Services.timelineEvents.create(event)
                    await MainActor.run { viewModel.timeline.append(saved) }
                    created += 1
                } catch {
                    speicherFehler = error.localizedDescription
                }
            }
            await MainActor.run {
                if let speicherFehler, created == 0 {
                    zeitstrahlFehler = "Ereignisse erkannt, Speichern fehlgeschlagen: \(speicherFehler)"
                    ergebnis = nil
                } else if let speicherFehler {
                    zeitstrahlFehler = "\(created) gespeichert, weitere nicht: \(speicherFehler)"
                    ergebnis = nil
                } else {
                    ergebnis = created > 0 ? "\(created) Ereignisse aus Dokumenten generiert und gespeichert." : "Keine Ereignisse erkannt."
                }
            }
        } catch {
            await MainActor.run { zeitstrahlFehler = error.localizedDescription }
        }
    }
    private func parseKIDatum(_ s: String) -> Date {
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: s) { return d }
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        for fmt in ["yyyy-MM-dd", "dd.MM.yyyy", "dd.MM.yy"] {
            df.dateFormat = fmt
            if let d = df.date(from: s) { return d }
        }
        return Date()
    }
    private func mapTimelineTyp(_ category: String?) -> TimelineEvent.TimelineTyp {
        guard let c = category?.lowercased() else { return .ereignis }
        if c.contains("frist") { return .frist }
        if c.contains("verhandlung") { return .hearing }
        if c.contains("urteil") || c.contains("entscheid") { return .entscheidung }
        if c.contains("schriftsatz") || c.contains("klage") { return .schriftsatz }
        return .ereignis
    }
    private func mapWichtigkeit(_ importance: String?) -> Int {
        switch importance?.lowercased() {
        case "kritisch": return 10
        case "hoch": return 8
        case "niedrig": return 3
        default: return 5
        }
    }
    private func fotosVideosAnalysieren() async {
        laeuft = true
        zeitstrahlFehler = nil
        defer { laeuft = false }
        let media = viewModel.beweise.filter { $0.type == .augenschein || $0.type == .dokument }
        let prompt = "Analysiere folgende Beweismittel (Foto/Video) juristisch:\n\(media.map(\.title).joined(separator: "\n"))"
        do {
            let text = try await LLMService.shared.invokeText(
                prompt: prompt,
                model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId,
                logKiName: "Zeitstrahl — Fotos & Videos"
            )
            await MainActor.run { ergebnis = text }
        } catch {
            await MainActor.run { zeitstrahlFehler = error.localizedDescription }
        }
    }
}
struct ArgumentBilanzView: View {
    let argumente: [Argument]
    var avgEigen: Double {
        let eigen = argumente.filter { $0.side == .eigen }
        guard !eigen.isEmpty else { return 0 }
        return eigen.reduce(0) { $0 + $1.effectiveStrength } / Double(eigen.count)
    }
    var avgGegner: Double {
        let gegner = argumente.filter { $0.side == .gegner }
        guard !gegner.isEmpty else { return 0 }
        return gegner.reduce(0) { $0 + $1.effectiveStrength } / Double(gegner.count)
    }
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(String(format: "%.1f", avgEigen))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.green)
                Text("Eigene Ø")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.red.opacity(0.2))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(avgEigen >= avgGegner ? Color.green : Color.orange)
                        .frame(width: proxy.size.width * CGFloat(avgEigen / 10.0), height: 8)
                }
            }
            .frame(height: 8)
            VStack(spacing: 2) {
                Text(String(format: "%.1f", avgGegner))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.red)
                Text("Gegner Ø")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}
struct ArgumentKarte: View {
    let argument: Argument
    let viewModel: CaseDetailViewModel
    @State private var aufgeklappt = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: argument.side == .eigen ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(argument.side == .eigen ? .green : .red)
                    .font(.system(size: 14))
                Text(argument.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(aufgeklappt ? .max : 2)
                Spacer()
                StaerkeAnzeige(staerke: argument.effectiveStrength, seite: argument.side)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { aufgeklappt.toggle() }
                } label: {
                    Image(systemName: aufgeklappt ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            if aufgeklappt {
                Divider().padding(.horizontal, 10)
                VStack(alignment: .leading, spacing: 6) {
                    if let desc = argument.description {
                        Text(desc)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    if let bewertung = argument.ki_bewertung {
                        KITransparenzZeile(text: bewertung, transparenz: .argumentKIBewertung(argument))
                    }
                    if let rechtsgrundlage = argument.rechtsgrundlage {
                        HStack(spacing: 4) {
                            Image(systemName: "book.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                            Text(rechtsgrundlage)
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    if let counter = argument.counter_argument {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Gegenargument:")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                            Text(counter)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(6)
                        .background(Color.orange.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(10)
            }
        }
        .background(argument.side == .eigen ? Color.green.opacity(0.04) : Color.red.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(argument.side == .eigen ? Color.green.opacity(0.15) : Color.red.opacity(0.15), lineWidth: 1)
        )
    }
}
struct StaerkeAnzeige: View {
    let staerke: Double
    let seite: Argument.ArgumentSeite
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<10) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(i < Int(staerke) ? (seite == .eigen ? Color.green : Color.red) : Color.gray.opacity(0.2))
                    .frame(width: 4, height: 12)
            }
            Text("\(Int(staerke))/10")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(seite == .eigen ? .green : .red)
                .padding(.leading, 2)
        }
    }
}
struct BeweisQualitaetsView: View {
    let beweise: [Evidence]
    var avgGewicht: Double {
        beweise.reduce(0) { $0 + $1.effectiveWeight } / Double(beweise.count)
    }
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "scale.3d")
                .foregroundStyle(.teal)
            Text("Ø Beweisgewicht: ")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f/10", avgGewicht))
                .font(.caption.bold())
                .foregroundStyle(avgGewicht >= 7 ? .green : avgGewicht >= 4 ? .orange : .red)
            Spacer()
            Text("\(beweise.count) Beweismittel")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(Color.teal.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}
struct BeweisKarte: View {
    let beweis: Evidence
    let viewModel: CaseDetailViewModel
    @State private var aufgeklappt = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: beweis.type.symbol)
                    .font(.system(size: 13))
                    .foregroundStyle(.teal)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(beweis.title)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(beweis.type.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if let source = beweis.source {
                            Text("·")
                            Text(source).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                Text("\(Int(beweis.effectiveWeight))/10")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(beweis.effectiveWeight >= 7 ? .green : beweis.effectiveWeight >= 4 ? .orange : .red)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { aufgeklappt.toggle() }
                } label: {
                    Image(systemName: aufgeklappt ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            if aufgeklappt {
                Divider().padding(.horizontal, 10)
                VStack(alignment: .leading, spacing: 6) {
                    if let desc = beweis.description {
                        Text(desc)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    if let bewertung = beweis.ki_bewertung {
                        KITransparenzZeile(text: bewertung, transparenz: .beweisKIBewertung(beweis))
                    }
                }
                .padding(10)
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.teal.opacity(0.15), lineWidth: 1))
    }
}
struct KITransparenzZeile: View {
    let text: String
    var transparenz: TransparenzInhalt? = nil
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "brain")
                .font(.system(size: 10))
                .foregroundStyle(.purple)
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            FenlynineOSTransparenzInfoButton(inhalt: transparenz ?? .kiModul(
                titel: "KI-Bewertung",
                begruendung: text,
                ausgabe: text
            ))
        }
        .padding(6)
        .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
    }
}
struct NeuesArgumentSheet: View {
    let caseId: String
    let onCreated: (Argument) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var side = Argument.ArgumentSeite.eigen
    @State private var strength = 5.0
    @State private var rechtsgrundlage = ""
    @State private var isSaving = false
    @State private var speichernFehler: String?
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Neues Argument", systemImage: "text.bubble.fill")
                    .font(.title3.bold())
                Spacer()
                Button("Abbrechen") { dismiss() }
            }
            .padding(20)
            Divider()
            Form {
                TextField("Titel *", text: $title)
                Picker("Seite", selection: $side) {
                    ForEach(Argument.ArgumentSeite.allCases, id: \.self) {
                        Text($0.bezeichnung).tag($0)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Stärke: \(Int(strength))/10")
                        .font(.caption)
                    Slider(value: $strength, in: 1...10, step: 1)
                        .tint(side == .eigen ? .green : .red)
                }
                TextField("Beschreibung", text: $description, axis: .vertical)
                    .lineLimit(3...6)
                TextField("Rechtsgrundlage (z.B. § 242 BGB)", text: $rechtsgrundlage)
                if let err = speichernFehler {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
            }
            .formStyle(.grouped)
            Divider()
            HStack {
                Spacer()
                Button("Hinzufügen") {
                    Task { await speichern() }
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .disabled(title.isEmpty || isSaving)
            }
            .padding(16)
        }
        .frame(width: 420, height: 440)
    }
    private func speichern() async {
        isSaving = true
        speichernFehler = nil
        var arg = Argument(case_id: caseId, title: title)
        arg.side = side
        arg.strength = Int(strength)
        if !description.isEmpty { arg.description = description }
        if !rechtsgrundlage.isEmpty { arg.rechtsgrundlage = rechtsgrundlage }
        do {
            let created = try await Services.arguments.create(arg)
            await MainActor.run { onCreated(created); dismiss() }
        } catch {
            await MainActor.run { speichernFehler = error.localizedDescription }
        }
        isSaving = false
    }
}
struct NeuerBeweisSheet: View {
    let caseId: String
    var argumente: [Argument] = []
    var vorgewaehltesArgumentId: String? = nil
    let onCreated: (Evidence) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var type = Evidence.EvidenceType.dokument
    @State private var weight = 5.0
    @State private var source = ""
    @State private var linkedArgumentId: String = ""
    @State private var isSaving = false
    @State private var speichernFehler: String?
    @State private var bereitsAngelegt: Evidence?
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Neues Beweismittel", systemImage: "doc.text.magnifyingglass")
                    .font(.title3.bold())
                Spacer()
                Button("Abbrechen") { dismiss() }
            }
            .padding(20)
            Divider()
            Form {
                TextField("Bezeichnung *", text: $title)
                Picker("Typ", selection: $type) {
                    ForEach(Evidence.EvidenceType.allCases, id: \.self) {
                        Label($0.rawValue, systemImage: $0.symbol).tag($0)
                    }
                }
                if !argumente.isEmpty {
                    Picker("Mit Argument verknüpfen", selection: $linkedArgumentId) {
                        Text("— Keine —").tag("")
                        ForEach(argumente) { arg in
                            Text(arg.title).tag(arg.id ?? "")
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Gewicht: \(Int(weight))/10")
                        .font(.caption)
                    Slider(value: $weight, in: 1...10, step: 1)
                        .tint(.teal)
                }
                TextField("Quelle", text: $source)
                if let err = speichernFehler {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
            }
            .formStyle(.grouped)
            Divider()
            HStack {
                Spacer()
                Button("Hinzufügen") {
                    Task { await speichern() }
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .disabled(title.isEmpty || isSaving)
            }
            .padding(16)
        }
        .frame(width: 420, height: argumente.isEmpty ? 380 : 440)
        .onAppear {
            if let pre = vorgewaehltesArgumentId { linkedArgumentId = pre }
        }
    }
    private func speichern() async {
        isSaving = true
        speichernFehler = nil
        var angelegt = bereitsAngelegt
        do {
            if angelegt == nil {
                var bew = Evidence(case_id: caseId, title: title)
                bew.type = type
                bew.weight = Int(weight)
                if !source.isEmpty { bew.source = source }
                if !linkedArgumentId.isEmpty {
                    bew.linked_argument_ids = [linkedArgumentId]
                }
                angelegt = try await Services.evidence.create(bew)
                bereitsAngelegt = angelegt
            }
            guard let created = angelegt else {
                throw CocoaError(.coderValueNotFound)
            }
            if !linkedArgumentId.isEmpty {
                guard let evId = created.id else {
                    throw CocoaError(.coderReadCorrupt)
                }
                var arg = try await Services.arguments.get(id: linkedArgumentId)
                var ids = Set(arg.linked_evidence_ids ?? [])
                ids.insert(evId)
                arg.linked_evidence_ids = Array(ids)
                _ = try await Services.arguments.update(id: linkedArgumentId, entity: arg)
            }
            await MainActor.run { onCreated(created); dismiss() }
        } catch {
            let text = angelegt == nil
                ? error.localizedDescription
                : "Beweismittel ist gespeichert, die Verknüpfung nicht: \(error.localizedDescription)"
            await MainActor.run { speichernFehler = text }
        }
        isSaving = false
    }
}
