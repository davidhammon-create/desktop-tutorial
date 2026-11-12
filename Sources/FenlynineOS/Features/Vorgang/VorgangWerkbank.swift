import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit
import CoreText
struct VorgangWerkbank: View {
    let vorgangId: UUID
    @Bindable var store: VorgangStore = .shared
    @State private var offen = true
    @State private var titel = ""
    @State private var gebiet = ""
    @State private var volumenText = ""
    @State private var beschreibung = ""
    @State private var parteiRolle = "Gegner"
    @State private var parteiName = ""
    @State private var optLabel = ""
    @State private var optP = "0,60"
    @State private var optBest = "20000"
    @State private var optWorst = "-8000"
    @State private var optKosten = "4000"
    @State private var abweichung = ""
    @State private var realKosten = ""
    @State private var realMonate = "12"
    @State private var realAusgang = ""
    @State private var hinweis: String?
    private var v: Vorgang? { store.vorgang(vorgangId) }
    var body: some View {
        if let v {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    offen.toggle()
                } label: {
                    HStack {
                        Text("HANDELN")
                            .font(.system(size: 10, weight: .semibold))
                            .kerning(0.4)
                        Text(v.zustand.bedingung + " · " + v.zustand.wasErlaubt)
                            .font(.system(size: 11))
                            .foregroundStyle(InterfacePalette.sekundaer)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: offen ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Premium.text)
                }
                .buttonStyle(.plain)
                if offen {
                    kontext(v)
                    parteienUndOptionen(v)
                    aktionen(v)
                    if let h = hinweis {
                        Text(h).font(.system(size: 11)).foregroundStyle(InterfacePalette.vorgeschlagen)
                    }
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(InterfacePalette.Material.l1))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(InterfacePalette.trennlinie, lineWidth: 1))
            .onAppear { lade(v) }
            .onChange(of: v.id) { _, _ in lade(v) }
        }
    }
    private func kontext(_ v: Vorgang) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                feld("Titel", text: $titel)
                feld("Rechtsgebiet", text: $gebiet)
                feld("Streitwert €", text: $volumenText)
            }
            TextField("Sachverhalt", text: $beschreibung, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(InterfacePalette.Material.l3))
            Button("Sachverhalt speichern") {
                store.setzeKontext(v.id, titel: titel, beschreibung: beschreibung, rechtsgebiet: gebiet,
                                   volumen: parseZahl(volumenText))
                hinweis = "Sachverhalt gespeichert."
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(InterfacePalette.aktion)
        }
    }
    private func parteienUndOptionen(_ v: Vorgang) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("PARTEI").font(.system(size: 9, weight: .semibold)).kerning(0.4).foregroundStyle(InterfacePalette.sekundaer)
                HStack {
                    feld("Rolle", text: $parteiRolle)
                    feld("Name", text: $parteiName)
                    Button("Hinzufügen") {
                        guard !parteiName.isEmpty else { return }
                        store.fuegeParteiHinzu(v.id, rolle: parteiRolle, name: parteiName)
                        parteiName = ""
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(InterfacePalette.aktion)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("OPTION").font(.system(size: 9, weight: .semibold)).kerning(0.4).foregroundStyle(InterfacePalette.sekundaer)
                HStack {
                    feld("Label", text: $optLabel)
                    feld("P", text: $optP)
                    feld("Best", text: $optBest)
                    feld("Worst", text: $optWorst)
                    feld("Kosten", text: $optKosten)
                    Button("Hinzufügen") {
                        guard !optLabel.isEmpty else { return }
                        store.fuegeOptionAusEingabe(
                            v.id,
                            label: optLabel,
                            p: parseZahl(optP) ?? 0.5,
                            best: parseZahl(optBest) ?? 0,
                            worst: parseZahl(optWorst) ?? 0,
                            kosten: parseZahl(optKosten) ?? 0
                        )
                        optLabel = ""
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(InterfacePalette.aktion)
                }
            }
        }
    }
    private func aktionen(_ v: Vorgang) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                aktion("Bewerten", erlaubt: v.aktiveOptionen.count >= 1) {
                    store.bewerteAlleOptionen(v.id)
                    hinweis = "Formelkaskade geschrieben — nicht die KI."
                }
                aktion("Empfehlung + Gegenprobe", erlaubt: v.aktiveOptionen.contains { $0.bewertung.rav != nil }) {
                    store.bewerteAlleOptionen(v.id)
                    store.setzeEmpfehlung(v.id)
                    hinweis = store.vorgang(v.id)?.empfehlung?.gegenprobe
                }
                aktion("Ins Portfolio", erlaubt: v.zustand.reihenfolge >= VorgangZustand.bewertet.reihenfolge) {
                    store.nimmInsPortfolio(v.id, programmId: v.id)
                    hinweis = "Im Portfolio sichtbar, sobald bewertet."
                }
            }
            if v.zustand.reihenfolge >= VorgangZustand.bewertet.reihenfolge, v.entscheidung == nil {
                HStack {
                    TextField("Abweichungsgrund (falls nicht die Empfehlung)", text: $abweichung)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(InterfacePalette.Material.l3))
                    Text("Option in der Linse mit »Diese wählen« festlegen.")
                        .font(.system(size: 11))
                        .foregroundStyle(InterfacePalette.sekundaer)
                }
            }
            if v.entscheidung != nil, v.ergebnis == nil {
                HStack {
                    feld("Ist-Kosten", text: $realKosten)
                    feld("Monate", text: $realMonate)
                    feld("Ausgang", text: $realAusgang)
                    aktion("Abschließen") {
                        store.schliesseAb(v.id, ergebnis: .init(
                            realKosten: parseZahl(realKosten) ?? 0,
                            realDauerMonate: Int(parseZahl(realMonate) ?? 0),
                            realAusgang: realAusgang.isEmpty ? "ohne Angabe" : realAusgang
                        ), wer: "Nutzer")
                        hinweis = "Ergebnis eingetragen — Kalibrierung."
                    }
                }
            }
        }
    }
    private func aktion(_ titel: String, erlaubt: Bool = true, _ run: @escaping () -> Void) -> some View {
        Button(action: run) {
            Text(titel)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(erlaubt ? InterfacePalette.aktion.opacity(0.22) : InterfacePalette.Material.l3))
                .foregroundStyle(erlaubt ? Premium.text : InterfacePalette.sekundaer)
        }
        .buttonStyle(.plain)
        .disabled(!erlaubt)
    }
    private func feld(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased()).font(.system(size: 8, weight: .bold)).kerning(0.3).foregroundStyle(InterfacePalette.sekundaer)
            TextField(label, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 6).fill(InterfacePalette.Material.l3))
        }
    }
    private func lade(_ v: Vorgang) {
        titel = v.titel
        gebiet = v.rechtsgebiet
        volumenText = v.volumen == 0 ? "" : String(Int(v.volumen))
        beschreibung = v.beschreibung
    }
    private func parseZahl(_ s: String) -> Double? {
        let t = s.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        return Double(t)
    }
}
enum VorgangExport {
    static func speichern(_ v: Vorgang) {
        let text = Formelkaskade.exportText(v)
        let panel = NSSavePanel()
        panel.title = "Vorgang exportieren"
        panel.nameFieldStringValue = "\(v.kurzId).txt"
        panel.allowedContentTypes = [.plainText, .pdf]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if url.pathExtension.lowercased() == "pdf" {
            try? pdf(text: text).write(to: url)
        } else {
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    private static func pdf(text: String) -> Data {
        let font = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        let attr = NSAttributedString(string: text, attributes: [.font: font])
        let framesetter = CTFramesetterCreateWithAttributedString(attr)
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let doc = PDFDocument()
        var chunk = ""
        var n = 0
        for line in text.components(separatedBy: "\n") {
            if (chunk + line).count > 3200 {
                doc.insert(seite(framesetter, chunk, pageRect), at: n); n += 1; chunk = line + "\n"
            } else { chunk += line + "\n" }
        }
        if !chunk.isEmpty { doc.insert(seite(framesetter, chunk, pageRect), at: n) }
        return doc.dataRepresentation() ?? Data(text.utf8)
    }
    private static func seite(_ framesetter: CTFramesetter, _ text: String, _ rect: CGRect) -> PDFPage {
        let path = CGPath(rect: rect.insetBy(dx: 40, dy: 40), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        let data = NSMutableData()
        var box = rect
        guard let consumer = CGDataConsumer(data: data),
              let ctx = CGContext(consumer: consumer, mediaBox: &box, nil) else { return PDFPage() }
        ctx.beginPDFPage(nil)
        CTFrameDraw(frame, ctx)
        ctx.endPDFPage(); ctx.closePDF()
        return PDFDocument(data: data as Data)?.page(at: 0) ?? PDFPage()
    }
}
