import SwiftUI
import EventKit

struct EinstellungenView: View {
@EnvironmentObject var authManager: AuthManager
@State private var ki = KIKonfiguration.shared
@State private var base44Config = Base44Config.load()
@AppStorage("fenlynineos_einstellungen_tab") private var selectedTab = "ki"

var body: some View {
  HStack(spacing: 0) {
    List(selection: $selectedTab) {
      Label("Konto & Abo", systemImage: "person.crop.circle.badge.checkmark").tag("konto")
      Label("Design & Erscheinungsbild", systemImage: "paintpalette.fill").tag("design")
      Label("KI-Konfiguration", systemImage: "brain").tag("ki")
      Label("Rechtsordnungen", systemImage: "globe.europe.africa.fill").tag("recht")
      Label("Daten-Souveränität", systemImage: "checkmark.shield.fill").tag("souveraen")
      Label("Marktvergleich", systemImage: "chart.bar.xaxis").tag("markt")
      Label("Verbindung (Base44)", systemImage: "server.rack").tag("api")
      Label("Benachrichtigungen", systemImage: "bell").tag("notifications")
      Label("Kalender", systemImage: "calendar").tag("calendar")
      Label("Datenschutz", systemImage: "lock.shield").tag("datenschutz")
      Label("Updates", systemImage: "arrow.triangle.2.circlepath").tag("updates")
      Label("Über FenlynineOS", systemImage: "info.circle").tag("ueber")
      // ADDITIV -- nur für Administrator sichtbar
      if KontoStore.shared.istAdmin {
        Label("Quellcode (Admin)", systemImage: "chevron.left.forwardslash.chevron.right").tag("admincode")
      }
    }
    .listStyle(.sidebar)
    .scrollContentBackground(.hidden)
    .frame(width: 220)
    .visionOSGlass(cornerRadius: 0, elevated: false)

    ScrollView {
      switch selectedTab {
      case "konto": KontoEinstellungenView()
      case "design": DesignEinstellungenView()
      case "ki": KIEinstellungenView(ki: $ki)
      case "recht": RechtsordnungenEinstellungenView()
      case "souveraen": SouveraenitaetView()
      case "markt": MarktvergleichView()
      case "api": APIEinstellungenView(config: $base44Config)
      case "notifications": BenachrichtigungsEinstellungenView()
      case "calendar": KalenderEinstellungenView()
      case "datenschutz": DatenschutzView()
      case "updates": UpdatePanelView()
      case "ueber": UeberFenlynineOSView()
      case "admincode":
        // ADDITIV -- Admin-Code-Archiv (nur hinzugefügt)
        AdminCodeArchivView()
      default: EmptyView()
      }
    }
    .frame(maxWidth: .infinity)
  }
  .navigationTitle("Einstellungen")
}
}

// MARK: - Design-Einstellungen

struct DesignEinstellungenView: View {
@Bindable private var design = FenlynineOSDesignStore.shared
@Bindable private var appearance = AppearanceStore.shared

var body: some View {
  VStack(alignment: .leading, spacing: 24) {
    VStack(alignment: .leading, spacing: 10) {
      Text("Appearance · systemweit")
        .font(.headline)
        .foregroundStyle(Premium.text)
      Text("Noir = OLED/Entscheidung · Atelier = hell/filigran (Apple-Stil für KI-Darstellung)")
        .font(.caption)
        .foregroundStyle(Premium.textSoft)
      HStack(spacing: 12) {
        AppearanceToggle()
        Toggle("Folgt Systemhelligkeit", isOn: $appearance.folgtSystem)
          .toggleStyle(.switch)
          .font(.system(size: 12))
      }
      Text(appearance.modus.untertitel)
        .font(.caption2)
        .foregroundStyle(Premium.textFaint)
    }
    Divider().opacity(0.3)
    DesignPresetPicker()
    Divider().opacity(0.3)
    FenlynineOSHintergrundPicker(store: design)
    Divider().opacity(0.3)
    FenlynineOSDesignModellPicker(store: design)
    Divider().opacity(0.3)
    Toggle("Tutorial beim Start anzeigen", isOn: Binding(
      get: { UserDefaults.standard.object(forKey: "fenlynineos_tutorial_aktiv") as? Bool ?? true },
      set: { UserDefaults.standard.set($0, forKey: "fenlynineos_tutorial_aktiv") }
    ))
    .font(.system(size: 12))
    Button("Tutorial jetzt starten") {
      NotificationCenter.default.post(name: .oeffneTutorial, object: nil)
   }
   .buttonStyle(.bordered)
 }
 .padding(24)
 .frame(maxWidth: .infinity, alignment: .leading)
}
}

