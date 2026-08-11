import Foundation
import PDFKit
import AppKit
import CoreText

// MARK: - Export & Akte (PDF Teil 8)

enum FenlynineOSKernExportService {

static func akteAlsText(store: FenlynineOSKernStore, funde: [FenlynineOSAuditorFund] = []) -> String {
  var s = [
    "nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn",
    "FENLYNINEOS -- GESAMT-AKTE",
    "nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn",
    "",
    "DECKBLATT",
    "Basis-Situation: \(store.basisSituation)",
    "Ziel: \(store.ziel)",
    "Phase: \(store.phase.bezeichnung)",
    "Exportiert: \(formattedDate())",
    "",
    "nn MODULE (PDF Teil 1) nn",
    "Oportun -> Strategos -> Lexara -> Advocatus",
    "",
    "nn KNOTEN (\(store.knoten.count)) nn"
  ]
  for k in store.knoten.sorted(by: { $0.tiefe < $1.tiefe }) {
    s.append("")
    s.append("[\(k.typ.bezeichnung)] \(k.titel) (\(k.modul.bezeichnung))")
    s.append(" Status: \(k.status.rawValue) | Herkunft: \(k.herkunft)")
    if let p = k.pErfolg { s.append(" P(Erfolg): \(Int(p*100))%") }
    if let ev = k.ev { s.append(" EV: \(String(format: "%.0f", ev))") }
    if let rav = k.rav { s.append(" RAV: \(String(format: "%.0f", rav))") }
    if let rpn = k.rpn { s.append(" RPN: \(Int(rpn))") }
    if let trigger = k.kausalTrigger { s.append(" Trigger: \(trigger)") }
  }
  s.append(""); s.append("nn KANTEN (\(store.kanten.count)) nn")
  for k in store.kanten {
    s.append(" \(k.vonId) n[\(k.typ.bezeichnung)]-> \(k.zuId): \(k.kausalitaet)")
  }
  if !funde.isEmpty {
    s.append(""); s.append("nn AUDITOR-PRÜFBERICHT nn")
    s.append(FenlynineOSAuditorService.pruefberichtText(store: store, funde: funde))
  }
  if let analyse = store.letzteAnalyse {
    s.append(""); s.append("nn KI-ANALYSE nn"); s.append(analyse)
  }
  return s.joined(separator: "\n")
}

@discardableResult
static func speichereAkte(store: FenlynineOSKernStore, funde: [FenlynineOSAuditorFund] = []) -> URL? {
  let text = akteAlsText(store: store, funde: funde)
  let stamp = dateStamp()
  let txtURL = downloadsURL().appendingPathComponent("FenlynineOS-Akte-\(stamp).txt")
  let pdfURL = downloadsURL().appendingPathComponent("FenlynineOS-Akte-\(stamp).pdf")
  do {
    try text.write(to: txtURL, atomically: true, encoding: .utf8)
    try erzeugePDF(text: text, url: pdfURL)
    return pdfURL
  } catch { return nil }
}

private static func erzeugePDF(text: String, url: URL) throws {
  let font = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
  let attrs: [NSAttributedString.Key: Any] = [.font: font]
  let attr = NSAttributedString(string: text, attributes: attrs)
  let framesetter = CTFramesetterCreateWithAttributedString(attr)
  let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
  let pdf = PDFDocument()
  let lines = text.components(separatedBy: "\n")
  var chunk = ""; var pageNum = 0
  for line in lines {
    if (chunk + line).count > 3500 {
      pdf.insert(erzeugeSeite(framesetter: framesetter, text: chunk, rect: pageRect), at: pageNum)
      pageNum += 1; chunk = line + "\n"
    } else { chunk += line + "\n" }
  }
  if !chunk.isEmpty {
    pdf.insert(erzeugeSeite(framesetter: framesetter, text: chunk, rect: pageRect), at: pageNum)
  }
  pdf.write(to: url)
}

private static func erzeugeSeite(framesetter: CTFramesetter, text: String, rect: CGRect) -> PDFPage {
  let path = CGPath(rect: rect.insetBy(dx: 40, dy: 40), transform: nil)
  let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
  let data = NSMutableData()
  var box = rect
  guard let consumer = CGDataConsumer(data: data),
     let ctx = CGContext(consumer: consumer, mediaBox: &box, nil) else {
    return PDFPage()
  }
  ctx.beginPDFPage(nil)
  CTFrameDraw(frame, ctx)
  ctx.endPDFPage(); ctx.closePDF()
  return PDFDocument(data: data as Data)?.page(at: 0) ?? PDFPage()
}

private static func downloadsURL() -> URL {
 FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
}

private static func dateStamp() -> String {
 let f = DateFormatter(); f.dateFormat = "yyyyMMdd-HHmm"; return f.string(from: Date())
}

private static func formattedDate() -> String {
 let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f.string(from: Date())
}
}

