import SwiftUI
import FenlynineOSKern

// MARK: - ProfilAuswahlView
//
// Zentrale Profilauswahl: Der Nutzer sieht eine Kachelansicht mit allen verfügbaren
// Profilen, wählt eines, und die App blendet nur die zugehörigen Module ein.
// Pflichtmodule (Fristen, Berufspflichten, Einstellungen) bleiben immer erreichbar.

struct ProfilAuswahlView: View {
    @EnvironmentObject var appState: AppState
    @State private var ausgewaehltesProfil: String = "vollzugriff"
    @State private var zeigeEigenesProfil = false
    @State private var eigenesProfilName = ""
    @State private var wechselFehler: String?
    @State private var erfolgsmeldung: String?

    private let spalten = [
        GridItem(.adaptive(minimum: 260, maximum: 340), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                profilRaster
                if let fehler = wechselFehler { fehlerBanner(fehler) }
                if let erfolg = erfolgsmeldung { erfolgsBanner(erfolg) }
                verbundInfo
                eigeneProfilSektion
            }
            .padding(24)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Arbeitsprofil wählen")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(FenlynineOSTheme.textPrimary)
            Text("Jedes Profil zeigt nur die Module, die Sie für diese Aufgabe brauchen. "
               + "Die übrigen Module werden ausgeblendet, nicht gelöscht — Ihre Daten "
               + "bleiben vollständig erhalten.")
                .font(.system(size: 13))
                .foregroundStyle(FenlynineOSTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Profilkacheln

    private var profilRaster: some View {
        LazyVGrid(columns: spalten, spacing: 16) {
            ForEach(Nutzungsprofil.alleStandard) { profil in
                ProfilKachel(
                    profil: profil,
                    istAktiv: profil.id == ausgewaehltesProfil,
                    aktion: { profilWechseln(zu: profil.id) }
                )
            }
        }
    }

    // MARK: - Verbund-Info

    @ViewBuilder
    private var verbundInfo: some View {
        if let profil = Nutzungsprofil.alleStandard.first(where: { $0.id == ausgewaehltesProfil }),
           !profil.verbuende.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Modulverbünde in „\(profil.titel)"")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(FenlynineOSTheme.textPrimary)
                Text("Diese Module arbeiten zusammen: Wählen Sie einen Fall in einem Modul, "
                   + "sehen die anderen automatisch denselben Kontext.")
                    .font(.system(size: 12))
                    .foregroundStyle(FenlynineOSTheme.textSecondary)

                ForEach(profil.verbuende) { verbund in
                    VerbundZeile(verbund: verbund)
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(FenlynineOSTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(FenlynineOSTheme.border, lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Eigenes Profil

    private var eigeneProfilSektion: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                zeigeEigenesProfil.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(FenlynineOSTheme.accent)
                    Text("Eigenes Profil aus aktuellem Zustand erstellen")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(FenlynineOSTheme.textPrimary)
                }
            }
            .buttonStyle(.plain)

            if zeigeEigenesProfil {
                HStack(spacing: 12) {
                    TextField("Profilname", text: $eigenesProfilName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 240)
                    Button("Erstellen") {
                        eigeneProfilErstellen()
                    }
                    .disabled(eigenesProfilName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.leading, 28)
            }
        }
    }

    // MARK: - Feedback

    private func fehlerBanner(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
            Text(text).font(.system(size: 12))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private func erfolgsBanner(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            Text(text).font(.system(size: 12))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Aktionen

    private func profilWechseln(zu profilId: String) {
        wechselFehler = nil
        erfolgsmeldung = nil
        // Der tatsächliche Wechsel läuft über den ProfilVerwalter im AppState.
        // Hier wird nur die Auswahl gesetzt; der AppState reagiert per onChange.
        withAnimation(.spring(duration: 0.3)) {
            ausgewaehltesProfil = profilId
        }
        // In der echten App: appState.profilVerwalter.wechseln(...)
        erfolgsmeldung = "Profil gewechselt."
    }

    private func eigeneProfilErstellen() {
        let name = eigenesProfilName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let id = "benutzer.\(name.lowercased().replacingOccurrences(of: " ", with: "-"))"
        // In der echten App:
        // let neues = appState.profilVerwalter.profilAusAktuellemZustand(
        //     id: id, titel: name, untertitel: "Benutzerdefiniert",
        //     symbol: "person.crop.rectangle", modell: appState.modellverwalter.aktuell)
        // appState.profilVerwalter.profilHinzufuegen(neues)
        eigenesProfilName = ""
        zeigeEigenesProfil = false
        erfolgsmeldung = "Profil „\(name)" erstellt."
    }
}

// MARK: - ProfilKachel

struct ProfilKachel: View {
    let profil: Nutzungsprofil
    let istAktiv: Bool
    let aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: profil.symbol)
                        .font(.system(size: 24))
                        .foregroundStyle(istAktiv ? .white : FenlynineOSTheme.accent)
                    Spacer()
                    if istAktiv {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                    }
                }

                Text(profil.titel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(istAktiv ? .white : FenlynineOSTheme.textPrimary)

                Text(profil.untertitel)
                    .font(.system(size: 12))
                    .foregroundStyle(istAktiv ? .white.opacity(0.85) : FenlynineOSTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    Text("\(profil.sichtbareModulIds.count) Module")
                        .font(.system(size: 11, weight: .medium))
                    if !profil.verbuende.isEmpty {
                        Text("·")
                        Text("\(profil.verbuende.count) Verbünde")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .foregroundStyle(istAktiv ? .white.opacity(0.7) : FenlynineOSTheme.textTertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(istAktiv
                          ? FenlynineOSTheme.accent.gradient
                          : FenlynineOSTheme.cardBackground.gradient)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(istAktiv ? Color.clear : FenlynineOSTheme.border, lineWidth: 1)
            }
            .shadow(color: istAktiv ? FenlynineOSTheme.accent.opacity(0.25) : .clear,
                    radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - VerbundZeile

struct VerbundZeile: View {
    let verbund: Modulverbund

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(FenlynineOSTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(verbund.titel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FenlynineOSTheme.textPrimary)

                HStack(spacing: 4) {
                    Text(verbund.leitmodulId)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(FenlynineOSTheme.accent)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9))
                        .foregroundStyle(FenlynineOSTheme.textTertiary)
                    Text(verbund.nebenmodulIds.joined(separator: ", "))
                        .font(.system(size: 11))
                        .foregroundStyle(FenlynineOSTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()

            Text(verbund.kontextTyp.rawValue.capitalized)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(FenlynineOSTheme.accent.opacity(0.1),
                            in: Capsule())
                .foregroundStyle(FenlynineOSTheme.accent)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Profil-Umschalter für die Seitenleiste

struct ProfilSchnellwahl: View {
    @Binding var aktivesProfilId: String
    @State private var aufgeklappt = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.25)) { aufgeklappt.toggle() }
            } label: {
                HStack(spacing: 8) {
                    if let profil = Nutzungsprofil.alleStandard.first(where: { $0.id == aktivesProfilId }) {
                        Image(systemName: profil.symbol)
                            .font(.system(size: 12))
                            .foregroundStyle(FenlynineOSTheme.accent)
                        Text(profil.titel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(FenlynineOSTheme.textPrimary)
                    }
                    Spacer()
                    Image(systemName: aufgeklappt ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(FenlynineOSTheme.textTertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(FenlynineOSTheme.cardBackground)
                }
            }
            .buttonStyle(.plain)

            if aufgeklappt {
                VStack(spacing: 2) {
                    ForEach(Nutzungsprofil.alleStandard) { profil in
                        Button {
                            withAnimation(.spring(duration: 0.2)) {
                                aktivesProfilId = profil.id
                                aufgeklappt = false
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: profil.symbol)
                                    .font(.system(size: 11))
                                    .frame(width: 16)
                                Text(profil.titel)
                                    .font(.system(size: 11))
                                Spacer()
                                if profil.id == aktivesProfilId {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(FenlynineOSTheme.accent)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background {
                                if profil.id == aktivesProfilId {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(FenlynineOSTheme.accent.opacity(0.1))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