// MARK: - KI-Einstellungen

struct KIEinstellungenView: View {
@Binding var ki: KIKonfiguration
@State private var healthResults: [KIHealthResult] = []
@State private var healthRunning = false

var body: some View {
 Form {
   Section("KI-Anbieter") {
     Picker("Modus", selection: $ki.modus) {
       ForEach(KIModus.allCases, id: \.self) {
         Text($0.bezeichnung).tag($0)
       }
     }

     if ki.modus == .offline {
       TextField("Offline-KI URL", text: $ki.offlineURL)
       TextField("Modell-Name", text: $ki.offlineModell)
       Text("Unterstützte Modelle: llama3, mistral, phi3, gemma, codellama")
         .font(.caption)
         .foregroundStyle(Premium.textSoft)
     }
   }

   Section("Apple Intelligence (on-device)") {
     let status = AppleIntelligenceService.status
     HStack(spacing: 8) {
       Image(systemName: status.ok ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
         .foregroundStyle(status.ok ? .green : .orange)
       VStack(alignment: .leading, spacing: 2) {
         Text(status.titel)
           .font(.system(size: 12, weight: .semibold))
         Text(status.hinweis)
           .font(.caption)
           .foregroundStyle(Premium.textSoft)
           .fixedSize(horizontal: false, vertical: true)
       }
     }
     Label("Immer aktuell: Das Modell ist Teil von macOS und wird mit jedem System-Update automatisch auf die neueste Version gebracht -- die App nutzt stets den aktuellsten Stand.",
        systemImage: "arrow.triangle.2.circlepath")
       .font(.caption)
       .foregroundStyle(Premium.textSoft)
     Label("Datenschutz: Verarbeitung vollständig auf diesem Mac -- keine Cloud, keine Übertragung, keine KI-Kosten.",
        systemImage: "lock.shield")
       .font(.caption)
       .foregroundStyle(Premium.textSoft)
     if status.ok && ki.modus != .appleIntelligence {
       Button {
         ki.modus = .appleIntelligence
       } label: {
         Label("Apple Intelligence als KI-Anbieter aktivieren", systemImage: "sparkles")
       }
     }
   }

   Section("Modell-Override (nur Base44)") {
     TextField("Modell (leer = Standard)", text: Binding(
       get: { ki.modellOverride ?? "" },
       set: { ki.modellOverride = $0.isEmpty ? nil : $0 }
     ))
     Text("Standard: claude-sonnet-4-6. Override nur für Tests.")
       .font(.caption)
       .foregroundStyle(Premium.textSoft)
   }

   Section("KI-Verbindungstest") {
     Text("Prüft alle drei Produktionsmodelle (Claude, Gemini, GPT-5) über Base44.")
       .font(.caption)
       .foregroundStyle(Premium.textSoft)
     Button {
       Task {
         healthRunning = true
         healthResults = await KIHealthCheck.runAll()
         healthRunning = false
       }
     } label: {
       if healthRunning {
         ProgressView().scaleEffect(0.7)
         Text("Teste Modelle…")
       } else {
         Label("Alle KI-Modelle testen", systemImage: "network")
       }
     }
     .disabled(healthRunning || ki.modus != .base44)
     ForEach(healthResults) { r in
       HStack {
         Image(systemName: r.ok ? "checkmark.circle.fill" : "xmark.circle.fill")
           .foregroundStyle(r.ok ? .green : .red)
         Text(r.modell).font(.caption.monospaced())
         Spacer()
         Text("\(r.latencyMs) ms").font(.caption2).foregroundStyle(Premium.textSoft)
       }
       if !r.ok {
         Text(r.message).font(.caption2).foregroundStyle(.red)
       }
     }
   }

   Section("Pro-Modul API (optional)") {
     Text("Standard: alle Module nutzen die globale Anbindung oben. Pro Modul können Sie eine eigene Offline-URL / ein eigenes Modell setzen.")
       .font(.caption)
       .foregroundStyle(Premium.textSoft)
     KIModulAnbindungenEditor()
   }

   Section {
     Button("Einstellungen speichern") {
       ki.save()
       KIKonfiguration.syncShared(from: ki)
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
   }
 }
 .formStyle(.grouped)
 .padding(20)
 .navigationTitle("KI-Konfiguration")
}
}

// MARK: - API-Einstellungen

struct APIEinstellungenView: View {
@Binding var config: Base44Config
@EnvironmentObject var authManager: AuthManager

var body: some View {
 VStack(alignment: .leading, spacing: 20) {
   OnboardingVerbindungsStatusView(
     appId: config.appId,
     baseUrl: config.appBaseUrl,
     schritt: 1
   )

   if authManager.geraeteModusAktiv {
     GroupBox {
       VStack(alignment: .leading, spacing: 8) {
         Label("Geräte-Modus aktiv", systemImage: "desktopcomputer")
           .font(.headline)
         Text("Dieser Mac ist Ihr Account. Alle Fälle werden lokal gespeichert.")
           .font(.caption)
           .foregroundStyle(Premium.textSoft)
         LabeledContent("Geräte-ID") {
           Text(DeviceIdentity.id)
             .font(.system(.caption, design: .monospaced))
             .textSelection(.enabled)
         }
         LabeledContent("Speicherort") {
           Text(DeviceIdentity.datenVerzeichnis.path)
             .font(.caption2)
             .textSelection(.enabled)
             .lineLimit(2)
         }
         Button("Datenordner im Finder öffnen") {
           NSWorkspace.shared.open(DeviceIdentity.datenVerzeichnis)
         }
         .buttonStyle(.link)
       }
       .padding(4)
     }
   }

   if authManager.isAuthenticated {
     Label("Angemeldet als \(authManager.userName)", systemImage: "person.circle.fill")
       .font(.subheadline)
       .foregroundStyle(Premium.textSoft)
   }

   Form {
     Section("Base44 (nur KI & Server-Funktionen)") {
       TextField("App-ID", text: $config.appId)
       TextField("App-Base-URL", text: $config.appBaseUrl)
       SecureField("Access-Token (optional)", text: Binding(
         get: { config.accessToken ?? "" },
         set: { config.accessToken = $0.isEmpty ? nil : $0 }
       ))
     }

     Section {
       Button("Verbindung speichern") {
         Task {
           await Base44Client.shared.updateConfig(config)
         }
       }
       .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     }
   }
   .formStyle(.grouped)
 }
 .padding(20)
}
}

// MARK: - Benachrichtigungs-Einstellungen

struct BenachrichtigungsEinstellungenView: View {
@StateObject private var service = NotificationService.shared
@State private var vorlauffrist = 3
@State private var zweiteErinnerung = true

var body: some View {
 Form {
   Section("Status") {
     HStack {
       Text("Benachrichtigungen")
       Spacer()
       Image(systemName: service.benachrichtigungsZugriff ? "checkmark.circle.fill" : "xmark.circle.fill")
         .foregroundStyle(service.benachrichtigungsZugriff ? .green : .red)
       Text(service.benachrichtigungsZugriff ? "Aktiviert" : "Deaktiviert")
         .foregroundStyle(Premium.textSoft)
     }
   }

   Section("Frist-Erinnerungen") {
     Stepper("Vorlauffrist: \(vorlauffrist) Tage", value: $vorlauffrist, in: 1...14)
     Toggle("Zweite Erinnerung (1 Tag vorher)", isOn: $zweiteErinnerung)
   }

   if !service.benachrichtigungsZugriff {
     Section {
       Button("Systemeinstellungen öffnen") {
         NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
       }
     }
   }
 }
 .formStyle(.grouped)
 .padding(20)
}
}

// MARK: - Kalender-Einstellungen

struct KalenderEinstellungenView: View {
@StateObject private var service = NotificationService.shared

var body: some View {
 Form {
   Section("Kalender-Integration") {
     HStack {
       Text("Kalender-Zugriff")
       Spacer()
       Image(systemName: service.kalenderZugriff ? "checkmark.circle.fill" : "xmark.circle.fill")
         .foregroundStyle(service.kalenderZugriff ? .green : .red)
       Text(service.kalenderZugriff ? "Freigegeben" : "Gesperrt")
         .foregroundStyle(Premium.textSoft)
     }

     if service.kalenderZugriff {
       Text("Fristen können direkt in Kalender.app eingetragen werden (automatisch mit Alarm).")
         .font(.caption)
         .foregroundStyle(Premium.textSoft)
     } else {
       Button("Kalender-Zugriff freigeben") {
         Task { await service.berechtigungenAnfordern() }
       }
       .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     }
   }
 }
 .formStyle(.grouped)
 .padding(20)
}
}

// MARK: - Datenschutz-View

struct DatenschutzView: View {
var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   Text("Datenschutz & Compliance")
     .font(.title3.bold())

   DatenschutzAbschnitt(
     titel: "Datenspeicherung",
     inhalt: "Falldaten werden lokal auf diesem Mac gespeichert (Application Support/FenlynineOS). API-Zugriffstoken und Gerätegeheimnisse liegen in der macOS-Keychain. KI-Anfragen werden an das konfigurierte Base44-Backend gesendet."
   )

   DatenschutzAbschnitt(
     titel: "KI-Verarbeitung",
     inhalt: "KI-Analysen werden über die Base44-Cloud (Claude Sonnet) verarbeitet. Bei Offline-Modus werden Daten an den konfigurierten lokalen Server übertragen. Keine Daten werden an Dritte weitergegeben."
   )

   DatenschutzAbschnitt(
     titel: "EU AI Act Compliance",
     inhalt: "FenlynineOS entspricht den Anforderungen des EU AI Acts (Art. 13 -- Transparenz). Jede KI-Ausgabe enthält eine Erklärung der Entscheidungsgrundlage."
   )

   DatenschutzAbschnitt(
     titel: "DSGVO",
     inhalt: "Personenbezogene Daten (Mandanten, Richter) werden gemäß DSGVO Art. 6 Abs. 1 lit. b (Vertragserfüllung) verarbeitet. Auskunftsrecht jederzeit auf Anfrage."
   )
 }
 .padding(20)
}
}

