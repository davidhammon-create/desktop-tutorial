import SwiftUI
import AppKit
struct KontoAnmeldungView: View {
    @ObservedObject private var store = KontoStore.shared
    @State private var modusRegistrieren = false
    @State private var name = ""
    @State private var email = ""
    @State private var passwort = ""
    @State private var passwort2 = ""
    private var ersteinrichtung: Bool { store.ersteinrichtungNoetig }
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 26) {
                VStack(spacing: 8) {
                    Text("FENLYNINEOS LEGAL SUITE")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Premium.action)
                    Text(ersteinrichtung
                         ? "Ersteinrichtung — Administrator-Konto anlegen"
                         : (modusRegistrieren ? "Neues Konto registrieren" : "Anmelden"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Premium.textSoft)
                }
                VStack(spacing: 10) {
                    if ersteinrichtung || modusRegistrieren {
                        feld("Name", text: $name, symbol: "person")
                    }
                    feld("E-Mail", text: $email, symbol: "envelope")
                    passwortFeld("Passwort", text: $passwort)
                    if ersteinrichtung || modusRegistrieren {
                        passwortFeld("Passwort wiederholen", text: $passwort2)
                    }
                    if let fehler = store.fehler {
                        Text(fehler)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Premium.critical)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(width: 320)
                VStack(spacing: 10) {
                    Button(action: absenden) {
                        Text(ersteinrichtung ? "Administrator-Konto anlegen"
                             : (modusRegistrieren ? "Konto erstellen" : "Anmelden"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Premium.onAction)
                            .frame(width: 320, height: 38)
                            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Premium.action))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                    if !ersteinrichtung {
                        Button {
                            store.fehler = nil
                            modusRegistrieren.toggle()
                        } label: {
                            Text(modusRegistrieren ? "Zurück zur Anmeldung" : "Neues Konto registrieren")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Premium.textSoft)
                        }
                        .buttonStyle(.plain)
                    }
                }
                VStack(spacing: 4) {
                    if ersteinrichtung {
                        Text("Das erste Konto erhält Administrator-Rechte und die Stufe „Imperium“ — kostenfrei.")
                    } else if modusRegistrieren {
                        Text("Neue Konten starten in der Stufe „Basis“ (kostenlos). Upgrades schaltet der Administrator frei.")
                    }
                    Text("Alle Kontodaten bleiben lokal auf diesem Gerät. Passwörter werden nur als Hash gespeichert (DSGVO).")
                }
                .font(.system(size: 10))
                .foregroundStyle(Premium.textFaint)
                .multilineTextAlignment(.center)
                .frame(width: 360)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Premium.void)
    }
    private func absenden() {
        if ersteinrichtung || modusRegistrieren {
            guard passwort == passwort2 else {
                store.fehler = "Die Passwörter stimmen nicht überein."
                return
            }
            store.registrieren(name: name, email: email, passwort: passwort)
        } else {
            store.anmelden(email: email, passwort: passwort)
        }
    }
    private func feld(_ titel: String, text: Binding<String>, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 11))
                .foregroundStyle(Premium.textFaint)
                .frame(width: 16)
            TextField(titel, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Premium.panel))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Premium.hairline, lineWidth: 1))
    }
    private func passwortFeld(_ titel: String, text: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "key")
                .font(.system(size: 11))
                .foregroundStyle(Premium.textFaint)
                .frame(width: 16)
            SecureField(titel, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Premium.panel))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Premium.hairline, lineWidth: 1))
    }
}
struct AboGateView: View {
    let eintrag: SeitenleistenEintrag
    var body: some View {
        AboPaywallView(eintrag: eintrag)
    }
}
struct KontoEinstellungenView: View {
    @ObservedObject private var store = KontoStore.shared
    @State private var altesPasswort = ""
    @State private var neuesPasswort = ""
    @State private var passwortMeldung: String?
    @State private var zeigeLoeschDialog = false
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let konto = store.aktuellesKonto {
                HStack(spacing: 14) {
                    Text(String(konto.name.prefix(1)).uppercased())
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Premium.onAction)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(konto.plan.akzent))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(konto.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Premium.text)
                        Text(konto.email)
                            .font(.system(size: 11))
                            .foregroundStyle(Premium.textSoft)
                        HStack(spacing: 6) {
                            abzeichen(konto.plan.titel, farbe: konto.plan.akzent)
                            abzeichen(konto.plan.fensterAnzahlText, farbe: Premium.textSoft)
                            if konto.istAdmin {
                                abzeichen("Administrator · KI kostenfrei", farbe: Premium.computed)
                            }
                        }
                    }
                    Spacer()
                    Button("Abmelden") { store.abmelden() }
                        .buttonStyle(.bordered)
                }
                Divider().opacity(0.3)
                AboFensterUebersichtView()
                Divider().opacity(0.3)
                VStack(alignment: .leading, spacing: 10) {
                    Text("KI-Nutzung — laufender Monat")
                        .font(.headline)
                        .foregroundStyle(Premium.text)
                    HStack(spacing: 12) {
                        kennzahl("Aufrufe", "\(store.monatsAufrufe(kontoId: konto.id))")
                        kennzahl("Kosten", String(format: "%.2f €", store.monatsKosten(kontoId: konto.id)))
                        if let budget = konto.kiBudgetMonat {
                            kennzahl("Budget", String(format: "%.2f €", budget))
                        }
                    }
                    let letzte = Array(store.verbrauch(kontoId: konto.id).prefix(8))
                    if letzte.isEmpty {
                        Text("Noch keine KI-Nutzung in diesem Konto.")
                            .font(.system(size: 11))
                            .foregroundStyle(Premium.textFaint)
                    } else {
                        VStack(spacing: 1) {
                            ForEach(letzte) { e in
                                HStack {
                                    Text(e.datum.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(Premium.textFaint)
                                        .frame(width: 130, alignment: .leading)
                                    Text("\(e.modul) · \(e.aktion)")
                                        .font(.system(size: 10.5))
                                        .foregroundStyle(Premium.textSoft)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(String(format: "%.2f €", e.kosten))
                                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(Premium.text)
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Premium.panel.opacity(0.5)))
                            }
                        }
                    }
                }
                Divider().opacity(0.3)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Passwort ändern")
                        .font(.headline)
                        .foregroundStyle(Premium.text)
                    HStack(spacing: 8) {
                        SecureField("Aktuelles Passwort", text: $altesPasswort)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                        SecureField("Neues Passwort (min. 8)", text: $neuesPasswort)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                        Button("Ändern") {
                            if store.passwortAendern(alt: altesPasswort, neu: neuesPasswort) {
                                passwortMeldung = "Passwort geändert."
                                altesPasswort = ""; neuesPasswort = ""
                            } else {
                                passwortMeldung = store.fehler
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    if let meldung = passwortMeldung {
                        Text(meldung)
                            .font(.system(size: 11))
                            .foregroundStyle(meldung == "Passwort geändert." ? Premium.computed : Premium.critical)
                    }
                }
                Divider().opacity(0.3)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Datenschutz (DSGVO)")
                        .font(.headline)
                        .foregroundStyle(Premium.text)
                    Text("Kontodaten und KI-Nutzungsprotokoll liegen ausschließlich lokal auf diesem Gerät. Passwörter werden nur als Salted-Hash gespeichert.")
                        .font(.system(size: 11))
                        .foregroundStyle(Premium.textSoft)
                    HStack(spacing: 10) {
                        Button("Meine Daten exportieren (Art. 15/20)") {
                            exportiereEigeneDaten(konto: konto)
                        }
                        .buttonStyle(.bordered)
                        Button("Konto löschen (Art. 17)", role: .destructive) {
                            zeigeLoeschDialog = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .confirmationDialog(
                    "Konto und alle zugehörigen Daten unwiderruflich löschen?",
                    isPresented: $zeigeLoeschDialog
                ) {
                    Button("Unwiderruflich löschen", role: .destructive) {
                        store.kontoLoeschen(kontoId: konto.id)
                    }
                    Button("Abbrechen", role: .cancel) {}
                }
            } else {
                Text("Nicht angemeldet.")
                    .foregroundStyle(Premium.textSoft)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    private func exportiereEigeneDaten(konto: Konto) {
        guard let json = store.datenExport(kontoId: konto.id) else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Datenauskunft-\(konto.email).json"
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            try? json.data(using: .utf8)?.write(to: url)
        }
    }
    private func abzeichen(_ text: String, farbe: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(farbe)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(farbe.opacity(0.12)))
    }
    private func kennzahl(_ titel: String, _ wert: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(titel.uppercased())
                .font(.system(size: 8.5, weight: .bold))
                .kerning(0.5)
                .foregroundStyle(Premium.textFaint)
            Text(wert)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Premium.text)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 9).fill(Premium.panel.opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Premium.hairline, lineWidth: 1))
    }
}
