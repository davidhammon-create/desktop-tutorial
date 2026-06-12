//
//  TabZeitstrahlView.swift
//  Konversion von src/components/lexara/TabZeitstrahl.jsx (779 Zeilen) nach SwiftUI.
//  Fall-Zeitstrahl mit Foto-/Video-Annotation, Vertragschecklisten,
//  Verknüpfung von Ereignissen und KI-Generierung aus Dokumenten.
//

import SwiftUI

// MARK: - Konfiguration

/// Kategorie eines Zeitstrahl-Ereignisses (1:1 zu CATEGORY_CONFIG aus React)
fileprivate struct ZeitstrahlKategorie: Identifiable, Hashable {
    let id: String
    let label: String
    let color: Color
}
fileprivate let ZEITSTRAHL_KATEGORIEN: [String: ZeitstrahlKategorie] = [
    "vertrag":       .init(id: "vertrag",       label: "Vertrag",       color: Color(red: 52/255,  green: 199/255, blue: 89/255)),
    "zahlung":       .init(id: "zahlung",       label: "Zahlung",       color: Color(red: 0,       green: 122/255, blue: 1)),
    "klage":         .init(id: "klage",         label: "Klage",         color: Color(red: 1,       green: 59/255,  blue: 48/255)),
    "urteil":        .init(id: "urteil",        label: "Urteil",        color: Color(red: 88/255,  green: 86/255,  blue: 214/255)),
    "frist":         .init(id: "frist",         label: "Frist",         color: Color(red: 1,       green: 149/255, blue: 0)),
    "verhandlung":   .init(id: "verhandlung",   label: "Verhandlung",   color: Color(red: 175/255, green: 82/255,  blue: 222/255)),
    "gutachten":     .init(id: "gutachten",     label: "Gutachten",     color: Color(red: 0,       green: 188/255, blue: 212/255)),
    "korrespondenz": .init(id: "korrespondenz", label: "Korrespondenz", color: Color(red: 139/255, green: 195/255, blue: 74/255)),
    "foto":          .init(id: "foto",          label: "Foto",          color: Color(red: 1,       green: 107/255, blue: 53/255)),
    "video":         .init(id: "video",         label: "Video",         color: Color(red: 192/255, green: 57/255,  blue: 43/255)),
    "sonstiges":     .init(id: "sonstiges",     label: "Sonstiges",     color: .gray),
]

fileprivate let ZEITSTRAHL_WICHTIGKEIT: [String: (label: String, color: Color)] = [
    "kritisch": ("Kritisch", Color(red: 1, green: 59/255, blue: 48/255)),
    "hoch":     ("Hoch",     Color(red: 1, green: 149/255, blue: 0)),
    "mittel":   ("Mittel",   Color(red: 0, green: 122/255, blue: 1)),
    "niedrig":  ("Niedrig",  .gray),
]

// MARK: - Hilfsstrukturen für das Documents-JSON

/// Eine Datei-Annotation (Foto/Video/PDF) innerhalb eines Ereignisses.
fileprivate struct ZeitstrahlDoc: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    var title: String = ""
    var fileUrl: String?
    var fileType: String?
    var annotation: String?
    var kiAnalyse: String?
    var kiAnalysiert: Bool = false
    var kiSequenz: [VideoSequenz] = []
    var relationType: String?  // "beweist" | "widerlegt" | "überschneidet"
}
fileprivate struct VideoSequenz: Hashable, Codable {
    var zeitstempel: String?
    var beschreibung: String?
}
fileprivate struct VertragsPunkt: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    var titel: String = ""
    var erledigt: Bool = false
    var faellig: String?
    var faelligUeberschritten: Bool = false
    var notiz: String?
}
/// Container, der zusätzlich zu den Pflichtfeldern in `documentsJSON` serialisiert wird.
fileprivate struct ZeitstrahlExtra: Codable {
    var docs: [ZeitstrahlDoc] = []
    var checklist: [VertragsPunkt] = []
    var relatedEventId: String?
    var relationType: String?
}

fileprivate enum MediaArt: String { case image, video, pdf, file }

