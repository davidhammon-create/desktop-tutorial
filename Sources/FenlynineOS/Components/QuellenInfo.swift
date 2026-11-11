import SwiftUI
struct QuellenAuskunft {
    enum Art {
        case formel      // deterministischer Algorithmus
        case ki          // Sprachmodell
        case quelle      // Gesetz / Rechtsprechung
        case lokal       // Gerätedaten (eigene Eingaben)
        var titel: String {
            switch self {
            case .formel: return "Deterministische Formel"
            case .ki:     return "KI-Sprachmodell"
            case .quelle: return "Gesetz / Rechtsprechung"
            case .lokal:  return "Lokale Gerätedaten"
            }
        }
        var symbol: String {
            switch self {
            case .formel: return "function"
            case .ki:     return "sparkles"
            case .quelle: return "books.vertical"
            case .lokal:  return "internaldrive"
            }
        }
        var farbe: Color {
            switch self {
            case .formel: return Premium.computed
            case .ki:     return Premium.proposed
            case .quelle: return Premium.mute
            case .lokal:  return Premium.action
            }
        }
        var haftungshinweis: String {
            switch self {
            case .formel:
                return "Reproduzierbar: identische Eingaben → identisches Ergebnis. Prüfen Sie die Eingaben, nicht die Rechnung."
            case .ki:
                return "Unbestätigter Vorschlag eines Sprachmodells. Fundstellen und Normen zwingend anwaltlich prüfen — Sie haften."
            case .quelle:
                return "Aus Norm oder Entscheidung übernommen. Aktualität der Fundstelle prüfen."
            case .lokal:
                return "Stammt aus Ihren eigenen Eingaben auf diesem Gerät. Keine externe Übertragung."
            }
        }
    }
    var art: Art
    var was: String
    var wie: String
    var datenbasis: String? = nil
    static func formel(_ was: String, formel: String, datenbasis: String? = nil) -> QuellenAuskunft {
        .init(art: .formel, was: was, wie: formel, datenbasis: datenbasis)
    }
    static func ki(_ was: String, modell: String = "Base44 · Claude Sonnet 4.6 (oder Offline-Modell laut Einstellungen)", datenbasis: String? = nil) -> QuellenAuskunft {
        .init(art: .ki, was: was, wie: modell, datenbasis: datenbasis)
    }
    static func quelle(_ was: String, fundstelle: String) -> QuellenAuskunft {
        .init(art: .quelle, was: was, wie: fundstelle)
    }
    static func lokal(_ was: String, basis: String) -> QuellenAuskunft {
        .init(art: .lokal, was: was, wie: basis)
    }
}
struct QuellenInfo: View {
    let auskunft: QuellenAuskunft
    var groesse: CGFloat = 12
    @State private var offen = false
    var body: some View {
        Button {
            offen.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: groesse, weight: .medium))
                .foregroundStyle(Premium.textFaint)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Herkunft & Berechnungsweg anzeigen")
        .popover(isPresented: $offen, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 7) {
                    Image(systemName: auskunft.art.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(auskunft.art.farbe)
                    Text(auskunft.art.titel.uppercased())
                        .font(.system(size: 9.5, weight: .black))
                        .kerning(0.6)
                        .foregroundStyle(auskunft.art.farbe)
                }
                zeile("Was", auskunft.was)
                zeile(auskunft.art == .ki ? "Modell" : (auskunft.art == .quelle ? "Fundstelle" : "Formel"), auskunft.wie)
                if let basis = auskunft.datenbasis {
                    zeile("Datenbasis", basis)
                }
                Divider().opacity(0.4)
                Text(auskunft.art.haftungshinweis)
                    .font(.system(size: 10))
                    .foregroundStyle(Premium.textSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(width: 320, alignment: .leading)
        }
    }
    private func zeile(_ titel: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titel.uppercased())
                .font(.system(size: 8.5, weight: .bold))
                .kerning(0.5)
                .foregroundStyle(Premium.textFaint)
            Text(text)
                .font(.system(size: 11.5, design: titel == "Formel" ? .monospaced : .default))
                .foregroundStyle(Premium.text)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
