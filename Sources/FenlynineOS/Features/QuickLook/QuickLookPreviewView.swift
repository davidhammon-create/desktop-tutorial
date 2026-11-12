import SwiftUI
import QuickLookUI
import AppKit
struct QuickLookPreviewButton: View {
    let url: URL
    let label: String
    @State private var zeigeVorschau = false
    var body: some View {
        Button {
            zeigeVorschau = true
        } label: {
            Label(label, systemImage: "eye")
        }
        .sheet(isPresented: $zeigeVorschau) {
            QuickLookSheet(url: url)
        }
    }
}
struct QuickLookSheet: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(url.lastPathComponent)
                    .font(.headline)
                Spacer()
                Button("Schließen") { dismiss() }
                    .keyboardShortcut(.escape)
            }
            .padding(16)
            Divider()
            QuickLookPreviewView(url: url)
                .frame(minWidth: 640, minHeight: 480)
        }
        .frame(width: 800, height: 600)
    }
}
struct QuickLookPreviewView: NSViewRepresentable {
    let url: URL
    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView()
        view.autostarts = true
        return view
    }
    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        nsView.previewItem = url as QLPreviewItem
    }
}
struct DokumentVorschauKarte: View {
    let dokument: LegalDocument
    @State private var zeigeVorschau = false
    @State private var temporaereURL: URL?
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: dokumentIcon)
                .font(.system(size: 24))
                .foregroundStyle(dokumentFarbe)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(dokument.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
                HStack(spacing: 8) {
                    if let typ = dokument.file_type {
                        Text(typ.uppercased())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let groesse = dokument.file_size {
                        Text(formatGroesse(groesse))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(dokument.kategorie.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1), in: Capsule())
                }
            }
            Spacer()
            if dokument.ai_summary != nil {
                Image(systemName: "brain")
                    .font(.system(size: 12))
                    .foregroundStyle(.purple)
                    .help("KI-Analyse vorhanden")
            }
            if let urlString = dokument.file_url, let url = URL(string: urlString) {
                Button {
                    zeigeVorschau = true
                    temporaereURL = url
                } label: {
                    Image(systemName: "eye")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help("Vorschau anzeigen")
            }
            if let urlString = dokument.file_url, let url = URL(string: urlString) {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                }
                .help("Dokument teilen")
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        .sheet(isPresented: $zeigeVorschau) {
            if let url = temporaereURL {
                QuickLookSheet(url: url)
            }
        }
    }
    private var dokumentIcon: String {
        switch dokument.file_type?.lowercased() {
        case "pdf": return "doc.richtext"
        case "docx", "doc": return "doc.text"
        case "xlsx", "xls": return "tablecells"
        case "pptx", "ppt": return "rectangle.on.rectangle"
        case "jpg", "jpeg", "png", "gif": return "photo"
        default: return "doc"
        }
    }
    private var dokumentFarbe: Color {
        switch dokument.file_type?.lowercased() {
        case "pdf": return .red
        case "docx", "doc": return .blue
        case "xlsx", "xls": return .green
        case "pptx", "ppt": return .orange
        case "jpg", "jpeg", "png": return .purple
        default: return .gray
        }
    }
    private func formatGroesse(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024
        if kb < 1024 { return String(format: "%.0f KB", kb) }
        return String(format: "%.1f MB", kb / 1024)
    }
}
struct FallTeilenButton: View {
    let fall: LegalCase
    @State private var zeigeTeilenMenu = false
    var body: some View {
        Button {
            zeigeNativeShareSheet()
        } label: {
            Label("Fall teilen", systemImage: "square.and.arrow.up")
        }
        .help("Fall-Zusammenfassung teilen")
    }
    private func zeigeNativeShareSheet() {
        let zusammenfassung = fallZusammenfassung()
        let picker = NSSharingServicePicker(items: [zusammenfassung])
        if let window = NSApp.keyWindow,
           let view = window.contentView {
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }
    private func fallZusammenfassung() -> String {
        var text = "⚖️ \(fall.fallname)\n"
        if let az = fall.aktenzeichen { text += "Aktenzeichen: \(az)\n" }
        if let gericht = fall.gericht { text += "Gericht: \(gericht)\n" }
        text += "Status: \(fall.status.rawValue)\n"
        if let prognose = fall.prognose {
            text += "Prognose: \(Int(prognose))%\n"
        }
        text += "\nExportiert aus FenlynineOS"
        return text
    }
}
struct BerichtTeilenButton: View {
    let pdfURL: URL
    let titel: String
    var body: some View {
        ShareLink(item: pdfURL, subject: Text(titel)) {
            Label("PDF teilen", systemImage: "square.and.arrow.up")
        }
    }
}
