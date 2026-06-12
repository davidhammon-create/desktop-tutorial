//
//  TabArgumenteView.swift
//  Konversion von src/components/lexara/TabArgumente.jsx (1155 Zeilen) nach SwiftUI.
//  Argumente-Tab mit KI-Bewertung, Batch-Bewertung, Argument-Extraktion aus
//  Dokumenten, Duplikat-Erkennung und Aufräum-Funktion ohne Belege.
//

import SwiftUI

struct TabArgumenteView: View {
    let caseId: String
    let caseData: Case?
    var onCountChange: (() -> Void)? = nil

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    // MARK: - State
    @State private var args: [Argument] = []
    @State private var evidence: [Evidence] = []
    @State private var filter: SideFilter = .all
    @State private var sortBy: SortMode = .created
    @State private var showAdd = false
    @State private var newArg = NewArgumentDraft()
    @State private var extractError: String?
    @State private var batchRating = false
    @State private var kiGenerating = false
    @State private var kiGenResult: KiGenResult?
    @State private var showExtraction = false
    @State private var extractMode: ExtractMode = .ki
    @State private var dsgvo = false
    @State private var text = ""
    @State private var extracting = false
    @State private var extracted: ExtractedResult?
    @State private var detectingDuplicates = false
    @State private var duplicates: [DuplicateGroup]?
    @State private var sheetMessage: String?

    // MARK: - Lokale Hilfstypen
    enum SideFilter: String, CaseIterable, Identifiable {
        case all, eigen, gegner
        var id: Self { self }
        var label: String {
            switch self { case .all: return "Alle"; case .eigen: return "Eigene"; case .gegner: return "Gegner" }
        }
    }

    enum SortMode: String, CaseIterable, Identifiable {
        case created, date, strength
        var id: Self { self }
        var label: String {
            switch self { case .created: return "Erstellt"; case .date: return "Datum"; case .strength: return "Stärke" }
        }
    }

    enum ExtractMode: String, CaseIterable, Identifiable {
        case algo, ki
        var id: Self { self }
        var label: String { self == .algo ? "Algorithmus" : "KI" }
    }

    struct NewArgumentDraft {
        var title = ""
        var description = ""
        var side: ArgumentSide = .eigen
        var strength: Double = 5
        var type: String = "Rechtsargument"
        var zeitpunkt: Date? = nil
        var anmerkungen = ""
    }

    /// Lokales Modell für KI-Extraktionsergebnisse.
    struct ExtractedResult {
        var zusammenfassung: String?
        var beweise: [ExtractedEvidence] = []
        var eigeneArgumente: [ExtractedArgument] = []
        var gegenseiteArgumente: [ExtractedArgument] = []
        var relevantePara: [String] = []
    }
    struct ExtractedEvidence: Identifiable {
        let id = UUID()
        var titel: String
        var beschreibung: String?
        var typ: String?
        var gewicht: Double?
    }
    struct ExtractedArgument: Identifiable {
        let id = UUID()
        var titel: String
        var beschreibung: String?
        var typ: String?
        var staerke: Double?
        var datum: String?
        var paragraphen: [String] = []
        var beweise: [ExtractedEvidence] = []
    }

    struct KiGenResult {
        var eigene: [ExtractedArgument] = []
        var gegner: [ExtractedArgument] = []
    }

    struct DuplicateGroup: Identifiable {
        let id = UUID()
        var nummern: [Int]
        var grund: String
        var zuBehalten: Int
    }

