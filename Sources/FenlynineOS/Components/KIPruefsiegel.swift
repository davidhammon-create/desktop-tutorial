import SwiftUI
import FenlynineOSKern

// MARK: - KI-Prüfsiegel
//
// Zeigt in der Kopfleiste, wie die letzte KI-Antwort die Nachprüfung
// bestanden hat, und listet auf Klick die Hinweise. Bewusst mit
// Systemfarben gebaut, damit es in Apple, Noir und Atelier gleich lesbar ist.

extension KIPruefbericht.Stufe {
    var farbe: Color {
        switch self {
        case .sauber: return .green
        case .pruefen: return .orange
        case .auffaellig: return .red
        }
    }
    var symbol: String {
        switch self {
        case .sauber: return "checkmark.shield.fill"
        case .pruefen: return "exclamationmark.shield.fill"
        case .auffaellig: return "xmark.shield.fill"
        }
    }
    var bezeichnung: String {
        switch self {
        case .sauber: return "Geprüft"
        case .pruefen: return "Bitte prüfen"
        case .auffaellig: return "Auffällig"
        }
    }
}

struct KIPruefsiegelButton: View {
    @ObservedObject private var store = KIPruefberichtStore.shared
    @State private var offen = false

    var body: some View {
        Button { offen.toggle() } label: {
            HStack(spacing: 5) {
                Image(systemName: store.letzter?.stufe.symbol ?? "shield")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(store.letzter?.stufe.farbe ?? Color.secondary)
                if store.offeneHinweise > 0 {
                    Text("\(store.offeneHinweise)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.primary)
                }
            }
            .frame(minWidth: 28, minHeight: 28)
            .padding(.horizontal, store.offeneHinweise > 0 ? 6 : 0)
            .background(Capsule().fill(Color.primary.opacity(0.10)))
        }
        .buttonStyle(.plain)
        .help("KI-Prüfung: Normzitate, Beträge und zitierte Entscheidungen der letzten KI-Antworten")
        .popover(isPresented: $offen, arrowEdge: .bottom) {
            KIPruefberichtListe()
                .frame(width: 420, height: 460)
        }
    }
}

struct KIPruefberichtListe: View {
    @ObservedObject private var store = KIPruefberichtStore.shared
    @AppStorage(KIVeredelung.pseudonymisierungKey) private var pseudonymisierung = true
    @AppStorage(KIVeredelung.antwortpruefungKey) private var antwortpruefung = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("KI-Prüfung")
                    .font(.system(size: 17, weight: .bold))
                Text("Jede KI-Antwort wird ohne KI nachgeprüft: Gibt es die zitierten Paragraphen, stammen die Beträge aus Ihren Daten, welche Entscheidungen hat das Modell selbst beigesteuert.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            Divider()
            if store.berichte.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "shield")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.secondary)
                    Text("Noch keine KI-Antwort in dieser Sitzung")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(store.berichte) { bericht in
                            KIPruefberichtZeile(bericht: bericht)
                            Divider().padding(.leading, 16)
                        }
                    }
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $pseudonymisierung) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Namen vor Cloud-Versand ersetzen")
                            .font(.system(size: 12, weight: .medium))
                        Text("Namen, Kontaktdaten und eigene Aktenzeichen gehen als Platzhalter an die Cloud-KI. Hochgeladene Dateien sind davon nicht erfasst.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Toggle(isOn: $antwortpruefung) {
                    Text("KI-Antworten nachprüfen")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .padding(16)
        }
    }
}

struct KIPruefberichtZeile: View {
    let bericht: KIPruefbericht
    @State private var aufgeklappt = false

    private var zeit: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "HH:mm"
        return f.string(from: bericht.erstelltAm)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                if !bericht.hinweise.isEmpty { aufgeklappt.toggle() }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: bericht.stufe.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(bericht.stufe.farbe)
                        .frame(width: 18)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(bericht.modul)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                            Spacer()
                            Text(zeit)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        Text(bericht.kurztext)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if bericht.pseudonymisierteAngaben > 0 {
                            Label("\(bericht.pseudonymisierteAngaben) Angaben pseudonymisiert gesendet",
                                  systemImage: "eye.slash")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !bericht.hinweise.isEmpty {
                        Image(systemName: aufgeklappt ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 3)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if aufgeklappt {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(bericht.hinweise, id: \.self) { hinweis in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•").foregroundStyle(.secondary)
                            Text(hinweis)
                                .font(.system(size: 11))
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(.leading, 28)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
