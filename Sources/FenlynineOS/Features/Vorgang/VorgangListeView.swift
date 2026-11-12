import SwiftUI
struct VorgangListeView: View {
    @Bindable var store: VorgangStore = .shared
    @State private var filterTyp: VorgangTyp? = nil
    @State private var filterZustand: VorgangZustand? = nil
    @State private var suche: String = ""
    @State private var neuerTyp: VorgangTyp = .streit
    @State private var neuerTitel: String = ""
    @State private var zeigeNeu = false
    @State private var kommandofeldOffen = false
    @State private var offenerVorgang: VorgangIdWrap? = nil
    private var gefiltert: [Vorgang] {
        var l = store.vorgaenge
        if let t = filterTyp { l = l.filter { $0.typ == t } }
        if let z = filterZustand { l = l.filter { $0.zustand == z } }
        if !suche.isEmpty { l = store.suche(suche) }
        return l.sorted { $0.geaendert > $1.geaendert }
    }
    var body: some View {
        VStack(spacing: 0) {
            filterLeiste
            liste
        }
        .background(InterfacePalette.Material.l0)
        .sheet(isPresented: $zeigeNeu) { neuerVorgangSheet }
        .sheet(isPresented: $kommandofeldOffen) {
            Kommandofeld { v in
                offenerVorgang = VorgangIdWrap(id: v.id)
            }
            .presentationBackground(.clear)
        }
        .sheet(item: $offenerVorgang) { wrap in
            VorgangAnsichtView(vorgangId: wrap.id)
                .frame(minWidth: 900, minHeight: 700)
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: .oeffneKommandofeld, object: nil, queue: .main) { _ in
                kommandofeldOffen = true
            }
        }
    }
    private var filterLeiste: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("Vorgänge")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Premium.text)
                Text("\(store.vorgaenge.count)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(InterfacePalette.sekundaer)
                Spacer()
                Button {
                    kommandofeldOffen = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                        Text("⌘K")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 8).fill(InterfacePalette.Material.l2))
                    .foregroundStyle(InterfacePalette.sekundaer)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("k", modifiers: [.command])
                Button {
                    zeigeNeu = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Neuer Vorgang")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 8).fill(InterfacePalette.aktion))
                    .foregroundStyle(Premium.text)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("n", modifiers: [.command])
            }
            HStack(spacing: 8) {
                filterChip(alle: "Alle Typen", aktiv: filterTyp == nil) { filterTyp = nil }
                ForEach(VorgangTyp.allCases) { t in
                    filterChip(t.bezeichnung, aktiv: filterTyp == t, symbol: t.linsenSymbol) {
                        filterTyp = filterTyp == t ? nil : t
                    }
                }
                Divider().frame(height: 20).overlay(InterfacePalette.trennlinie)
                filterChip(alle: "Alle Zustände", aktiv: filterZustand == nil) { filterZustand = nil }
                ForEach([VorgangZustand.erfasst, .strukturiert, .bewertet, .entschieden, .laufend, .abgeschlossen]) { z in
                    filterChip(z.bezeichnung, aktiv: filterZustand == z) {
                        filterZustand = filterZustand == z ? nil : z
                    }
                }
                Spacer()
            }
        }
        .padding(16)
        .background(InterfacePalette.Material.l1)
    }
    private func filterChip(_ label: String? = nil, alle: String? = nil, aktiv: Bool, symbol: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let s = symbol {
                    Image(systemName: s).font(.system(size: 9))
                }
                Text(label ?? alle ?? "")
                    .font(.system(size: 11, weight: .semibold))
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .foregroundStyle(aktiv ? .white : InterfacePalette.sekundaer)
            .background(RoundedRectangle(cornerRadius: 6).fill(aktiv ? InterfacePalette.aktion.opacity(0.24) : Color.clear))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(InterfacePalette.trennlinie, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
    private var liste: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(gefiltert) { v in
                    zeile(v)
                        .onTapGesture { offenerVorgang = VorgangIdWrap(id: v.id) }
                }
            }
            .padding(.vertical, 4)
        }
    }
    private func zeile(_ v: Vorgang) -> some View {
        HStack(spacing: 12) {
            Image(systemName: v.typ.linsenSymbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(InterfacePalette.aktion)
                .frame(width: 20)
            Circle().fill(zustandFarbe(v.zustand)).frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(v.titel).font(.system(size: 13, weight: .semibold)).foregroundStyle(Premium.text).lineLimit(1)
                HStack(spacing: 8) {
                    Text(v.kurzId).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(InterfacePalette.sekundaer)
                    Text(v.rechtsgebiet).font(.system(size: 10)).foregroundStyle(InterfacePalette.sekundaer)
                    if let p = v.parteien.first { Text(p.name).font(.system(size: 10)).foregroundStyle(InterfacePalette.sekundaer) }
                }
            }
            Spacer()
            if let ev = v.optionen.first(where: { !$0.istVorgeschichte })?.bewertung.ev {
                WertBadge(wert: ev, groesseText: 13, fett: true)
            }
            if let f = v.fristen.min(by: { $0.tageBisAblauf < $1.tageBisAblauf }) {
                Text("\(f.tageBisAblauf) T")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(f.tageBisAblauf < 14 ? InterfacePalette.kritisch : InterfacePalette.sekundaer)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 0).fill(Premium.well.opacity(0.5)))
        .contentShape(Rectangle())
    }
    private func zustandFarbe(_ z: VorgangZustand) -> Color {
        switch z {
        case .erfasst:       return InterfacePalette.sekundaer
        case .strukturiert:  return InterfacePalette.vorgeschlagen
        case .bewertet:      return InterfacePalette.aktion
        case .entschieden:   return InterfacePalette.berechnet
        case .laufend:       return InterfacePalette.aktion
        case .abgeschlossen: return InterfacePalette.sekundaer
        }
    }
    private var neuerVorgangSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Neuer Vorgang").font(.system(size: 17, weight: .semibold)).foregroundStyle(Premium.text)
            VStack(alignment: .leading, spacing: 6) {
                Text("TYP").font(.system(size: 10, weight: .semibold)).kerning(0.4).foregroundStyle(InterfacePalette.sekundaer)
                HStack(spacing: 6) {
                    ForEach(VorgangTyp.allCases) { t in
                        Button {
                            neuerTyp = t
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: t.linsenSymbol).font(.system(size: 10))
                                Text(t.bezeichnung).font(.system(size: 11, weight: .semibold))
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .foregroundStyle(neuerTyp == t ? .white : InterfacePalette.sekundaer)
                            .background(RoundedRectangle(cornerRadius: 6).fill(neuerTyp == t ? InterfacePalette.aktion.opacity(0.24) : InterfacePalette.Material.l2))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("TITEL").font(.system(size: 10, weight: .semibold)).kerning(0.4).foregroundStyle(InterfacePalette.sekundaer)
                TextField("z.B. Alpha Holdings — Steuerstruktur", text: $neuerTitel)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(Premium.text)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(InterfacePalette.Material.l3))
            }
            HStack {
                Spacer()
                Button("Abbrechen") { zeigeNeu = false }
                    .buttonStyle(.plain)
                    .foregroundStyle(InterfacePalette.sekundaer)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                Button {
                    let v = store.neu(typ: neuerTyp, titel: neuerTitel.isEmpty ? "Neuer Vorgang" : neuerTitel)
                    zeigeNeu = false
                    offenerVorgang = VorgangIdWrap(id: v.id)
                    neuerTitel = ""
                } label: {
                    Text("Anlegen")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 8).fill(InterfacePalette.aktion))
                        .foregroundStyle(Premium.text)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 480)
        .background(InterfacePalette.Material.l1)
    }
}
struct VorgangIdWrap: Identifiable, Equatable {
    let id: UUID
}
extension Notification.Name {
    static let oeffneKommandofeld = Notification.Name("fenlynineos.vorgang.kommandofeld")
}
