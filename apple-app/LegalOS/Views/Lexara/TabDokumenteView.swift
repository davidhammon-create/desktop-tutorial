//
//  TabDokumenteView.swift
//  Konversion von src/components/lexara/TabDokumente.jsx
//  Dokumentenverwaltung mit Hochladen, Vorschau, KI-Analyse und Argument-Extraktion.
//

import SwiftUI
import UniformTypeIdentifiers

struct TabDokumenteView: View {
    let caseId: String

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var documents: [LegalDocument] = []
    @State private var loading = true
    @State private var importing = false
    @State private var selectedDoc: LegalDocument? = nil
    @State private var showImporter = false
    @State private var analyzing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if loading { ProgressView().padding() }
                else if documents.isEmpty { emptyState }
                else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                        ForEach(documents) { doc in
                            documentCard(doc)
                                .onTapGesture { selectedDoc = doc }
                        }
                    }
                }
            }.padding(20)
        }
        .task { await load() }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pdf, .text, UTType("public.composite-content") ?? .data]) { result in
            if case .success(let url) = result { Task { await importDoc(url) } }
        }
        .sheet(item: $selectedDoc) { doc in detailSheet(doc) }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Dokumente").font(.headline)
                Text("\(documents.count) Dokumente").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Button { showImporter = true } label: { Label("Hochladen", systemImage: "plus") }.buttonStyle(.borderedProminent).disabled(importing)
        }
    }

    private var emptyState: some View {
        VStack {
            Image(systemName: "doc.fill").font(.largeTitle).foregroundColor(.secondary)
            Text("Noch keine Dokumente").foregroundColor(.secondary)
        }.frame(maxWidth: .infinity).padding(40).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func documentCard(_ doc: LegalDocument) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: iconFor(doc.fileType)).font(.largeTitle).foregroundColor(.blue)
            Text(doc.title).font(.subheadline.weight(.semibold)).lineLimit(2)
            if let s = doc.aiSummary { Text(s).font(.caption2).foregroundColor(.secondary).lineLimit(3) }
            if !doc.extractedArguments.isEmpty {
                Label("\(doc.extractedArguments.count) Argumente", systemImage: "text.bubble").font(.caption2).foregroundColor(.green)
            }
        }
        .padding(12).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func detailSheet(_ doc: LegalDocument) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(doc.title).font(.headline)
                Spacer()
                Button { selectedDoc = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
            }
            if let s = doc.aiSummary {
                GroupBox("Zusammenfassung") { Text(s).font(.body).padding(8) }
            } else {
                Button { Task { await analyze(doc) } } label: {
                    Label(analyzing ? "Analysiere…" : "KI-Analyse starten", systemImage: "sparkles")
                }.buttonStyle(.borderedProminent).disabled(analyzing)
            }
            if !doc.extractedArguments.isEmpty {
                GroupBox("Extrahierte Argumente") {
                    VStack(alignment: .leading) {
                        ForEach(doc.extractedArguments, id: \.self) { Text("• \($0)").font(.caption) }
                    }.padding(8)
                }
            }
            HStack {
                Button("Löschen", role: .destructive) { Task { await delete(doc) } }
                Spacer()
            }
        }.padding(20).frame(width: 540, height: 480)
    }

    private func iconFor(_ type: String?) -> String {
        switch type?.lowercased() {
        case "pdf": return "doc.richtext"
        case "txt", "md": return "doc.text"
        case "docx": return "doc"
        default: return "doc.fill"
        }
    }

    private func load() async {
        loading = true; defer { loading = false }
        do { documents = try await cloudKit.fetchForCase(LegalDocument.self, caseId: caseId) }
        catch { cloudKit.lastError = error.localizedDescription }
    }

    private func importDoc(_ url: URL) async {
        importing = true; defer { importing = false }
        let title = url.deletingPathExtension().lastPathComponent
        var doc = LegalDocument(caseId: caseId, title: title)
        doc.fileType = url.pathExtension
        doc.fileUrl = url.absoluteString
        do { _ = try await cloudKit.save(doc); await load() }
        catch { cloudKit.lastError = error.localizedDescription }
    }

    private func analyze(_ doc: LegalDocument) async {
        analyzing = true; defer { analyzing = false }
        let prompt = "Fasse das Dokument \"\(doc.title)\" für einen Anwalt zusammen und extrahiere relevante Argumente (max. 10)."
        let res = await kiProvider.invokeLLM(prompt: prompt, context: "Dokumentanalyse", caseId: caseId)
        if case .success(let v) = res, let raw = v as? String {
            var d = doc
            d.aiSummary = raw
            do { _ = try await cloudKit.save(d); await load() }
            catch { cloudKit.lastError = error.localizedDescription }
        }
    }

    private func delete(_ doc: LegalDocument) async {
        do { try await cloudKit.delete(recordID: doc.id); await load(); selectedDoc = nil }
        catch { cloudKit.lastError = error.localizedDescription }
    }
}