fileprivate func mediaArt(url: String?, mime: String?) -> MediaArt {
    let lowMime = (mime ?? "").lowercased()
    if lowMime.hasPrefix("image/") { return .image }
    if lowMime.hasPrefix("video/") { return .video }
    if lowMime == "application/pdf" { return .pdf }
    let ext = (url ?? "").split(separator: ".").last.map(String.init)?
        .lowercased().split(separator: "?").first.map(String.init) ?? ""
    let img = ["jpg","jpeg","png","gif","webp","heic","bmp","tiff","svg"]
    let vid = ["mp4","mov","avi","mkv","webm","wmv","flv","m4v"]
    if img.contains(ext) { return .image }
    if vid.contains(ext) { return .video }
    if ext == "pdf" { return .pdf }
    return .file
}

// MARK: - Hauptansicht

struct TabZeitstrahlView: View {
    let caseId: String
    let caseData: Case?
    var kiMode: Bool = true

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var events: [TimelineEvent] = []
    @State private var loading = true
    @State private var generating = false
    @State private var showForm = false
    @State private var editEvent: TimelineEvent?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                legend
                if showForm {
                    EventFormView(
                        existing: editEvent,
                        caseId: caseId,
                        allEvents: events,
                        onSaved: {
                            showForm = false; editEvent = nil
                            Task { await load() }
                        },
                        onCancel: { showForm = false; editEvent = nil }
                    )
                }

