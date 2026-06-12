//
//  CasePDFExportService.swift
//  PDF-Export eines Falls (1:1 Port von base44/functions/exportCasePDF/entry.ts).
//  Nutzt Apples PDFKit für native macOS PDF-Generierung.
//

import Foundation
import PDFKit
import AppKit

@MainActor
public enum CasePDFExportService {

    /// Exportiert einen vollständigen Fallbericht als PDF.
    /// Lädt automatisch alle zugehörigen Argumente, Beweise, Personen, Fristen aus CloudKit.
    public static func export(caseEntity: Case,
                              arguments: [Argument],
                              evidence:  [Evidence],
                              persons:   [Person],
                              deadlines: [Deadline]) -> Data? {

        let pageWidth: CGFloat  = 612    // US-Letter (auch DIN-A4-tauglich)
        let pageHeight: CGFloat = 792
        let margin: CGFloat     = 50
        let contentW: CGFloat   = pageWidth - 2 * margin

        let pdfMetadata: [CFString: Any] = [
            kCGPDFContextTitle:   "MachiavelLEX – Fallbericht: \(caseEntity.fallname)" as CFString,
            kCGPDFContextAuthor:  "LegalOS" as CFString,
            kCGPDFContextCreator: "LegalOS macOS App" as CFString
        ]

        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let consumer = CGDataConsumer(data: pdfData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox,
                                  pdfMetadata as CFDictionary) else { return nil }

        var y: CGFloat = pageHeight - margin
        ctx.beginPDFPage(nil)

        // Drawing-Helper
        func newPageIfNeeded(_ space: CGFloat) {
            if y - space < margin {
                ctx.endPDFPage()
                ctx.beginPDFPage(nil)
                y = pageHeight - margin
            }
        }

        func addText(_ text: String, size: CGFloat = 10,
                     bold: Bool = false, color: NSColor = .black) {
            newPageIfNeeded(size + 6)
            let font = bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size)
            let para = NSMutableParagraphStyle()
            para.lineBreakMode = .byWordWrapping
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font, .foregroundColor: color, .paragraphStyle: para
            ]
            let attr = NSAttributedString(string: text, attributes: attrs)
            let frame = CGRect(x: margin, y: y - 100, width: contentW, height: 100)
            let path = CGPath(rect: frame, transform: nil)
            let framesetter = CTFramesetterCreateWithAttributedString(attr)
            let textFrame = CTFramesetterCreateFrame(framesetter,
                CFRange(location: 0, length: 0), path, nil)
            let lines = CTFrameGetLines(textFrame) as! [CTLine]
            let lineHeight: CGFloat = size + 4
            for line in lines {
                let lineY = y
                ctx.textPosition = CGPoint(x: margin, y: lineY - size)
                CTLineDraw(line, ctx)
                y -= lineHeight
            }
            y -= 2
        }

        func addSection(_ title: String) {
            y -= 6
            newPageIfNeeded(20)
            ctx.setFillColor(NSColor(white: 0.94, alpha: 1).cgColor)
            ctx.fill(CGRect(x: margin - 5, y: y - 14, width: contentW + 10, height: 16))
            addText(title, size: 11, bold: true)
            y -= 4
        }

        func addRule() {
            ctx.setStrokeColor(NSColor(white: 0.78, alpha: 1).cgColor)
            ctx.setLineWidth(0.5)
            ctx.move(to: CGPoint(x: margin, y: y))
            ctx.addLine(to: CGPoint(x: margin + contentW, y: y))
            ctx.strokePath()
            y -= 6
        }

        // ── Header ──────────────────────────────────────────────────
        addText("MachiavelLEX – Fallbericht", size: 18, bold: true)
        let df = DateFormatter()
        df.dateStyle = .long; df.locale = Locale(identifier: "de_DE")
        addText("Erstellt am \(df.string(from: Date()))",
                size: 9, color: NSColor(white: 0.45, alpha: 1))
        y -= 4
        addRule()

        // ── 1. Basisdaten ───────────────────────────────────────────
        addSection("1. Basisdaten")
        addText("Fallname: \(caseEntity.fallname)", size: 10, bold: true)
        if let v = caseEntity.aktenzeichen { addText("Aktenzeichen: \(v)") }
        if let v = caseEntity.gericht { addText("Gericht: \(v)") }
        if let v = caseEntity.rechtsgebiet { addText("Rechtsgebiet: \(v)") }
        addText("Status: \(caseEntity.status.rawValue)")
        addText("Instanz: \(caseEntity.instanz.rawValue)")
        if let v = caseEntity.streitwert { addText("Streitwert: \(formatEuro(v))") }

        // ── 2. KI-Prognose ──────────────────────────────────────────
        addSection("2. KI-Prognose")
        addText("Erfolgswahrscheinlichkeit: \(Int(caseEntity.prognose ?? 0)) %",
                size: 11, bold: true)
        if let v = caseEntity.zentraleRechtsfrage { addText("Zentrale Rechtsfrage: \(v)") }
        if let v = caseEntity.prozessziel { addText("Prozessziel: \(v)") }

        // ── 3. Argumentketten ───────────────────────────────────────
        addSection("3. Argumentketten")
        let eigene = arguments.filter { $0.side == .eigen }
        let gegner = arguments.filter { $0.side == .gegner }
        addText("Eigene Argumente (\(eigene.count)):", size: 10, bold: true)
        for (i, a) in eigene.enumerated() {
            let st = a.kiStrength ?? a.strength
            addText("\(i + 1). \(a.title) (Stärke: \(st.map { "\(Int($0))" } ?? "-")/10)")
            if let d = a.argDescription { addText("   \(d)", size: 9, color: NSColor(white: 0.3, alpha: 1)) }
        }
        y -= 2
        addText("Gegner-Argumente (\(gegner.count)):", size: 10, bold: true)
        for (i, a) in gegner.enumerated() {
            let st = a.kiStrength ?? a.strength
            addText("\(i + 1). \(a.title) (Stärke: \(st.map { "\(Int($0))" } ?? "-")/10)")
        }

        // ── 4. Beweislage ───────────────────────────────────────────
        addSection("4. Beweislage")
        if evidence.isEmpty {
            addText("Keine Beweise erfasst.")
        } else {
            for (i, e) in evidence.enumerated() {
                let w = e.kiWeight ?? e.weight
                addText("\(i + 1). \(e.title) – Gewicht: \(w.map { "\(Int($0))" } ?? "-")/10")
                if let d = e.evidenceDescription {
                    addText("   \(d)", size: 9, color: NSColor(white: 0.3, alpha: 1))
                }
            }
        }

        // ── 5. Personen ─────────────────────────────────────────────
        addSection("5. Beteiligte Personen")
        if persons.isEmpty {
            addText("Keine Personen erfasst.")
        } else {
            for (i, p) in persons.enumerated() {
                let org = p.organization.map { " (\($0))" } ?? ""
                addText("\(i + 1). \(p.name) – \(p.role.rawValue)\(org)")
                if let g = p.glaubwuerdigkeit {
                    addText("   Glaubwürdigkeit: \(Int(g))%", size: 9,
                            color: NSColor(white: 0.3, alpha: 1))
                }
            }
        }

        // ── 6. Fristen ──────────────────────────────────────────────
        addSection("6. Fristen")
        let dateF = DateFormatter()
        dateF.dateStyle = .medium; dateF.locale = Locale(identifier: "de_DE")
        let sorted = deadlines.sorted { $0.dueDate < $1.dueDate }
        if sorted.isEmpty {
            addText("Keine Fristen erfasst.")
        } else {
            for (i, d) in sorted.enumerated() {
                addText("\(i + 1). \(d.title) – Fällig: \(dateF.string(from: d.dueDate)) [\(d.status.rawValue)]")
            }
        }

        // ── Footer ──────────────────────────────────────────────────
        y -= 6
        addRule()
        addText("LegalOS – Legal Intelligence Platform",
                size: 8, color: NSColor(white: 0.6, alpha: 1))

        ctx.endPDFPage()
        ctx.closePDF()
        return pdfData as Data
    }

    /// Speichert das PDF mit einem System-Save-Dialog.
    public static func saveToFile(_ data: Data, defaultName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = defaultName
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }
}

// Hilfsformatierung
private func formatEuro(_ v: Double) -> String {
    let nf = NumberFormatter()
    nf.numberStyle = .decimal
    nf.locale = Locale(identifier: "de_DE")
    nf.maximumFractionDigits = 0
    return (nf.string(from: NSNumber(value: v)) ?? "\(Int(v))") + " €"
}