struct DatenschutzAbschnitt: View {
let titel: String
let inhalt: String

var body: some View {
 VStack(alignment: .leading, spacing: 6) {
   Text(titel)
     .font(.system(size: 13, weight: .semibold))
   Text(inhalt)
     .font(.system(size: 12))
     .foregroundStyle(Premium.textSoft)
 }
 .padding(12)
 .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
}
}

// MARK: - Über FenlynineOS

struct UeberFenlynineOSView: View {
private var version: String {
 Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.5.0"
}
private var build: String {
 Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "31"
}
private var displayName: String { AppDefaults.produktNameVoll }

var body: some View {
 VStack(spacing: 20) {
   Image(systemName: "scale.3d")
     .font(.system(size: 56))
     .foregroundStyle(.blue)

   VStack(spacing: 6) {
     Text(displayName)
       .font(.system(size: 22, weight: .bold, design: .rounded))
       .multilineTextAlignment(.center)
     Text(AppDefaults.produktUntertitel)
       .font(.subheadline)
       .foregroundStyle(Premium.textSoft)
     Text("by \(AppDefaults.hersteller)")
       .font(.caption)
       .foregroundStyle(Premium.textSoft)
     Text("Version \(version) (Build \(build))")
       .font(.caption)
       .foregroundStyle(.tertiary)
     Text("macOS 14+ Sonoma -- Native SwiftUI")
       .font(.caption2)
       .foregroundStyle(.tertiary)
   }

   Divider()

   VStack(alignment: .leading, spacing: 8) {
     InfoZeile(label: "Technologie", wert: "Swift 5.9 · SwiftUI · Swift Charts · Core Spotlight")
     InfoZeile(label: "Backend", wert: "Base44 BaaS · Deno Serverless Functions")
     InfoZeile(label: "KI", wert: "Claude Sonnet 4.6 (cloud) / Ollama (offline)")
     InfoZeile(label: "Algorithmen", wert: "Bayesianische Inferenz · Monte-Carlo (SIMD)")
     InfoZeile(label: "Daten-Modelle", wert: "20 Entities · RLS-gesichert")
   }
   .padding(16)
   .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
 }
 .padding(24)
}
}

struct InfoZeile: View {
let label: String
let wert: String

var body: some View {
 HStack {
   Text(label + ":")
     .font(.system(size: 12))
     .foregroundStyle(Premium.textSoft)
     .frame(width: 120, alignment: .leading)
   Text(wert)
     .font(.system(size: 12, weight: .medium))
 }
}
}

