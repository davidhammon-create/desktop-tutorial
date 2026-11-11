import SwiftUI
struct VerhandlungLinse: View {
    let vorgangId: UUID
    @Bindable var store: VorgangStore = .shared
    @State private var gebot: Double = 18_000
    @State private var protokoll: [VerhandlungEintrag] = []
    @State private var stichwort: String = ""
    private var vorgang: Vorgang? { store.vorgang(vorgangId) }
    var body: some View {
        if let v = vorgang, let entscheidung = v.entscheidung, let gewaehlt = v.optionen.first(where: { $0.id == entscheidung.optionId }) {
            geritSaal(v, gewaehlt: gewaehlt)
        } else if let v = vorgang {
            gesperrt(v)
        } else {
            Text("Vorgang nicht gefunden").foregroundStyle(Premium.text)
        }
    }
    private func geritSaal(_ v: Vorgang, gewaehlt: VorgangOption) -> some View {
        let ev = gewaehlt.bewertung.ev?.wert ?? 0
        let schmerz = gewaehlt.bewertung.rav?.wert ?? ev * 0.9
        let differenz = gebot - ev
        let besserAlsSchmerz = gebot >= schmerz
        return VStack(spacing: 24) {
            HStack {
                Text(v.titel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(InterfacePalette.sekundaer)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "wifi.slash")
                    Text("Kein Mikrofon · Kein Netz nötig")
                }
                .font(.system(size: 10))
                .foregroundStyle(InterfacePalette.sekundaer)
            }
            VStack(spacing: 12) {
                Text("GEGENSEITE BIETET")
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(0.6)
                    .foregroundStyle(InterfacePalette.sekundaer)
                Text(InterfaceZahl.waehrung(gebot))
                    .font(.system(size: 72, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(besserAlsSchmerz ? InterfacePalette.berechnet : InterfacePalette.kritisch)
                Text(besserAlsSchmerz ? "ANNEHMEN" : "ABLEHNEN")
                    .font(.system(size: 36, weight: .black))
                    .kerning(2)
                    .foregroundStyle(besserAlsSchmerz ? InterfacePalette.berechnet : InterfacePalette.kritisch)
                Text(besserAlsSchmerz
                     ? "\(InterfaceZahl.waehrung(differenz)) ggü. EV · aber \(gewaehlt.zeit.maxMonate) Mon. früher."
                     : "\(InterfaceZahl.waehrung(differenz)) unter EV · und \(InterfaceZahl.waehrung(gebot - schmerz)) unter Schmerzgrenze.")
                    .font(.system(size: 13))
                    .foregroundStyle(InterfacePalette.sekundaer)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 16).fill(InterfacePalette.Material.l2))
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("IHR EV (Klage)").font(.system(size: 10, weight: .semibold)).kerning(0.4).foregroundStyle(InterfacePalette.sekundaer)
                    Text(InterfaceZahl.waehrung(ev)).font(.system(size: 16, weight: .semibold)).monospacedDigit().foregroundStyle(Premium.text)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("SCHMERZGRENZE").font(.system(size: 10, weight: .semibold)).kerning(0.4).foregroundStyle(InterfacePalette.sekundaer)
                    HStack(spacing: 6) {
                        Herkunftsmarke(herkunft: .formel, groesse: 7)
                        Text(InterfaceZahl.waehrung(schmerz))
                            .font(.system(size: 16, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(Premium.text)
                    }
                }
                Spacer()
            }
            HStack(spacing: 12) {
                buttonGross("−1.000", -1000)
                buttonGross("−500", -500)
                Spacer()
                buttonGross("+500", 500)
                buttonGross("+1.000", 1000)
            }
            HStack(spacing: 12) {
                Button {
                    protokolliere(v, was: "Angebot angenommen", betrag: gebot)
                } label: {
                    Text("ANNEHMEN")
                        .font(.system(size: 14, weight: .bold))
                        .kerning(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 10).fill(InterfacePalette.berechnet.opacity(0.18)))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(InterfacePalette.berechnet, lineWidth: 1.5))
                        .foregroundStyle(InterfacePalette.berechnet)
                }
                .buttonStyle(.plain)
                Button {
                    protokolliere(v, was: "Angebot abgelehnt", betrag: gebot)
                } label: {
                    Text("ABLEHNEN")
                        .font(.system(size: 14, weight: .bold))
                        .kerning(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 10).fill(InterfacePalette.kritisch.opacity(0.14)))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(InterfacePalette.kritisch, lineWidth: 1.5))
                        .foregroundStyle(InterfacePalette.kritisch)
                }
                .buttonStyle(.plain)
            }
            if !protokoll.isEmpty {
                Divider().overlay(InterfacePalette.trennlinie)
                VStack(alignment: .leading, spacing: 4) {
                    Text("PROTOKOLL (nur Zahlen · keine Mitschrift)")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(0.4)
                        .foregroundStyle(InterfacePalette.sekundaer)
                    ForEach(protokoll) { e in
                        HStack {
                            Text(e.was).font(.system(size: 11)).foregroundStyle(.white.opacity(0.75))
                            Spacer()
                            Text(InterfaceZahl.waehrung(e.betrag)).font(.system(size: 11, design: .monospaced)).foregroundStyle(InterfacePalette.sekundaer)
                        }
                    }
                }
            }
            konterBibliothek(gewaehlt)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(InterfacePalette.Material.l0)
        .onAppear {
            if gebot == 18_000, let ev = gewaehlt.bewertung.ev?.wert {
                gebot = max(0, ev)
            }
        }
    }
    private func konterBibliothek(_ option: VorgangOption) -> some View {
        let g = NexusStore.shared.graph(optionId: option.id)
        let karten = g.map { NexusPropagation.konterBibliothek(graph: $0) } ?? []
        let q = stichwort.trimmingCharacters(in: .whitespacesAndNewlines)
        let treffer = q.isEmpty ? Array(karten.prefix(1)) : karten.filter { $0.gegnerKern.localizedCaseInsensitiveContains(q) }
        return VStack(alignment: .leading, spacing: 8) {
            Text("KONTER-BIBLIOTHEK — KEIN MIKROFON · OFFLINE")
                .font(.system(size: 10, weight: .semibold))
                .kerning(0.4)
                .foregroundStyle(InterfacePalette.sekundaer)
            TextField("Zwei Stichworte zum Abgleich", text: $stichwort)
                .textFieldStyle(.plain)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(InterfacePalette.Material.l3))
            if let karte = treffer.first {
                NexusKonterKarteView(karte: karte)
            } else if karten.isEmpty {
                Text("Kein Graph — NEXUS vor dem Termin befüllen. Advocatus erzeugt keine Knoten.")
                    .font(.system(size: 12))
                    .foregroundStyle(InterfacePalette.sekundaer)
            } else {
                Text("Kein Treffer in der vorbereiteten Bibliothek.")
                    .font(.system(size: 12))
                    .foregroundStyle(InterfacePalette.sekundaer)
            }
        }
    }
    private func gesperrt(_ v: Vorgang) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(InterfacePalette.sekundaer)
                Text("Verhandlung gesperrt")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Premium.text)
            }
            Text("Wird verfügbar, sobald eine Option gewählt ist.")
                .font(.system(size: 12))
                .foregroundStyle(InterfacePalette.sekundaer)
            Text("Der Advocatus-Modus rechnet im Saal nichts Neues aus — er zeigt nur, was schon entschieden war.")
                .font(.system(size: 11))
                .foregroundStyle(InterfacePalette.sekundaer)
            Text("§ 201 StGB · § 169 GVG · KEIN MIKROFON, IN KEINER VERSION.")
                .font(.system(size: 10, weight: .semibold))
                .kerning(0.4)
                .foregroundStyle(InterfacePalette.kritisch)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(InterfacePalette.Material.l2))
        .padding(20)
    }
    private func buttonGross(_ label: String, _ delta: Double) -> some View {
        Button {
            gebot = max(0, gebot + delta)
        } label: {
            Text(label)
                .font(.system(size: 18, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Premium.text)
                .frame(width: 96, height: 60)
                .background(RoundedRectangle(cornerRadius: 12).fill(InterfacePalette.Material.l3))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(InterfacePalette.trennlinie, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
    private func protokolliere(_ v: Vorgang, was: String, betrag: Double) {
        protokoll.append(.init(was: was, betrag: betrag))
        store.protokolliereAdvocatus(v.id, was: was, betrag: betrag)
        store.setzeZustand(v.id, .laufend, wer: "Advocatus")
    }
}
struct VerhandlungEintrag: Identifiable {
    let id = UUID()
    let was: String
    let betrag: Double
}