    // MARK: - Computed
    private var filtered: [Argument] {
        var list = args.filter { arg in
            filter == .all
            || (filter == .eigen && arg.side == .eigen)
            || (filter == .gegner && arg.side == .gegner)
        }
        switch sortBy {
        case .date:
            list.sort { (a, b) in
                let da = parseDate(a.zeitpunkt)?.timeIntervalSince1970 ?? 0
                let db = parseDate(b.zeitpunkt)?.timeIntervalSince1970 ?? 0
                return da > db
            }
        case .strength:
            list.sort { (a, b) in
                let sa = a.kiStrength ?? a.strength ?? 0
                let sb = b.kiStrength ?? b.strength ?? 0
                return sa > sb
            }
        case .created:
            break
        }
        return list
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                toolbar
                if let dups = duplicates { duplicatesPanel(dups) }
                if let kg = kiGenResult { kiGeneratedPanel(kg) }
                if showAdd { addPanel }
                extractionPanel
                argumentList
            }
            .padding()
        }
        .navigationTitle("Argumente")
        .task { await loadAll() }
        .alert("Hinweis", isPresented: Binding(get: { sheetMessage != nil }, set: { if !$0 { sheetMessage = nil } })) {
            Button("OK", role: .cancel) { sheetMessage = nil }
        } message: {
            Text(sheetMessage ?? "")
        }
    }

    // MARK: - Sub-Views
    private var toolbar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ForEach(SideFilter.allCases) { f in
                    Button { filter = f } label: {
                        Text(f.label)
                            .font(.caption)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(filter == f ? Color.accentColor : Color.gray.opacity(0.15),
                                        in: Capsule())
                            .foregroundStyle(filter == f ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
                Divider().frame(height: 16)
                Text("Sortierung:").font(.caption2).foregroundStyle(.secondary)
                ForEach(SortMode.allCases) { s in
                    Button { sortBy = s } label: {
                        Text(s.label)
                            .font(.caption2)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(sortBy == s ? Color.blue : Color.gray.opacity(0.15),
                                        in: Capsule())
                            .foregroundStyle(sortBy == s ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            HStack {
                Button {
                    Task { await rateBatch() }
                } label: {
                    Label(batchRating ? "Bewerte…" : "Alle bewerten", systemImage: "star.fill")
                }
                .disabled(batchRating || args.isEmpty)

                Button {
                    Task { await generateKiArgumente() }
                } label: {
                    Label(kiGenerating ? "KI generiert…" : "KI-Argumente", systemImage: "sparkles")
                }
                .disabled(kiGenerating)

                Button {
                    Task { await detectDuplicates() }
                } label: {
                    Label(detectingDuplicates ? "Prüfe…" : "Duplikate", systemImage: "magnifyingglass")
                }
                .disabled(detectingDuplicates)

                Button(role: .destructive) {
                    Task { await cleanupWithoutEvidence() }
                } label: {
                    Label("Ohne Belege löschen", systemImage: "trash")
                }

                Button {
                    showAdd.toggle()
                } label: {
                    Label("Argument", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.small)
        }
    }

    private func duplicatesPanel(_ groups: [DuplicateGroup]) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Ähnliche Argumente gefunden", systemImage: "magnifyingglass")
                        .font(.callout).bold()
                    Spacer()
                    Button(role: .destructive) {
                        Task { await deleteDuplicates(groups) }
                    } label: { Label("Doppelte löschen", systemImage: "trash") }
                    Button("Schließen") { duplicates = nil }
                }
                ForEach(groups) { group in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(group.grund).font(.caption).bold()
                        ForEach(group.nummern, id: \.self) { idx in
                            if let arg = args[safe: idx - 1] {
                                let keep = idx == group.zuBehalten
                                HStack(alignment: .top, spacing: 8) {
                                    Text("#\(idx)").font(.caption2).monospaced()
                                        .foregroundStyle(keep ? .green : .red)
                                    VStack(alignment: .leading) {
                                        Text(arg.title).font(.caption).bold()
                                        if let d = arg.argDescription {
                                            Text(d).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    if keep { Text("BEHALTEN").font(.caption2).bold().foregroundStyle(.green) }
                                }
                                .padding(6)
                                .background((keep ? Color.green : Color.red).opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .padding(8)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func kiGeneratedPanel(_ kg: KiGenResult) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("KI-generierte Argumente", systemImage: "sparkles")
                        .font(.callout).bold()
                    Spacer()
                    Button {
                        Task { await takeAllKiArgumente() }
                    } label: { Label("Alle übernehmen", systemImage: "checkmark") }
                    Button(role: .destructive) { kiGenResult = nil } label: {
                        Label("Alle löschen", systemImage: "trash")
                    }
                }
                HStack(alignment: .top, spacing: 16) {
                    kiGenColumn(label: "EIGENE ARGUMENTE", items: kg.eigene, side: .eigen)
                    kiGenColumn(label: "GEGNERARGUMENTE", items: kg.gegner, side: .gegner)
                }
            }
        }
    }

    private func kiGenColumn(label: String, items: [ExtractedArgument], side: ArgumentSide) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(label) · \(items.count)")
                .font(.caption2).bold().foregroundStyle(.secondary)
            ForEach(items) { a in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text(a.titel).font(.caption).bold()
                            if let b = a.beschreibung { Text(b).font(.caption2).foregroundStyle(.secondary) }
                            if !a.paragraphen.isEmpty {
                                HStack {
                                    ForEach(a.paragraphen, id: \.self) { p in
                                        Text(p).font(.caption2).monospaced()
                                            .padding(.horizontal, 4).padding(.vertical, 1)
                                            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                                    }
                                }
                            }
                            if side == .eigen && !a.beweise.isEmpty {
                                ForEach(a.beweise) { ev in
                                    Label(ev.titel, systemImage: "doc.text").font(.caption2)
                                }
                            }
                        }
                        Spacer()
                        VStack(spacing: 4) {
                            Text("\(Int(a.staerke ?? 5))/10").font(.caption2).foregroundStyle(.secondary)
                            Button("Übernehmen") {
                                Task { await takeKiArg(a, side: side) }
                            }
                            .font(.caption2)
                        }
                    }
                }
                .padding(6)
                .background(.background, in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var addPanel: some View {
        GroupBox("Neues Argument") {
            VStack(spacing: 8) {
                TextField("Titel *", text: $newArg.title)
                TextField("Beschreibung", text: $newArg.description, axis: .vertical)
                    .lineLimit(2...4)
                HStack {
                    DatePicker("Zeitpunkt",
                               selection: Binding(get: { newArg.zeitpunkt ?? Date() },
                                                  set: { newArg.zeitpunkt = $0 }),
                               displayedComponents: .date)
                        .labelsHidden()
                    TextField("Anmerkungen", text: $newArg.anmerkungen)
                }
                HStack {
                    Picker("Seite", selection: $newArg.side) {
                        Text("Eigen").tag(ArgumentSide.eigen)
                        Text("Gegner").tag(ArgumentSide.gegner)
                    }
                    .pickerStyle(.menu)
                    Picker("Typ", selection: $newArg.type) {
                        ForEach(["Rechtsargument","Tatsachenargument","Widerspruch","Druckmittel"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                    Stepper(value: $newArg.strength, in: 0...10, step: 0.5) {
                        Text("Stärke: \(newArg.strength, specifier: "%.1f")")
                    }
                }
                HStack {
                    Spacer()
                    Button("Abbrechen") { showAdd = false }
                    Button("Hinzufügen") { Task { await addManual() } }
                        .buttonStyle(.borderedProminent)
                        .disabled(newArg.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }

    private var extractionPanel: some View {
        GroupBox {
            DisclosureGroup(isExpanded: $showExtraction) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Modus:").font(.caption).foregroundStyle(.secondary)
                        Picker("Modus", selection: $extractMode) {
                            ForEach(ExtractMode.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    if extractMode == .ki {
                        GroupBox("DSGVO-Hinweis (Art. 13, 28 DSGVO)") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("• Dokumente werden ausschließlich zur Analyse verarbeitet").font(.caption2)
                                Text("• Keine dauerhafte Speicherung der Originaldokumente").font(.caption2)
                                Text("• Keine Weitergabe an Dritte").font(.caption2)
                                Toggle("Ich stimme der Verarbeitung zu", isOn: $dsgvo)
                                    .font(.caption)
                            }
                        }
                    }
                    TextField("Oder Text manuell einfügen…", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        Task { await handleExtract() }
                    } label: {
                        if extracting {
                            Label("Analysiere…", systemImage: "arrow.clockwise")
                        } else {
                            Label("Analysieren", systemImage: "wand.and.stars")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(extracting)
                    if let err = extractError {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    if let ext = extracted {
                        extractionResults(ext)
                    }
                }
            } label: {
                Label("Argument-Extraktion – Dokumente & Texte analysieren",
                      systemImage: "doc.text.magnifyingglass")
                    .font(.callout)
            }
        }
    }

    private func extractionResults(_ ext: ExtractedResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let s = ext.zusammenfassung {
                Text(s).font(.caption).italic().foregroundStyle(.secondary)
                    .padding(.leading, 8)
                    .overlay(Rectangle().frame(width: 2).foregroundStyle(.gray), alignment: .leading)
            }
            HStack {
                Spacer()
                Button { Task { await takeAll() } } label: {
                    Label("Alle übernehmen", systemImage: "checkmark")
                }
                Button(role: .destructive) {
                    extracted = nil; text = ""
                } label: { Label("Alle löschen", systemImage: "trash") }
            }
            HStack(alignment: .top, spacing: 16) {
                extractedColumn(label: "EIGENE ARGUMENTE", items: ext.eigeneArgumente, side: .eigen)
                extractedColumn(label: "GEGENSEITE", items: ext.gegenseiteArgumente, side: .gegner)
            }
        }
    }

    private func extractedColumn(label: String, items: [ExtractedArgument], side: ArgumentSide) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(label) · \(items.count)").font(.caption2).bold().foregroundStyle(.secondary)
            ForEach(items) { a in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(a.titel).font(.caption).bold()
                        Spacer()
                        Text("\(Int(a.staerke ?? 5))/10").font(.caption2).foregroundStyle(.secondary)
                        if let d = a.datum {
                            Text(d).font(.caption2)
                                .padding(.horizontal, 4)
                                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                        }
                        Button("Übernehmen") { Task { await take(a, side: side) } }
                            .font(.caption2)
                    }
                    if let typ = a.typ { Text(typ).font(.caption2).foregroundStyle(.secondary) }
                    if !a.paragraphen.isEmpty {
                        HStack {
                            ForEach(a.paragraphen.prefix(3), id: \.self) { p in
                                Text(p).font(.caption2).monospaced()
                                    .padding(.horizontal, 3).background(Color.blue.opacity(0.1),
                                                                        in: RoundedRectangle(cornerRadius: 3))
                            }
                            if a.paragraphen.count > 3 {
                                Text("+\(a.paragraphen.count - 3)").font(.caption2)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var argumentList: some View {
        VStack(spacing: 8) {
            ForEach(filtered) { arg in
                VStack(alignment: .leading, spacing: 6) {
                    ArgCardView(arg: arg,
                                onDelete: { Task { await del(arg.id) } },
                                onSave: { Task { await loadAll() } },
                                onKiWeight: { Task { await kiWeightFor(arg) } })
                    if let reason = arg.kiReasoning {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("KI-Begründung (Stärke \(Int(arg.kiStrength ?? 0))/10):")
                                .font(.caption).bold()
                            Text(reason).font(.caption2)
                        }
                        .padding(8)
                        .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            if filtered.isEmpty {
                ContentUnavailableView("Noch keine Argumente",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Manuell hinzufügen oder aus Dokument extrahieren."))
            }
        }
    }

    // MARK: - Daten-Operationen
    @MainActor
    private func loadAll(notify: Bool = false) async {
        let pred = NSPredicate(format: "case_id == %@", caseId)
        let aLoad = (try? await cloudKit.fetch(Argument.self, predicate: pred)) ?? []
        let eLoad = (try? await cloudKit.fetch(Evidence.self, predicate: pred)) ?? []
        args = aLoad
        evidence = eLoad
        if notify { onCountChange?() }
    }

    private func addManual() async {
        guard !newArg.title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var a = Argument(caseId: caseId, title: newArg.title)
        a.argDescription = newArg.description.isEmpty ? nil : newArg.description
        a.side = newArg.side
        a.strength = newArg.strength
        a.type = newArg.type
        if let z = newArg.zeitpunkt { a.zeitpunkt = isoDate(z) }
        a.anmerkungen = newArg.anmerkungen.isEmpty ? nil : newArg.anmerkungen
        _ = try? await cloudKit.save(a)
        newArg = NewArgumentDraft()
        showAdd = false
        await loadAll(notify: true)
    }

    private func del(_ id: String) async {
        try? await cloudKit.delete(recordID: id)
        await loadAll(notify: true)
    }

    private func kiWeightFor(_ arg: Argument) async {
        let prompt = """
        Du bist ein erfahrener Rechtsanwalt. Bewerte die Stärke dieses Rechtsarguments im deutschen Zivilprozess.
        Argument: "\(arg.title)"
        Beschreibung: "\(arg.argDescription ?? "")"
        Typ: \(arg.type ?? "Rechtsargument"), Seite: \(arg.side.rawValue)
        Gib eine Stärke (0-10) UND eine kurze juristische Begründung (2-3 Sätze) zurück.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "staerke": ["type": "number", "minimum": 0, "maximum": 10],
                "begruendung": ["type": "string"]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        if case .success(let any) = res, let dict = any as? [String: Any] {
            let s = (dict["staerke"] as? Double) ?? 0
            let b = (dict["begruendung"] as? String) ?? ""
            var updated = arg
            updated.kiStrength = min(10, max(0, s))
            updated.kiReasoning = b
            _ = try? await cloudKit.save(updated)
            await loadAll()
        }
    }

    private func handleExtract() async {
        if extractMode == .ki && !dsgvo { extractError = "Bitte DSGVO-Hinweis akzeptieren"; return }
        if text.trimmingCharacters(in: .whitespaces).isEmpty {
            extractError = "Text erforderlich"; return
        }
        extracting = true; extractError = nil
        defer { extracting = false }
        let prompt = """
        Du bist ein erfahrener Rechtsanwalt. Analysiere diese Eingabe gründlich und extrahiere:
        1. EIGENE ARGUMENTE (welche Klauseln unterstützen unsere Position?)
        2. GEGENSEITE-ARGUMENTE
        3. BEWEISE (Klauseln, Unterschriften, Daten)
        4. Für jedes Argument: zugehörige Beweise.
        5. DATUM: YYYY-MM-DD, falls erkennbar.

        Fall: \(caseData?.fallname ?? "") | \(caseData?.rechtsgebiet ?? "")
        Rechtsfrage: \(caseData?.zentraleRechtsfrage ?? "")
        TEXT: \(text)
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "zusammenfassung": ["type": "string"],
                "beweise": ["type": "array"],
                "eigene_argumente": ["type": "array"],
                "gegenseite_argumente": ["type": "array"],
                "relevante_paragraphen": ["type": "array"]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        guard case .success(let any) = res, let dict = any as? [String: Any] else {
            extractError = "KI-Analyse fehlgeschlagen"; return
        }
        extracted = parseExtraction(dict)
        text = ""
    }

    private func parseExtraction(_ dict: [String: Any]) -> ExtractedResult {
        var r = ExtractedResult()
        r.zusammenfassung = dict["zusammenfassung"] as? String
        r.relevantePara = dict["relevante_paragraphen"] as? [String] ?? []
        r.beweise = (dict["beweise"] as? [[String: Any]] ?? []).map { parseEv($0) }
        r.eigeneArgumente = (dict["eigene_argumente"] as? [[String: Any]] ?? []).map { parseArg($0) }
        r.gegenseiteArgumente = (dict["gegenseite_argumente"] as? [[String: Any]] ?? []).map { parseArg($0) }
        return r
    }

    private func parseEv(_ d: [String: Any]) -> ExtractedEvidence {
        ExtractedEvidence(titel: d["titel"] as? String ?? "",
                          beschreibung: d["beschreibung"] as? String,
                          typ: d["typ"] as? String,
                          gewicht: d["gewicht"] as? Double)
    }
    private func parseArg(_ d: [String: Any]) -> ExtractedArgument {
        ExtractedArgument(
            titel: d["titel"] as? String ?? "",
            beschreibung: d["beschreibung"] as? String,
            typ: d["typ"] as? String,
            staerke: d["staerke"] as? Double,
            datum: d["datum"] as? String,
            paragraphen: d["paragraphen"] as? [String] ?? d["paragraphen"] as? [String] ?? [],
            beweise: (d["beweise"] as? [[String: Any]] ?? []).map { parseEv($0) }
        )
    }

    private func take(_ a: ExtractedArgument, side: ArgumentSide) async {
        var arg = Argument(caseId: caseId, title: a.titel)
        arg.argDescription = a.beschreibung
        arg.side = side
        arg.strength = a.staerke ?? 5
        arg.type = a.typ ?? "Rechtsargument"
        arg.paragraphs = a.paragraphen
        arg.zeitpunkt = a.datum
        _ = try? await cloudKit.save(arg)
        extracted.map { ext in
            var copy = ext
            if side == .eigen { copy.eigeneArgumente.removeAll { $0.titel == a.titel } }
            else { copy.gegenseiteArgumente.removeAll { $0.titel == a.titel } }
            extracted = copy
        }
        await loadAll(notify: true)
    }

    private func takeAll() async {
        guard let ext = extracted else { return }
        // Erst Beweise speichern und Map Titel → ID bauen
        var evMap: [String: String] = [:]
        for ev in ext.beweise where !ev.titel.isEmpty {
            var e = Evidence(caseId: caseId, title: ev.titel)
            e.evidenceDescription = ev.beschreibung
            e.type = ev.typ ?? "Dokument"
            e.source = "Extraktion"
            e.weight = ev.gewicht ?? 5
            if let saved = try? await cloudKit.save(e) { evMap[ev.titel] = saved.id }
        }
        let all: [(ExtractedArgument, ArgumentSide)] =
            ext.eigeneArgumente.map { ($0, .eigen) } +
            ext.gegenseiteArgumente.map { ($0, .gegner) }
        for (a, side) in all {
            var arg = Argument(caseId: caseId, title: a.titel)
            arg.argDescription = a.beschreibung
            arg.side = side
            arg.strength = a.staerke ?? 5
            arg.type = a.typ ?? "Rechtsargument"
            arg.paragraphs = a.paragraphen
            arg.zeitpunkt = a.datum
            _ = try? await cloudKit.save(arg)
        }
        extracted = nil
        await loadAll(notify: true)
        sheetMessage = "\(all.count) Argument(e) übernommen, \(evMap.count) Beweis(e) erstellt"
    }

    private func rateBatch() async {
        guard !args.isEmpty else { return }
        batchRating = true; defer { batchRating = false }
        let lines = args.enumerated().map { (i, a) in
            "\(i+1). [\(a.side.rawValue.uppercased())] \(a.title)\nBeschreibung: \(a.argDescription ?? "-")"
        }.joined(separator: "\n\n")
        let prompt = """
        Du bist ein erfahrener Rechtsanwalt. Bewerte die Stärke dieser Argumente.
        Fall: \(caseData?.fallname ?? "")
        Rechtsgebiet: \(caseData?.rechtsgebiet ?? "")
        Zentrale Frage: \(caseData?.zentraleRechtsfrage ?? "")
        \(lines)
        Gib pro Argument: index, staerke (0-10), begruendung.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "bewertungen": ["type": "array"]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        if case .success(let any) = res,
           let dict = any as? [String: Any],
           let bews = dict["bewertungen"] as? [[String: Any]] {
            for b in bews {
                guard let idx = b["index"] as? Int, args.indices.contains(idx) else { continue }
                var a = args[idx]
                a.kiStrength = min(10, max(0, (b["staerke"] as? Double) ?? 0))
                a.kiReasoning = b["begruendung"] as? String
                _ = try? await cloudKit.save(a)
            }
            await loadAll(notify: true)
        }
    }

    private func generateKiArgumente() async {
        kiGenerating = true; defer { kiGenerating = false }
        kiGenResult = nil
        let prompt = """
        Du bist ein erfahrener Rechtsanwalt. Generiere auf Basis des Fallkontexts die stärksten
        juristischen Argumente für unsere Seite UND die zu erwartenden Gegenargumente.

        Fall: \(caseData?.fallname ?? "")
        Rechtsgebiet: \(caseData?.rechtsgebiet ?? "")
        Zentrale Rechtsfrage: \(caseData?.zentraleRechtsfrage ?? "")
        Prozessziel: \(caseData?.prozessziel ?? "")
        Instanz: \(caseData?.instanz.rawValue ?? "")
        Gericht: \(caseData?.gericht ?? "")

        Maximal 19 Argumente. Für jedes: titel, beschreibung, staerke, paragraphen, beweise (nur eigene Argumente).
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "eigene_argumente": ["type": "array"],
                "gegner_argumente": ["type": "array"]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        if case .success(let any) = res, let dict = any as? [String: Any] {
            var k = KiGenResult()
            k.eigene = (dict["eigene_argumente"] as? [[String: Any]] ?? []).map { parseArg($0) }
            k.gegner = (dict["gegner_argumente"] as? [[String: Any]] ?? []).map { parseArg($0) }
            kiGenResult = k
        }
    }

    private func takeKiArg(_ a: ExtractedArgument, side: ArgumentSide) async {
        // Wenn Beweise vorhanden -> als Beweise speichern, kein Argument anlegen
        if side == .eigen && !a.beweise.isEmpty {
            for ev in a.beweise {
                var e = Evidence(caseId: caseId, title: ev.titel)
                e.evidenceDescription = ev.beschreibung
                e.type = ev.typ ?? "Dokument"
                e.weight = ev.gewicht ?? 5
                _ = try? await cloudKit.save(e)
            }
            // Eventuell bestehendes gleichnamiges Argument löschen
            if let existing = args.first(where: { $0.title == a.titel }) {
                try? await cloudKit.delete(recordID: existing.id)
            }
        } else {
            var arg = Argument(caseId: caseId, title: a.titel)
            arg.argDescription = a.beschreibung
            arg.side = side
            arg.strength = a.staerke ?? 5
            arg.type = "Rechtsargument"
            arg.paragraphs = a.paragraphen
            _ = try? await cloudKit.save(arg)
        }
        kiGenResult.map { kg in
            var copy = kg
            if side == .eigen { copy.eigene.removeAll { $0.titel == a.titel } }
            else { copy.gegner.removeAll { $0.titel == a.titel } }
            kiGenResult = copy
        }
        await loadAll(notify: true)
    }

    private func takeAllKiArgumente() async {
        guard let kg = kiGenResult else { return }
        let all = kg.eigene.map { ($0, ArgumentSide.eigen) } + kg.gegner.map { ($0, ArgumentSide.gegner) }
        for (a, side) in all { await takeKiArg(a, side: side) }
        kiGenResult = nil
    }

    private func detectDuplicates() async {
        guard args.count >= 2 else {
            sheetMessage = "Zu wenige Argumente zum Vergleich."; return
        }
        detectingDuplicates = true; defer { detectingDuplicates = false }
        let argsList = args.enumerated().map { (i, a) in
            "\(i+1). \(a.title)\(a.argDescription.map { " — " + String($0.prefix(60)) } ?? "")"
        }.joined(separator: "\n")
        let prompt = """
        Finde ähnliche oder doppelte Argumente. Paraphrasierungen zählen.
        ARGUMENTE:
        \(argsList)
        Gib Gruppen ähnlicher Argumente zurück mit nummern[], grund, zu_behalten.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": ["duplikat_gruppen": ["type": "array"]]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        if case .success(let any) = res,
           let dict = any as? [String: Any],
           let groups = dict["duplikat_gruppen"] as? [[String: Any]], !groups.isEmpty {
            duplicates = groups.map {
                DuplicateGroup(
                    nummern: $0["nummern"] as? [Int] ?? [],
                    grund: $0["grund"] as? String ?? "",
                    zuBehalten: $0["zu_behalten"] as? Int ?? 0
                )
            }
        } else {
            sheetMessage = "Keine ähnlichen Argumente gefunden."
            duplicates = nil
        }
    }

    private func deleteDuplicates(_ groups: [DuplicateGroup]) async {
        var deleted = 0
        for group in groups {
            for idx in group.nummern where idx != group.zuBehalten {
                if let arg = args[safe: idx - 1] {
                    try? await cloudKit.delete(recordID: arg.id); deleted += 1
                }
            }
        }
        await loadAll(notify: true)
        duplicates = nil
        sheetMessage = "\(deleted) doppelte Argumente gelöscht."
    }

    private func cleanupWithoutEvidence() async {
        let withoutEv = args.filter { $0.evidenceIds.isEmpty }
        if withoutEv.isEmpty {
            sheetMessage = "Alle Argumente haben Belege."; return
        }
        if evidence.isEmpty {
            for a in withoutEv { try? await cloudKit.delete(recordID: a.id) }
            await loadAll(notify: true)
            sheetMessage = "\(withoutEv.count) Argumente gelöscht."
            return
        }
        let allEv = evidence.map { e in
            "[\(e.type ?? "Beweis")] \(e.title)\nBeschreibung: \(e.evidenceDescription ?? "")"
        }.joined(separator: "\n---\n")
        let prompt = """
        Du bist Rechtsanwalt. Prüfe sorgfältig den inhaltlichen Bezug.
        BEWEISE:
        \(allEv)
        ARGUMENTE OHNE EVIDENCE-IDS:
        \(withoutEv.map { "\($0.title)\nBeschreibung: \($0.argDescription ?? "-")" }.joined(separator: "\n==="))
        Gib zu_loeschen[] mit titel und grund zurück.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": ["zu_loeschen": ["type": "array"]]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        if case .success(let any) = res,
           let dict = any as? [String: Any],
           let toDel = dict["zu_loeschen"] as? [[String: Any]], !toDel.isEmpty {
            var n = 0
            for item in toDel {
                if let t = item["titel"] as? String,
                   let arg = withoutEv.first(where: { $0.title == t }) {
                    try? await cloudKit.delete(recordID: arg.id); n += 1
                }
            }
            await loadAll(notify: true)
            sheetMessage = "\(n) Argumente gelöscht (KI-basiert)."
        } else {
            sheetMessage = "KI: Alle Argumente haben Bezug. Keine Löschung."
        }
    }

    // MARK: - Helpers
    private func parseDate(_ s: String?) -> Date? {
        guard let s else { return nil }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }
    private func isoDate(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }
}

// MARK: - Argument-Kachel
private struct ArgCardView: View {
    let arg: Argument
    var onDelete: () -> Void
    var onSave: () -> Void
    var onKiWeight: () -> Void
    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider
    @State private var editing = false
    @State private var form: TabArgumenteView.NewArgumentDraft = .init()
    @State private var newPara = ""
    @State private var paragraphs: [String] = []
    @State private var analyzing = false
    @State private var kiWeighting = false
    @State private var analysisExpl: String?
    @State private var analysisVorschlaege: [String] = []

    private var discrepancy: Double {
        guard let k = arg.kiStrength else { return 0 }
        return abs((arg.strength ?? 5) - k)
    }
    private var hasDiscrepancy: Bool { discrepancy >= 2 }

    var body: some View {
        GroupBox {
            if editing { editView } else { displayView }
        }
        .onAppear {
            form.title = arg.title
            form.description = arg.argDescription ?? ""
            form.side = arg.side
            form.type = arg.type ?? "Rechtsargument"
            form.strength = arg.strength ?? 5
            form.anmerkungen = arg.anmerkungen ?? ""
            paragraphs = arg.paragraphs
        }
    }

    private var displayView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(arg.side == .eigen ? "Eigen" : "Gegner")
                    .font(.caption2).bold()
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background((arg.side == .eigen ? Color.blue : Color.red).opacity(0.15),
                                in: Capsule())
                if let t = arg.type {
                    Text(t).font(.caption2).foregroundStyle(.secondary)
                }
                if hasDiscrepancy {
                    Label("Δ \(discrepancy, specifier: "%.1f")", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2).foregroundStyle(.orange)
                }
                Spacer()
                Button { editing = true } label: { Image(systemName: "pencil") }.buttonStyle(.plain)
                Button { onDelete() } label: { Image(systemName: "trash") }.buttonStyle(.plain)
            }
            Text(arg.title).font(.callout).bold()
            if let d = arg.argDescription {
                Text(d).font(.caption).foregroundStyle(.secondary).lineLimit(3)
            }
            HStack {
                if let z = arg.zeitpunkt {
                    Label(z, systemImage: "calendar").font(.caption2).foregroundStyle(.secondary)
                }
                if let a = arg.anmerkungen {
                    Label(a, systemImage: "note.text").font(.caption2).foregroundStyle(.orange)
                }
            }
            VStack(spacing: 4) {
                scoreRow(label: "Manuell", value: arg.strength ?? 5, color: .blue)
                scoreRow(label: "KI-Stärke", value: arg.kiStrength ?? 0, color: .purple,
                         shown: arg.kiStrength != nil)
            }
            if !arg.paragraphs.isEmpty {
                HStack {
                    ForEach(arg.paragraphs, id: \.self) { p in
                        Text(p).font(.caption2).monospaced()
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                    }
                }
            }
            HStack {
                Button {
                    Task { await runKiWeight() }
                } label: {
                    Label(kiWeighting ? "Bewerte…" : "KI bewerten", systemImage: "sparkles")
                        .font(.caption2)
                }
                .disabled(kiWeighting)
                if hasDiscrepancy {
                    Button { Task { await analyzeDiscrepancy() } } label: {
                        Label(analyzing ? "Analysiere…" : "Diskrepanz analysieren",
                              systemImage: "exclamationmark.triangle")
                            .font(.caption2)
                    }
                    .disabled(analyzing)
                }
            }
            if let expl = analysisExpl {
                VStack(alignment: .leading, spacing: 4) {
                    Text(expl).font(.caption)
                    ForEach(Array(analysisVorschlaege.enumerated()), id: \.offset) { (i, v) in
                        HStack(alignment: .top) {
                            Text("\(i+1).").bold()
                            Text(v).font(.caption)
                        }
                    }
                }
                .padding(8)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private var editView: some View {
        VStack(spacing: 6) {
            TextField("Titel *", text: $form.title)
            TextField("Beschreibung", text: $form.description, axis: .vertical).lineLimit(2...4)
            HStack {
                Picker("Seite", selection: $form.side) {
                    Text("Eigen").tag(ArgumentSide.eigen)
                    Text("Gegner").tag(ArgumentSide.gegner)
                }.pickerStyle(.menu)
                Picker("Typ", selection: $form.type) {
                    ForEach(["Rechtsargument","Tatsachenargument","Widerspruch","Druckmittel"], id: \.self) {
                        Text($0).tag($0)
                    }
                }.pickerStyle(.menu)
                Stepper(value: $form.strength, in: 0...10, step: 0.5) {
                    Text("Stärke \(form.strength, specifier: "%.1f")")
                }
            }
            // Paragraphen
            HStack {
                ForEach(Array(paragraphs.enumerated()), id: \.offset) { (i, p) in
                    HStack(spacing: 2) {
                        Text(p).font(.caption2).monospaced()
                        Button {
                            paragraphs.remove(at: i)
                        } label: { Image(systemName: "xmark.circle.fill").font(.caption2) }
                            .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)
                    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                }
            }
            HStack {
                TextField("z.B. § 280 BGB", text: $newPara)
                Button("+") {
                    let trimmed = newPara.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { paragraphs.append(trimmed); newPara = "" }
                }
            }
            HStack {
                Spacer()
                Button("Abbrechen") { editing = false }
                Button("Speichern") { Task { await save() } }
                    .buttonStyle(.borderedProminent)
            }
        }
        .textFieldStyle(.roundedBorder)
    }

    private func scoreRow(label: String, value: Double, color: Color, shown: Bool = true) -> some View {
        HStack {
            Text(label).font(.caption2).foregroundStyle(.secondary).frame(width: 80, alignment: .leading)
            ProgressView(value: shown ? value / 10 : 0).tint(color)
            Text(shown ? "\(Int(value))" : "–").font(.caption2).bold().foregroundStyle(color)
                .frame(width: 24, alignment: .trailing)
        }
    }

    private func save() async {
        var a = arg
        a.title = form.title
        a.argDescription = form.description.isEmpty ? nil : form.description
        a.side = form.side
        a.type = form.type
        a.strength = form.strength
        a.anmerkungen = form.anmerkungen.isEmpty ? nil : form.anmerkungen
        a.paragraphs = paragraphs
        _ = try? await cloudKit.save(a)
        editing = false
        onSave()
    }

    private func runKiWeight() async {
        kiWeighting = true; defer { kiWeighting = false }
        onKiWeight()
    }

    private func analyzeDiscrepancy() async {
        analyzing = true; defer { analyzing = false }
        let prompt = """
        Analysiere die Diskrepanz zwischen manueller und KI-Bewertung dieses Rechtsarguments:
        Argument: "\(arg.title)"
        Beschreibung: "\(arg.argDescription ?? "")"
        Manuelle Stärke: \(arg.strength ?? 5)/10
        KI-Stärke: \(arg.kiStrength ?? 0)/10
        Diskrepanz: \(discrepancy)
        Liefere erklaerung und 3 vorschlaege.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "erklaerung": ["type": "string"],
                "vorschlaege": ["type": "array"]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema)
        if case .success(let any) = res, let dict = any as? [String: Any] {
            analysisExpl = dict["erklaerung"] as? String
            analysisVorschlaege = dict["vorschlaege"] as? [String] ?? []
        }
    }
}

// MARK: - Helfer
fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
