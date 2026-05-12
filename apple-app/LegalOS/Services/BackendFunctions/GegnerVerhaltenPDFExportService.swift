//
//  GegnerVerhaltenPDFExportService.swift
//  PDF-Export der Gegnerverhalten-Analyse (Taktiken, Schwachstellen, Empfehlungen).
//  1:1 Port von base44/functions/exportGegnerVerhaltenPDF/entry.ts.
//

import Foundation
import AppKit

@MainActor
public enum GegnerVerhaltenPDFExportService {

    public static func export(caseEntity: Case,
                              gegnerVerhalten: [GegnerVerhalten],
                              persons: [Person]) -> Data? {
        let pageW: CGFloat = 612, pageH: CGFloat = 792, m: CGFloat = 50
        let contentW = pageW - 2 * m
        let pdfData = NSMutableData()
        var box = CGRect(x: 0, y: 0, width: pageW, height: pageH)
        guard let consumer = CGDataConsumer(data: pdfData),
              let ctx = CGContext(consumer: consumer, mediaBox: &box, nil) else { return nil }

        var y: CGFloat = pageH - m
        ctx.beginPDFPage(nil)

        func newPageIfNeeded(_ s: CGFloat) {
            if y - s < m { ctx.endPDFPage(); ctx.beginPDFPage(nil); y = pageH - m }
        }
        func text(_ t: String, size: CGFloat = 10, bold: Bool = false, color: NSColor = .black) {
            newPageIfNeeded(size + 6)
            let font = bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size)
            let attr = NSAttributedString(string: t, attributes: [.font: font, .foregroundColor: color])
            let frame = CGRect(x: m, y: y - 100, width: contentW, height: 100)
            let path = CGPath(rect: frame, transform: nil)
            let fs = CTFramesetterCreateWithAttributedString(attr)
            let tf = CTFramesetterCreateFrame(fs, CFRange(location: 0, length: 0), path, nil)
            let lines = CTFrameGetLines(tf) as! [CTLine]
            for line in lines {
                ctx.textPosition = CGPoint(x: m, y: y - size)
                CTLineDraw(line, ctx); y -= size + 4
            }
            y -= 2
        }
        func section(_ t: String) {
            y -= 6; newPageIfNeeded(20)
            ctx.setFillColor(NSColor(white: 0.94, alpha: 1).cgColor)
            ctx.fill(CGRect(x: m - 5, y: y - 14, width: contentW + 10, height: 16))
            text(t, size: 11, bold: true); y -= 4
        }

        // Header
        text("Gegnerverhalten-Analyse", size: 18, bold: true)
        text("Fall: \(caseEntity.fallname)", size: 10, color: NSColor(white: 0.4, alpha: 1))
        let df = DateFormatter(); df.dateStyle = .long; df.locale = Locale(identifier: "de_DE")
        text("Erstellt am \(df.string(from: Date()))", size: 9, color: NSColor(white: 0.5, alpha: 1))
        y -= 4

        // Gegnerprofile aus Personen
        let gegnerPersonen = persons.filter { $0.role == .partei || $0.role == .anwalt }
        if !gegnerPersonen.isEmpty {
            section("1. Gegnerische Akteure")
            for p in gegnerPersonen {
                text("\(p.name) – \(p.role.rawValue)\(p.organization.map { " (\($0))" } ?? "")",
                     size: 10, bold: true)
                if let g = p.glaubwuerdigkeit {
                    text("Glaubwürdigkeit: \(Int(g))%", size: 9, color: NSColor(white: 0.3, alpha: 1))
                }
                if p.aussagen > 0 || p.widersprueche > 0 {
                    text("Aussagen: \(p.aussagen), Widersprüche: \(p.widersprueche)", size: 9)
                }
            }
        }

        // Dokumentierte Verhaltensmuster
        section("2. Dokumentierte Verhaltensmuster")
        if gegnerVerhalten.isEmpty {
            text("Keine dokumentierten Muster.")
        } else {
            let dF = DateFormatter(); dF.dateStyle = .medium; dF.locale = Locale(identifier: "de_DE")
            for v in gegnerVerhalten {
                text("• \(v.typ.rawValue) – \(v.titel)", size: 10, bold: true)
                if let b = v.beschreibung { text("  \(b)", size: 9) }
                if let d = v.datum {
                    text("  Datum: \(dF.string(from: d))", size: 9, color: NSColor(white: 0.3, alpha: 1))
                }
                if let r = v.reaktion {
                    text("  Reaktion: \(r.rawValue)", size: 9, color: NSColor.systemBlue)
                }
                if let u = v.unserAngebot, let g = v.gegnerAngebot {
                    text("  Unser Angebot: \(Int(u))€ vs. Gegnerangebot: \(Int(g))€", size: 9)
                }
            }
        }

        // Strategie-Empfehlungen
        section("3. Strategie-Empfehlungen")
        text("• Konsistenz vs. Inkonsistenz dokumentieren", size: 10)
        text("• Widersprüche der Gegenseite gezielt in der Verhandlung adressieren", size: 10)
        text("• Glaubwürdigkeitsmaße bei Zeugenvernehmungen nutzen", size: 10)

        ctx.endPDFPage(); ctx.closePDF()
        return pdfData as Data
    }

    public static func saveToFile(_ data: Data, defaultName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = defaultName
        if panel.runModal() == .OK, let url = panel.url { try? data.write(to: url) }
    }
}