                if loading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .padding(.vertical, 30)
                } else if events.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(events) { ev in
                            EventCardView(
                                event: ev,
                                allEvents: events,
                                onEdit: { editEvent = ev; showForm = true },
                                onDelete: { Task { await delete(ev.id) } },
                                onUpdateExtra: { newExtra in
                                    Task { await persistExtra(for: ev, extra: newExtra) }
                                }
                            )
                        }
                    }
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Zeitstrahl")
        .task { await load() }
    }

    // MARK: Sub-Views

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Fallzeitstrahl").font(.headline)
                Text("Dokumente, Fotos, Videos – chronologisch mit KI-Analyse & Beweisverknüpfung")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if kiMode {
                Button {
                    Task { await generateFromDocuments() }
                } label: {
                    Label(generating ? "Generiere…" : "Aus Dokumenten generieren",
                          systemImage: "sparkles")
                }
                .disabled(generating)
            }
            Button {
                editEvent = nil
                showForm = true
            } label: {
                Label("Ereignis", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var legend: some View {
        HStack(spacing: 12) {
            Label("bestätigt", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            Label("widerlegt", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
            Label("überschneidet", systemImage: "link").foregroundStyle(.orange)
            Label("Foto", systemImage: "photo").foregroundStyle(.orange)
            Label("Video (KI-Sequenz)", systemImage: "video").foregroundStyle(.red)
            Spacer()
        }
        .font(.caption2)
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Noch keine Ereignisse erfasst",
            systemImage: "calendar",
            description: Text("Fügen Sie Ereignisse manuell hinzu oder lassen Sie sie aus Dokumenten generieren.")
        )
    }

    // MARK: - Datenoperationen

    private func load() async {
        loading = true
        let pred = NSPredicate(format: "case_id == %@", caseId)
        let list = (try? await cloudKit.fetch(TimelineEvent.self, predicate: pred)) ?? []
        events = list.sorted { $0.date < $1.date }
        loading = false
    }

    private func delete(_ id: String) async {
        try? await cloudKit.delete(recordID: id)
        await load()
    }

    /// Persistiert Foto-/Video-Annotationen sowie Checklisten in `documentsJSON`.
    private func persistExtra(for event: TimelineEvent, extra: ZeitstrahlExtra) async {
        var copy = event
        if let data = try? JSONEncoder().encode(extra),
           let str = String(data: data, encoding: .utf8) {
            copy.documentsJSON = str
        }
        _ = try? await cloudKit.save(copy)
        await load()
    }

    // MARK: - KI: Erzeuge Ereignisse aus Dokumenten
    private func generateFromDocuments() async {
        generating = true; defer { generating = false }
        let pred = NSPredicate(format: "case_id == %@", caseId)
        let docs = (try? await cloudKit.fetch(LegalDocument.self, predicate: pred)) ?? []
        guard !docs.isEmpty else { return }

        let docList = docs.map {
            "- \($0.title): \($0.aiSummary ?? $0.docDescription ?? "keine Zusammenfassung")"
        }.joined(separator: "\n")

        let prompt = """
        Analysiere die folgenden Falldokumente und extrahiere alle relevanten Ereignisse für einen Zeitstrahl.

        Fall: \(caseData?.fallname ?? "")
        Rechtsgebiet: \(caseData?.rechtsgebiet ?? "")

        Dokumente:
        \(docList)

        Erkenne auch Vertragsvereinbarungen mit Fristen und ob sie eingehalten wurden (vertrag_checkliste).
        Markiere Widersprüche zwischen Dokumenten mit relation_type "widerlegt".
        """

        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "ereignisse": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "date":             ["type": "string"],
                            "title":            ["type": "string"],
                            "description":     ["type": "string"],
                            "category":         ["type": "string"],
                            "importance":       ["type": "string"],
                            "persons_involved": ["type": "array", "items": ["type": "string"]],
                            "vertrag_checkliste": [
                                "type": "array",
                                "items": [
                                    "type": "object",
                                    "properties": [
                                        "titel":   ["type": "string"],
                                        "faellig": ["type": "string"],
                                        "erledigt": ["type": "boolean"],
                                        "faelligUeberschritten": ["type": "boolean"],
                                        "notiz":   ["type": "string"]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]

        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        guard case .success(let any) = res,
              let dict = any as? [String: Any],
              let liste = dict["ereignisse"] as? [[String: Any]] else { return }

        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        for ev in liste {
            let date = (ev["date"] as? String).flatMap { f.date(from: $0) } ?? Date()
            var event = TimelineEvent(caseId: caseId, date: date,
                                      title: ev["title"] as? String ?? "Unbenannt")
            event.eventDescription = ev["description"] as? String
            event.category = TimelineCategory(rawValue: ev["category"] as? String ?? "sonstiges") ?? .sonstiges
            event.importance = TimelineImportance(rawValue: ev["importance"] as? String ?? "mittel") ?? .mittel
            event.personsInvolved = ev["persons_involved"] as? [String] ?? []
            event.kiGenerated = true

            // Vertrags-Checkliste in `documentsJSON` ablegen.
            var extra = ZeitstrahlExtra()
            if let cl = ev["vertrag_checkliste"] as? [[String: Any]] {
                extra.checklist = cl.map {
                    VertragsPunkt(
                        titel: $0["titel"] as? String ?? "",
                        erledigt: $0["erledigt"] as? Bool ?? false,
                        faellig: $0["faellig"] as? String,
                        faelligUeberschritten: $0["faelligUeberschritten"] as? Bool ?? false,
                        notiz: $0["notiz"] as? String
                    )
                }
            }
            if let data = try? JSONEncoder().encode(extra),
               let str = String(data: data, encoding: .utf8) {
                event.documentsJSON = str
            }
            _ = try? await cloudKit.save(event)
        }
        await load()
    }
}

// MARK: - Event-Karte
fileprivate struct EventCardView: View {
    let event: TimelineEvent
    let allEvents: [TimelineEvent]
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onUpdateExtra: (ZeitstrahlExtra) -> Void

    @State private var expanded = false

    private var extra: ZeitstrahlExtra {
        guard let s = event.documentsJSON,
              let d = s.data(using: .utf8),
              let p = try? JSONDecoder().decode(ZeitstrahlExtra.self, from: d) else {
            return ZeitstrahlExtra()
        }
        return p
    }

    private var kategorie: ZeitstrahlKategorie {
        ZEITSTRAHL_KATEGORIEN[event.category.rawValue] ?? ZEITSTRAHL_KATEGORIEN["sonstiges"]!
    }
    private var wichtigkeit: (label: String, color: Color) {
        ZEITSTRAHL_WICHTIGKEIT[event.importance.rawValue] ?? ZEITSTRAHL_WICHTIGKEIT["mittel"]!
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(kategorie.color).frame(width: 10, height: 10).padding(.top, 6)
            VStack(alignment: .leading, spacing: 6) {
                header
                if !expanded, let desc = event.eventDescription {
                    Text(desc).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                if expanded { details }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(kategorie.color.opacity(0.3)))
            .onTapGesture { expanded.toggle() }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.date, format: .dateTime.day().month().year())
                        .font(.caption2).monospaced().foregroundStyle(.secondary)
                    Text(kategorie.label)
                        .font(.caption2).bold()
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(kategorie.color.opacity(0.18), in: Capsule())
                        .foregroundStyle(kategorie.color)
                    Text(wichtigkeit.label)
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(wichtigkeit.color.opacity(0.18), in: Capsule())
                        .foregroundStyle(wichtigkeit.color)
                    if event.kiGenerated {
                        Text("KI").font(.caption2).bold()
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Color.purple.opacity(0.15), in: Capsule())
                            .foregroundStyle(.purple)
                    }
                }
                Text(event.title).font(.callout).bold()
            }
            Spacer()
            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                .foregroundStyle(.secondary)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let desc = event.eventDescription {
                VStack(alignment: .leading) {
                    Text("Beschreibung").font(.caption2).bold().foregroundStyle(.secondary)
                    Text(desc).font(.caption)
                }
            }
            if !event.personsInvolved.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Beteiligte").font(.caption2).bold().foregroundStyle(.secondary)
                    HStack {
                        ForEach(event.personsInvolved, id: \.self) { p in
                            Text(p).font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.gray.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }
            if !extra.checklist.isEmpty {
                ContractChecklistView(items: extra.checklist) { newItems in
                    var e = extra; e.checklist = newItems
                    onUpdateExtra(e)
                }
            }
            if !extra.docs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dateien & Beweise").font(.caption2).bold().foregroundStyle(.secondary)
                    ForEach(Array(extra.docs.enumerated()), id: \.element.id) { idx, doc in
                        FileAnnotationView(doc: doc) { newDoc in
                            var copy = extra; copy.docs[idx] = newDoc
                            onUpdateExtra(copy)
                        }
                    }
                }
            }
            HStack {
                Button { onEdit() } label: { Label("Bearbeiten", systemImage: "pencil") }
                Button(role: .destructive) { onDelete() } label: { Label("Löschen", systemImage: "trash") }
            }
            .font(.caption)
        }
    }
}

