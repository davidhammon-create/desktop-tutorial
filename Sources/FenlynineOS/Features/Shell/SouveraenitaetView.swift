import SwiftUI
import AppKit
struct SouveraenitaetView: View {
    @ObservedObject private var residenz = DatenResidenzStore.shared
    @ObservedObject private var poweros = PowerOSDatenbank.shared
    @ObservedObject private var teilen = WissensTeilenManager.shared
    @State private var remoteUpdates = FenlynineOSSicherheitsHaertung.remoteUpdatesErlaubt
    @State private var iCloudChat = FenlynineOSSicherheitsHaertung.iCloudChatErlaubt
    var body: some View {
        Form {
            Section("Sicherheitsstatus (Offline-first)") {
                Text("\(AppDefaults.produktName) läuft lokal auf diesem Mac. Die Trust-Boundary ist Ihr Benutzerkonto + FileVault. Cloud, Remote-Updates und iCloud-Sync sind standardmäßig gesperrt — nur bewusste Freigaben öffnen Egress.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(Array(FenlynineOSSicherheitsHaertung.statusZeilen.enumerated()), id: \.offset) { _, zeile in
                    LabeledContent(zeile.0) {
                        Text(zeile.1)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(zeile.2 ? Color.green : Color.orange)
                    }
                }
                Toggle(isOn: $remoteUpdates) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remote-Updates erlauben")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Standard: AUS. Verhindert stilles Ersetzen der App-Binary über das Netz. Lokale Update-Pakete (file://) bleiben möglich.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .onChange(of: remoteUpdates) { _, neu in
                    FenlynineOSSicherheitsHaertung.remoteUpdatesErlaubt = neu
                }
                Toggle(isOn: $iCloudChat) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud-Chat-Sync")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Standard: AUS. Chats bleiben nur in der lokalen App-Sandbox / auf diesem Mac.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .onChange(of: iCloudChat) { _, neu in
                    FenlynineOSSicherheitsHaertung.iCloudChatErlaubt = neu
                }
            }
            Section("Daten-Residenz (KI-Infrastruktur)") {
                Text("Diese Schicht sitzt vor JEDEM KI-Aufruf und erzwingt, dass Daten nur über Server der gewählten Region fließen — oder das Gerät gar nicht verlassen. Verstößt der konfigurierte Anbieter dagegen, wird automatisch auf on-device KI umgeleitet. Jede Entscheidung wird revisionssicher protokolliert (DSGVO Art. 30, § 203 StGB, § 43e BRAO).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Region", selection: $residenz.region) {
                    ForEach(Residenzregion.allCases) { r in
                        Label(r.titel, systemImage: r.symbol).tag(r)
                    }
                }
                .pickerStyle(.inline)
                Text(residenz.region.beschreibung)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle(isOn: $residenz.base44Ausnahme) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Base44 als Auftragsverarbeiter zulassen (Übergangs-Ausnahme)")
                            .font(.system(size: 12, weight: .semibold))
                        Text(residenz.region == .nurLokal
                             ? "Bei „Nur dieses Gerät“ wirkungslos — Cloud bleibt vollständig gesperrt."
                             : "Aus = strikte Durchsetzung: Cloud-Aufrufe außerhalb der Region werden auf Apple Intelligence / lokale Modelle umgeleitet.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .disabled(residenz.region == .nurLokal)
                LabeledContent("Aktueller Status") {
                    Label(DatenResidenz.statusLabel, systemImage: residenz.region.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(residenz.region == .weltweit ? Color.orange : Color.green)
                }
            }
            Section("PowerOS-Rechtsdatenbank (ständige KI-Sammlung)") {
                Text("Der Rechtsradar und die KIs sammeln fortlaufend Rechtsinformationen über alle aktiven Rechtsordnungen und speichern sie als SQLite-Datenbank + lesbaren Spiegel im PowerOS-Ordner.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LabeledContent("Ordner") {
                    Text(poweros.pfad.path)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                }
                LabeledContent("Einträge in der Datenbank") { Text("\(poweros.anzahlEintraege)") }
                LabeledContent("Sammel-Protokolle") { Text("\(poweros.anzahlLog)") }
                if let sync = poweros.letzterSync {
                    LabeledContent("Letzter Sync") { Text(sync.formatted(date: .abbreviated, time: .shortened)) }
                }
                LabeledContent("Status") { Text(poweros.status) }
                HStack(spacing: 10) {
                    Button {
                        poweros.synchronisiere()
                        poweros.protokolliere(aktion: "Manueller Sync", details: "aus Einstellungen ausgelöst")
                    } label: { Label("Jetzt synchronisieren", systemImage: "arrow.triangle.2.circlepath") }
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([poweros.pfad])
                    } label: { Label("PowerOS-Ordner öffnen", systemImage: "folder") }
                }
            }
            Section("Wissens-Teilen (Opt-in — Ihre Entscheidung)") {
                Toggle(isOn: $teilen.teilenAktiv) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ich möchte Rechtswissen beitragen")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Standard: AUS. Ohne Opt-in wird nichts geteilt — alles bleibt lokal. Jederzeit widerrufbar. Es geht ausschließlich um Rechtswissen (Normen, Urteile, Muster) — niemals um Mandantendaten.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                HStack(spacing: 10) {
                    Button {
                        teilen.beitragHochladen()
                    } label: { Label("Dokumente/Pakete hochladen", systemImage: "square.and.arrow.up.on.square") }
                    .disabled(!teilen.teilenAktiv)
                    Button {
                        teilen.wissenspaketExportieren()
                    } label: { Label("Wissenspaket exportieren", systemImage: "shippingbox") }
                }
                if !teilen.status.isEmpty {
                    Text(teilen.status).font(.caption).foregroundStyle(.secondary)
                }
                LabeledContent("Bisher beigetragen") { Text("\(teilen.beitraege) Datei(en)") }
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
    }
}
struct MarktvergleichView: View {
    private struct Zeile: Identifiable {
        let id = UUID()
        let merkmal: String
        let fenlynineOS: String
        let logicc: String
        let harvey: String
        let clio: String
        let jupus: String
    }
    private let zeilen: [Zeile] = [
        .init(merkmal: "Datensouveränität",
              fenlynineOS: "On-device-KI möglich: Daten verlassen das Gerät GAR NICHT. Wählbare Residenz (DE/EU/CH) mit erzwungener Umleitung + Audit.",
              logicc: "Hosting in Deutschland, DSGVO-konform, kein Modelltraining",
              harvey: "US-Cloud (OpenAI-Partnerschaft), Enterprise-Verträge",
              clio: "Nordamerikanische Cloud, DSGVO via AVV",
              jupus: "EU-Hosting"),
        .init(merkmal: "Substanzielle Rechts-KI",
              fenlynineOS: "Lexara (Analyse) · Strategos (Strategie) · Opportunisma (Chancen) · Fenylaw Strategies · Rechenwerk mit offengelegten Formeln (EV, VaR, Monte-Carlo, ZOPA)",
              logicc: "Multi-Modell-Chat + Dokumentanalyse (kein Fach-Workflow)",
              harvey: "Research, Due Diligence, Drafting (Enterprise)",
              clio: "Nur Verwaltungs-KI (Abrechnung, Zusammenfassungen)",
              jupus: "Keine — Intake/Workflow-Automatisierung"),
        .init(merkmal: "Transparenz der KI",
              fenlynineOS: "Jede Zahl mit Herkunft (QuellenInfo): Formel, Datenquelle oder KI-Modell offengelegt — Anwälte MÜSSEN der KI nicht glauben, sie können nachrechnen",
              logicc: "Modellauswahl sichtbar (Smart Select)",
              harvey: "Blackbox mit interner Validierung",
              clio: "Blackbox",
              jupus: "n/a"),
        .init(merkmal: "Mehrrechtsordnungen",
              fenlynineOS: "DE · CH · NO · JP · CN kuratiert (Fristen, Gebühren, Gerichte, Zitierregeln) + Funktions-Union über Grenzen + rechtsvergleichende KI-Antworten",
              logicc: "Keine Rechtsordnungs-Logik",
              harvey: "Multi-Jurisdiktion (v. a. Common Law, Enterprise)",
              clio: "US/CA/UK-fokussiert",
              jupus: "DE-fokussiert"),
        .init(merkmal: "Kanzlei-Betrieb",
              fenlynineOS: "Vorgänge, Fristen-Kaskaden, RVG, Zeiterfassung, Abrechnung, Konten/Abos, Admin-Zentrale — integriert, lokal",
              logicc: "Nein (reine KI-Plattform)",
              harvey: "Nein (reine KI)",
              clio: "Ja (Kernprodukt, Cloud)",
              jupus: "Teilweise (Intake)"),
        .init(merkmal: "Wissensdatenbank",
              fenlynineOS: "PowerOS: ständige KI-Sammlung in lokale SQLite-DB + Rechtsdaten-Ordner auf jedem Rechner + Opt-in-Teilen",
              logicc: "Eigene Assistenten auf Kanzleidokumenten",
              harvey: "Firm-Knowledge (Enterprise-Setup)",
              clio: "Nur Falldaten",
              jupus: "Nein"),
        .init(merkmal: "Selbstheilung & Wartung",
              fenlynineOS: "Selbstreparatur-Agent: Health-Scans, Snapshots, KI-Failover, Beschwerdekanal — einzigartig",
              logicc: "Nein", harvey: "Nein", clio: "Nein", jupus: "Nein"),
        .init(merkmal: "Mobile Ergänzung",
              fenlynineOS: "iOS-Companion: Foto-Upload, Diktat, Kombi-KI-Routing (Lexara/Strategos/Opportunisma automatisch)",
              logicc: "Web-App", harvey: "Web", clio: "Mobile App", jupus: "Web"),
        .init(merkmal: "Preisniveau",
              fenlynineOS: "Lokal, Abo-Stufen frei kalkulierbar; KI-Kosten transparent je Konto gemessen",
              logicc: "29,90–89,90 €/Monat/Nutzer",
              harvey: "≈ 1.000 $+/Platz/Monat, 20-Platz-Minimum",
              clio: "39–139 $/Monat/Nutzer",
              jupus: "Auf Anfrage")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Marktvergleich — warum \(AppDefaults.produktName) führt")
                .font(.system(size: 16, weight: .bold))
            Text("Basis: Marktrecherche Stand August 2026 (Anbieter-Websites und Fachanalysen). \(AppDefaults.produktNameVoll) kombiniert, was sonst 4 getrennte Produkte erfordert — und setzt bei Datensouveränität und Transparenz Standards, die kein Wettbewerber bietet.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(zeilen) { z in
                VStack(alignment: .leading, spacing: 6) {
                    Text(z.merkmal)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Premium.action)
                    vergleichsZeile("FenlynineOS", z.fenlynineOS, stark: true)
                    vergleichsZeile("LOGICC", z.logicc)
                    vergleichsZeile("Harvey", z.harvey)
                    vergleichsZeile("Clio", z.clio)
                    vergleichsZeile("Jupus", z.jupus)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Premium.well))
            }
            Text("Hinweis: Der Vergleich dient der internen Produktsteuerung. Angaben zu Drittanbietern nach bestem Wissen; Preise/Funktionen können sich ändern.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    private func vergleichsZeile(_ name: String, _ text: String, stark: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(name)
                .font(.system(size: 11, weight: stark ? .bold : .semibold))
                .foregroundStyle(stark ? Premium.text : Premium.textSoft)
                .frame(width: 64, alignment: .leading)
            Text(text)
                .font(.system(size: 11, weight: stark ? .medium : .regular))
                .foregroundStyle(stark ? Premium.text : Premium.textSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
