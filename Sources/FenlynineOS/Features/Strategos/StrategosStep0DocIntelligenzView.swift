import SwiftUI
import AppKit
import UniformTypeIdentifiers
struct StrategosStep0DocIntelligenzView: View {
    @Binding var szenario: StrategosScenario
    let onSave: ([String: Any]) async -> Void
    let onProceed: () -> Void
    struct DocEntry: Identifiable {
        var id: String
        var name: String
        var status: String
        var url: String?
        var summary: String?
        var doc_typ: String?
    }
    @State private var docs: [DocEntry] = []
    @State private var uploading = false
    @State private var analyzing = false
    @State private var result: [String: Any]?
    @State private var done = false
    @State private var fehler: String?
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Label("Strategos · Dokumenten-Intelligenz", systemImage: "brain.head.profile")
                    .font(.caption.bold())
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing), in: Capsule())
                    .foregroundStyle(.white)
                Text("Dokumente hochladen & KI briefen").font(.title2.bold())
                Text("Die KI extrahiert alle Informationen und versorgt automatisch jeden nachfolgenden Analyse-Schritt mit Kontext.")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            if let err = fehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            dropZone
            if !docs.isEmpty {
                docList
            }
            if let r = result {
                ergebnisPanel(r)
            }
        }
        .onAppear { hydrate() }
    }
    private var dropZone: some View {
        Button {
            pickFiles()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "arrow.up.doc.fill").font(.title).foregroundStyle(.purple)
                Text("Dateien auswählen").font(.subheadline.bold()).foregroundStyle(.purple)
                Text("PDF · DOCX · TXT · JPG · PNG · XLSX · EML").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(32)
            .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8])))
        }
        .buttonStyle(.plain)
        .disabled(uploading)
    }
    private var docList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(docs.count) Dokument(e) · \(docs.filter { $0.status == "done" }.count) bereit")
                    .font(.caption.bold()).foregroundStyle(.secondary)
                Spacer()
                if docs.contains(where: { $0.status == "done" }) && !done {
                    Button {
                        Task { await runAnalysis() }
                    } label: {
                        if analyzing { ProgressView().scaleEffect(0.7); Text("KI analysiert…") }
                        else { Label("Jetzt KI-Analyse starten", systemImage: "sparkles") }
                    }
                    .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                    .disabled(analyzing)
                } else if done {
                    Label("Analyse abgeschlossen", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold()).foregroundStyle(.green)
                }
            }
            ForEach(docs) { doc in
                HStack {
                    Image(systemName: "doc.fill").foregroundStyle(doc.status == "done" ? .green : .purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(doc.name).font(.caption.bold()).lineLimit(1)
                        if let s = doc.summary { Text(s).font(.caption2).foregroundStyle(.secondary).lineLimit(1) }
                        else if doc.status == "analyzing" { Text("KI analysiert…").font(.caption2).foregroundStyle(.orange) }
                        else if doc.status == "uploading" { Text("Lädt hoch…").font(.caption2) }
                    }
                    Spacer()
                    Button { Task { await removeDoc(doc.id) } } label: {
                        Image(systemName: "trash").font(.caption2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background((doc.status == "done" ? Color.green : Color.purple).opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            }
            if done {
                Button("↺ Neu analysieren") { Task { await runAnalysis() } }
                    .font(.caption).buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                    .disabled(analyzing)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.12)))
    }
    @ViewBuilder
    private func ergebnisPanel(_ r: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("KI-Analyse · Ergebnis").font(.caption.bold()).foregroundStyle(.secondary)
                    Text(r["unternehmen_name"] as? String ?? szenario.titel).font(.headline)
                    if let g = r["gegner_name"] as? String {
                        Text("vs. \(g)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let risk = KIJson.numberValue(r["gesamtrisiko_einschaetzung"]) {
                    VStack {
                        Text("\(Int(risk.rounded()))/10").font(.title2.bold())
                            .foregroundStyle(risk >= 8 ? .red : risk >= 5 ? .orange : .green)
                        Text("Gesamtrisiko").font(.caption2)
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            if let briefing = r["ki_briefing"] as? String, !briefing.isEmpty {
                Text("KI-Briefing").font(.caption.bold())
                Text(briefing).font(.caption2).lineLimit(8)
            }
            if let facts = r["schluessel_fakten"] as? [String], !facts.isEmpty {
                Text("Schlüsselfakten").font(.caption.bold())
                ForEach(facts.prefix(5), id: \.self) { Text("• \($0)").font(.caption2) }
            }
            Button {
                onProceed()
            } label: {
                Label("Weiter zu Kontext & Situation →", systemImage: "chevron.right")
            }
            .buttonStyle(FenlynineOSGlassProminentButtonStyle())
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.12)))
    }
    private func hydrate() {
        guard let ki = szenario.ki_kontext?.dictValue else { return }
        if let docArr = ki["docs"] as? [[String: Any]] {
            docs = docArr.compactMap { d in
                guard let id = d["id"] as? String, let name = d["name"] as? String else { return nil }
                return DocEntry(
                    id: id, name: name,
                    status: d["status"] as? String ?? "done",
                    url: d["url"] as? String,
                    summary: d["summary"] as? String,
                    doc_typ: d["doc_typ"] as? String
                )
            }
        }
        if let analyse = ki["analyse"] as? [String: Any] {
            result = analyse
            done = true
        }
    }
    private func pickFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.pdf, .plainText, .text, .png, .jpeg, .commaSeparatedText, .data]
        guard panel.runModal() == .OK else { return }
        Task { await handleFiles(panel.urls) }
    }
    private func handleFiles(_ urls: [URL]) async {
        uploading = true
        fehler = nil
        defer { uploading = false }
        var newDocs: [DocEntry] = []
        for url in urls {
            let tempId = UUID().uuidString
            var pending = DocEntry(id: tempId, name: url.lastPathComponent, status: "uploading", url: nil, summary: nil, doc_typ: nil)
            await MainActor.run { docs.append(pending) }
            do {
                let data = try Data(contentsOf: url)
                let mime = mimeType(for: url)
                let fileUrl = try await LLMService.shared.uploadFile(data: data, fileName: url.lastPathComponent, mimeType: mime)
                pending.status = "analyzing"
                pending.url = fileUrl
                await MainActor.run {
                    if let i = docs.firstIndex(where: { $0.id == tempId }) { docs[i] = pending }
                }
                let summarySchema: [String: Any] = [
                    "type": "object",
                    "properties": ["summary": ["type": "string"], "doc_typ": ["type": "string"]]
                ]
                let s: AnyCodable = try await LLMService.shared.invoke(
                    prompt: "Fasse dieses Dokument in max. 1 Satz zusammen: Name, Typ, worum geht es?",
                    schema: summarySchema,
                    fileUrls: [fileUrl],
                    model: "claude_sonnet_4_6"
                )
                let sd = s.dictValue ?? [:]
                pending.status = "done"
                pending.summary = sd["summary"] as? String ?? url.lastPathComponent
                pending.doc_typ = sd["doc_typ"] as? String
                newDocs.append(pending)
                await MainActor.run {
                    if let i = docs.firstIndex(where: { $0.id == tempId }) { docs[i] = pending }
                }
            } catch {
                await MainActor.run {
                    docs.removeAll { $0.id == tempId }
                    fehler = error.localizedDescription
                }
            }
        }
        let docDicts = docs.map { docToDict($0) }
        await onSave(["ki_kontext": mergeKiKontext(["docs": docDicts])])
    }
    private func removeDoc(_ id: String) async {
        docs.removeAll { $0.id == id }
        if docs.isEmpty { result = nil; done = false }
        await onSave(["ki_kontext": mergeKiKontext(["docs": docs.map { docToDict($0) }])])
    }
    private func runAnalysis() async {
        let ready = docs.filter { $0.status == "done" && $0.url != nil }
        guard !ready.isEmpty else { return }
        analyzing = true
        fehler = nil
        defer { analyzing = false }
        let fileUrls = ready.compactMap { $0.url }
        let docList = ready.map { "\($0.name)\($0.summary.map { " (\($0))" } ?? "")" }.joined(separator: "\n")
        let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
        let prompt = """
        Du bist der intelligenteste strategische Assistent einer Großkanzlei. Extrahiere aus den Dokumenten alle relevanten Informationen für eine strategische Unternehmensanalyse.
        Dokumente:
        \(docList)
        Extrahiere: unternehmen_name, rechtsform, branche, umsatz, mitarbeiter, hauptsitz_land, hauptsitz_stadt, gegner_name, gegner_rolle, sachverhalt_lang, zeitkritikalitaet, szenario_typ, rechtsgebiet, fragestellung, ausgangslage, ki_briefing (mind. 300 Wörter), empfohlene_rechtsgebiete, schluessel_fakten, zeitachse, parteien, kritische_fristen, gesamtrisiko_einschaetzung.
        NUR was explizit aus dem Dokument hervorgeht — kein Raten.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "unternehmen_name": ["type": "string"], "rechtsform": ["type": "string"],
                "branche": ["type": "string"], "umsatz": ["type": "number"], "mitarbeiter": ["type": "number"],
                "hauptsitz_land": ["type": "string"], "hauptsitz_stadt": ["type": "string"],
                "gegner_name": ["type": "string"], "gegner_rolle": ["type": "string"],
                "sachverhalt_lang": ["type": "string"], "zeitkritikalitaet": ["type": "number"],
                "szenario_typ": ["type": "string"], "rechtsgebiet": ["type": "string"],
                "fragestellung": ["type": "string"], "ausgangslage": ["type": "string"],
                "ki_briefing": ["type": "string"],
                "empfohlene_rechtsgebiete": ["type": "array", "items": ["type": "string"]],
                "schluessel_fakten": ["type": "array", "items": ["type": "string"]],
                "zeitachse": ["type": "array", "items": ["type": "object"]],
                "parteien": ["type": "array", "items": ["type": "object"]],
                "kritische_fristen": ["type": "array", "items": ["type": "object"]],
                "gesamtrisiko_einschaetzung": ["type": "number"]
            ] as [String: Any]
        ] as [String: Any]
        do {
            let response: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt, schema: schema, fileUrls: fileUrls, model: "claude_sonnet_4_6"
            )
            guard let r = try? KIJson.requireObject(response, kontext: "Dokumentenanalyse") else {
                await MainActor.run { fehler = "Keine verwertbare KI-Antwort erhalten." }
                return
            }
            var newCtx = ctx
            for key in ["unternehmen_name", "rechtsform", "branche", "gegner_name", "gegner_rolle", "sachverhalt_lang", "hauptsitz_land", "hauptsitz_stadt"] {
                if let v = r[key] as? String, !v.isEmpty, (newCtx[key] as? String)?.isEmpty != false {
                    newCtx[key] = v
                }
            }
            if let u = r["umsatz"] as? Double, newCtx["umsatz"] == nil { newCtx["umsatz"] = u }
            if let m = r["mitarbeiter"] as? Double, newCtx["mitarbeiter"] == nil { newCtx["mitarbeiter"] = m }
            if let z = r["zeitkritikalitaet"] as? Double, newCtx["zeitkritikalitaet"] == nil { newCtx["zeitkritikalitaet"] = z }
            if let rg = r["empfohlene_rechtsgebiete"] as? [String], !rg.isEmpty { newCtx["rechtsgebiete"] = rg }
            newCtx["dokumente"] = ready.compactMap { doc -> [String: Any]? in
                guard let url = doc.url, KIFileURLs.isValidAttachmentURL(url) else { return nil }
                return ["name": doc.name, "url": url, "type": doc.doc_typ ?? "", "summary": doc.summary ?? ""]
            }
            var patch: [String: Any] = [
                "unternehmenskontext": newCtx,
                "ki_kontext": mergeKiKontext([
                    "docs": docs.map { docToDict($0) },
                    "analyse": r,
                    "ki_briefing": r["ki_briefing"] ?? "",
                    "schluessel_fakten": r["schluessel_fakten"] ?? [],
                    "zeitachse": r["zeitachse"] ?? [],
                    "parteien": r["parteien"] ?? [],
                    "kritische_fristen": r["kritische_fristen"] ?? []
                ])
            ]
            for key in ["szenario_typ", "rechtsgebiet", "fragestellung", "ausgangslage"] {
                if let v = r[key] as? String, !v.isEmpty {
                    if key == "szenario_typ" && szenario.szenario_typ == nil { patch["szenario_typ"] = v }
                    if key == "rechtsgebiet" && szenario.rechtsgebiet == nil { patch["rechtsgebiet"] = v }
                    if key == "fragestellung" && szenario.fragestellung == nil { patch["fragestellung"] = v }
                    if key == "ausgangslage" && szenario.ausgangslage == nil { patch["ausgangslage"] = v }
                }
            }
            await onSave(patch)
            await MainActor.run { result = r; done = true }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
    private func mergeKiKontext(_ updates: [String: Any]) -> [String: Any] {
        var ki = szenario.ki_kontext?.dictValue ?? [:]
        for (k, v) in updates { ki[k] = v }
        return ki
    }
    private func docToDict(_ d: DocEntry) -> [String: Any] {
        var o: [String: Any] = ["id": d.id, "name": d.name, "status": d.status]
        if let u = d.url { o["url"] = u }
        if let s = d.summary { o["summary"] = s }
        if let t = d.doc_typ { o["doc_typ"] = t }
        return o
    }
    private func mimeType(for url: URL) -> String {
        if url.pathExtension.lowercased() == "pdf" { return "application/pdf" }
        if ["jpg", "jpeg", "png"].contains(url.pathExtension.lowercased()) { return "image/jpeg" }
        return "application/octet-stream"
    }
}