// MARK: - Vertragschecklist
fileprivate struct ContractChecklistView: View {
    let items: [VertragsPunkt]
    var onChange: ([VertragsPunkt]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Vertragspunkte / Erfüllung").font(.caption2).bold().foregroundStyle(.secondary)
            ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                HStack(alignment: .top) {
                    Button {
                        var copy = items
                        copy[idx].erledigt.toggle()
                        onChange(copy)
                    } label: {
                        Image(systemName: item.erledigt ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.erledigt ? .green : .gray)
                    }
                    .buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.titel)
                            .font(.caption)
                            .strikethrough(item.erledigt)
                            .foregroundStyle(item.faelligUeberschritten && !item.erledigt ? .red : .primary)
                        if let f = item.faellig, !f.isEmpty {
                            Label("Fällig: \(f)", systemImage: "clock")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        if item.faelligUeberschritten && !item.erledigt {
                            Text("⚠ Nicht eingehalten!").font(.caption2).bold().foregroundStyle(.red)
                        }
                        if let n = item.notiz, !n.isEmpty {
                            Text(n).font(.caption2).italic().foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Datei-Annotation
fileprivate struct FileAnnotationView: View {
    var doc: ZeitstrahlDoc
    var onUpdate: (ZeitstrahlDoc) -> Void

    @State private var editing = false
    @State private var annotation = ""

    private var symbol: String {
        switch mediaArt(url: doc.fileUrl, mime: doc.fileType) {
        case .image: return "photo"
        case .video: return "video"
        case .pdf:   return "doc.richtext"
        case .file:  return "doc"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: symbol).foregroundStyle(.secondary)
                if let url = doc.fileUrl, let u = URL(string: url) {
                    Link(doc.title, destination: u).font(.caption)
                } else {
                    Text(doc.title).font(.caption)
                }
                if doc.kiAnalysiert {
                    Text("KI ✓").font(.caption2).bold()
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(Color.purple.opacity(0.15), in: Capsule())
                        .foregroundStyle(.purple)
                }
                if let r = doc.relationType {
                    relationBadge(r)
                }
                Spacer()
            }
            if let ka = doc.kiAnalyse {
                Text(ka).font(.caption2)
                    .padding(6)
                    .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            }
            if !doc.kiSequenz.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Video-Ablauf (KI)").font(.caption2).bold().foregroundStyle(.secondary)
                    ForEach(Array(doc.kiSequenz.enumerated()), id: \.offset) { _, seq in
                        HStack(alignment: .top) {
                            Text(seq.zeitstempel ?? "–").font(.caption2).monospaced()
                                .foregroundStyle(.red)
                            Text(seq.beschreibung ?? "").font(.caption2)
                        }
                    }
                }
            }
            if editing {
                TextField("Was beweist diese Datei?", text: $annotation, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Speichern") {
                        var d = doc; d.annotation = annotation
                        onUpdate(d); editing = false
                    }.buttonStyle(.borderedProminent).controlSize(.small)
                    Button("Abbrechen") { editing = false }.controlSize(.small)
                }
            } else {
                HStack {
                    if let a = doc.annotation, !a.isEmpty {
                        Text("💬 \(a)").font(.caption2).italic().foregroundStyle(.secondary)
                    } else {
                        Text("Keine Annotation").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        annotation = doc.annotation ?? ""
                        editing = true
                    } label: { Image(systemName: "pencil").font(.caption2) }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(6)
        .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }

    private func relationBadge(_ type: String) -> some View {
        let (label, color, sym): (String, Color, String) = {
            switch type {
            case "beweist":      return ("bestätigt", .green, "checkmark.circle")
            case "widerlegt":    return ("widerlegt", .red,   "exclamationmark.triangle")
            case "überschneidet":return ("überschneidet", .orange, "link")
            default:             return (type, .gray, "questionmark")
            }
        }()
        return Label(label, systemImage: sym)
            .font(.caption2)
            .padding(.horizontal, 5).padding(.vertical, 1)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

// MARK: - Ereignis-Formular
fileprivate struct EventFormView: View {
    let existing: TimelineEvent?
    let caseId: String
    let allEvents: [TimelineEvent]
    var onSaved: () -> Void
    var onCancel: () -> Void

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var date = Date()
    @State private var title = ""
    @State private var description = ""
    @State private var category: TimelineCategory = .sonstiges
    @State private var importance: TimelineImportance = .mittel
    @State private var persons: [String] = []
    @State private var personInput = ""
    @State private var checklist: [VertragsPunkt] = []
    @State private var newCheckItem = ""
    @State private var docs: [ZeitstrahlDoc] = []
    @State private var newDocTitle = ""
    @State private var newDocUrl = ""
    @State private var relatedEventId: String?
    @State private var relationType: String?

    var body: some View {
        GroupBox(existing == nil ? "Neues Ereignis" : "Ereignis bearbeiten") {
            Form {
                Section {
                    DatePicker("Datum", selection: $date, displayedComponents: .date)
                    TextField("Titel *", text: $title)
                    TextField("Beschreibung", text: $description, axis: .vertical).lineLimit(2...5)
                    Picker("Kategorie", selection: $category) {
                        ForEach(TimelineCategory.allCases, id: \.self) { c in
                            Text((ZEITSTRAHL_KATEGORIEN[c.rawValue]?.label) ?? c.rawValue).tag(c)
                        }
                    }
                    Picker("Wichtigkeit", selection: $importance) {
                        ForEach(TimelineImportance.allCases, id: \.self) { i in
                            Text((ZEITSTRAHL_WICHTIGKEIT[i.rawValue]?.label) ?? i.rawValue).tag(i)
                        }
                    }
                }
                Section("Beteiligte Personen") {
                    HStack {
                        TextField("Name hinzufügen", text: $personInput)
                        Button("+") {
                            let t = personInput.trimmingCharacters(in: .whitespaces)
                            if !t.isEmpty { persons.append(t); personInput = "" }
                        }
                    }
                    if !persons.isEmpty {
                        WrappingHStack(items: persons) { p, idx in
                            HStack(spacing: 4) {
                                Text(p).font(.caption)
                                Button { persons.remove(at: idx) } label: { Image(systemName: "xmark.circle.fill") }
                                    .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.gray.opacity(0.15), in: Capsule())
                        }
                    }
                }
                Section("Dateien / Fotos / Videos") {
                    HStack {
                        TextField("Titel", text: $newDocTitle)
                        TextField("URL (optional)", text: $newDocUrl)
                        Button("+") {
                            let t = newDocTitle.trimmingCharacters(in: .whitespaces)
                            guard !t.isEmpty else { return }
                            docs.append(ZeitstrahlDoc(title: t, fileUrl: newDocUrl.isEmpty ? nil : newDocUrl))
                            newDocTitle = ""; newDocUrl = ""
                        }
                    }
                    ForEach(Array(docs.enumerated()), id: \.element.id) { idx, doc in
                        HStack {
                            Text(doc.title).font(.caption)
                            Spacer()
                            Picker("Relation", selection: Binding(
                                get: { docs[idx].relationType ?? "" },
                                set: { docs[idx].relationType = $0.isEmpty ? nil : $0 })
                            ) {
                                Text("Keine").tag("")
                                Text("beweist").tag("beweist")
                                Text("widerlegt").tag("widerlegt")
                                Text("überschneidet").tag("überschneidet")
                            }
                            .labelsHidden()
                            Button { docs.remove(at: idx) } label: { Image(systemName: "trash") }
                                .buttonStyle(.plain)
                        }
                    }
                    if !docs.isEmpty {
                        Button {
                            Task { await analyseMediaWithKI() }
                        } label: { Label("Fotos & Videos mit KI analysieren", systemImage: "sparkles") }
                    }
                }
                if !allEvents.isEmpty {
                    Section("Verknüpfung mit anderem Ereignis") {
                        Picker("Verknüpft mit", selection: Binding(
                            get: { relatedEventId ?? "" },
                            set: { relatedEventId = $0.isEmpty ? nil : $0 })
                        ) {
                            Text("Keine").tag("")
                            ForEach(allEvents.filter { $0.id != existing?.id }) { e in
                                Text(e.title).tag(e.id)
                            }
                        }
                        Picker("Beziehungstyp", selection: Binding(
                            get: { relationType ?? "" },
                            set: { relationType = $0.isEmpty ? nil : $0 })
                        ) {
                            Text("Typ wählen").tag("")
                            Text("bestätigt/beweist").tag("beweist")
                            Text("widerlegt").tag("widerlegt")
                            Text("überschneidet sich").tag("überschneidet")
                        }
                    }
                }
                if category == .vertrag || !checklist.isEmpty {
                    Section("Vertragspunkte / Erfüllungsliste") {
                        ForEach(Array(checklist.enumerated()), id: \.element.id) { idx, item in
                            VStack(alignment: .leading) {
                                HStack {
                                    Toggle("", isOn: Binding(
                                        get: { checklist[idx].erledigt },
                                        set: { checklist[idx].erledigt = $0 }
                                    )).labelsHidden()
                                    TextField("Punkt", text: Binding(
                                        get: { checklist[idx].titel },
                                        set: { checklist[idx].titel = $0 }
                                    ))
                                    Button { checklist.remove(at: idx) } label: { Image(systemName: "xmark") }
                                        .buttonStyle(.plain)
                                }
                                HStack {
                                    TextField("Fällig (YYYY-MM-DD)", text: Binding(
                                        get: { checklist[idx].faellig ?? "" },
                                        set: { checklist[idx].faellig = $0.isEmpty ? nil : $0 }
                                    ))
                                    TextField("Notiz", text: Binding(
                                        get: { checklist[idx].notiz ?? "" },
                                        set: { checklist[idx].notiz = $0.isEmpty ? nil : $0 }
                                    ))
                                }
                            }
                        }
                        HStack {
                            TextField("Neuer Punkt (z.B. Lieferung bis 15.01.)", text: $newCheckItem)
                            Button("+ Punkt") {
                                let t = newCheckItem.trimmingCharacters(in: .whitespaces)
                                guard !t.isEmpty else { return }
                                checklist.append(VertragsPunkt(titel: t)); newCheckItem = ""
                            }
                        }
                    }
                }
            }
            HStack {
                Spacer()
                Button("Abbrechen", action: onCancel)
                Button(existing == nil ? "Ereignis erstellen" : "Speichern") { Task { await save() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.top, 4)
        }
        .onAppear { if let ex = existing { populate(from: ex) } }
    }

    private func populate(from ex: TimelineEvent) {
        date = ex.date; title = ex.title
        description = ex.eventDescription ?? ""
        category = ex.category; importance = ex.importance
        persons = ex.personsInvolved
        if let s = ex.documentsJSON, let d = s.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(ZeitstrahlExtra.self, from: d) {
            checklist = parsed.checklist
            docs = parsed.docs
            relatedEventId = parsed.relatedEventId
            relationType = parsed.relationType
        }
    }

    /// KI-gestützte Analyse aller Bilder und Videos – setzt `kiAnalyse` & `kiSequenz`.
    private func analyseMediaWithKI() async {
        var updated = docs
        for (i, doc) in docs.enumerated() {
            let art = mediaArt(url: doc.fileUrl, mime: doc.fileType)
            if art == .image {
                let prompt = """
                Analysiere dieses Foto für eine rechtliche Fallakte (\(doc.fileUrl ?? "")):
                Was ist zu sehen, welche Personen, Datum/Ort, juristischer Beweiswert?
                """
                let res = await kiProvider.invokeLLM(prompt: prompt, schema: nil, caseId: caseId)
                if case .success(let any) = res {
                    updated[i].kiAnalyse = (any as? String) ?? ""
                    updated[i].kiAnalysiert = true
                }
            } else if art == .video {
                let prompt = """
                Analysiere dieses Video (\(doc.fileUrl ?? "")):
                Erstelle eine zeitliche Sequenz (zeitstempel/beschreibung) und beurteile den Beweiswert.
                """
                let schema: [String: Any] = [
                    "type": "object",
                    "properties": [
                        "zusammenfassung": ["type": "string"],
                        "sequenz": [
                            "type": "array",
                            "items": ["type": "object", "properties": [
                                "zeitstempel": ["type": "string"],
                                "beschreibung": ["type": "string"]
                            ]]
                        ],
                        "beweiswert": ["type": "string"]
                    ]
                ]
                let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
                if case .success(let any) = res, let dict = any as? [String: Any] {
                    let zs = (dict["zusammenfassung"] as? String) ?? ""
                    let bw = (dict["beweiswert"] as? String) ?? ""
                    updated[i].kiAnalyse = zs + (bw.isEmpty ? "" : "\n\nBeweiswert: \(bw)")
                    if let arr = dict["sequenz"] as? [[String: Any]] {
                        updated[i].kiSequenz = arr.map {
                            VideoSequenz(zeitstempel: $0["zeitstempel"] as? String,
                                         beschreibung: $0["beschreibung"] as? String)
                        }
                    }
                    updated[i].kiAnalysiert = true
                }
            }
        }
        docs = updated
    }

    private func save() async {
        var ev = existing ?? TimelineEvent(caseId: caseId, date: date, title: title)
        ev.date = date
        ev.title = title
        ev.eventDescription = description.isEmpty ? nil : description
        ev.category = category
        ev.importance = importance
        ev.personsInvolved = persons
        var extra = ZeitstrahlExtra()
        extra.checklist = checklist
        extra.docs = docs
        extra.relatedEventId = relatedEventId
        extra.relationType = relationType
        if let data = try? JSONEncoder().encode(extra),
           let s = String(data: data, encoding: .utf8) {
            ev.documentsJSON = s
        }
        _ = try? await cloudKit.save(ev)
        onSaved()
    }
}

// MARK: - Hilfs-Layout für umbrechende Tag-Rows
fileprivate struct WrappingHStack<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item, Int) -> Content
    init(items: [Item], @ViewBuilder content: @escaping (Item, Int) -> Content) {
        self.items = items; self.content = content
    }
    var body: some View {
        FlowLayout(spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                content(item, idx)
            }
        }
    }
}

/// Einfaches Flow-Layout (macOS 14+)
fileprivate struct FlowLayout: Layout {
    var spacing: CGFloat = 4
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? 300
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > maxW { x = 0; y += lineH + spacing; lineH = 0 }
            x += s.width + spacing
            lineH = max(lineH, s.height)
        }
        return CGSize(width: maxW, height: y + lineH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxW = bounds.width
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, lineH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > bounds.minX + maxW { x = bounds.minX; y += lineH + spacing; lineH = 0 }
            sv.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += s.width + spacing
            lineH = max(lineH, s.height)
        }
    }
}
