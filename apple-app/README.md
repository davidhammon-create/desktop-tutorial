# LegalOS – Native Apple-App (iOS + macOS)

LegalOS ist eine SwiftUI-Multiplatform-App (iOS 17+, macOS 14+), die die bestehende
React/BASE44-Webapp 1:1 in einer nativen Apple-Umgebung nachbildet. Es werden
**ausschließlich Apple-eigene Technologien** verwendet – kein BASE44, keine
externen SPM-Packages.

## Architektur

| Bereich          | Technologie                                                  |
|------------------|--------------------------------------------------------------|
| UI               | SwiftUI 5 (`NavigationSplitView`, `TabView`, `Charts`)       |
| Datenhaltung     | CloudKit (`CKContainer.default()`, Public + Private DB)      |
| Auth             | Eigene Email/Passwort-Auth (SHA256+Salt, CryptoKit) +        |
|                  | Sign in with Apple (`AuthenticationServices`)                |
| Session-Storage  | Keychain (`SecItemAdd/Copy/Delete`)                          |
| KI               | Anthropic Claude API – direkter HTTPS-Call, Modell           |
|                  | `claude-sonnet-4-6`                                          |
| Async            | Strikt `async/await`, `URLSession.shared.data(for:)`         |

## Voraussetzungen

- Xcode 15.4 oder neuer
- Aktiver Apple-Developer-Account (für CloudKit + Sign in with Apple)
- Anthropic API-Key

## Schritt-für-Schritt Setup in Xcode

### 1. Neues Multiplatform-Projekt anlegen

1. **Xcode öffnen → Datei → Neu → Projekt** (`⇧⌘N`)
2. Reiter **Multiplatform** wählen.
3. Vorlage **App** wählen → *Weiter*.
4. Felder:
   - **Product Name:** `LegalOS`
   - **Team:** Dein Apple-Developer-Team
   - **Organization Identifier:** z.B. `de.deinefirma`
   - **Bundle Identifier:** ergibt sich daraus, z.B. `de.deinefirma.LegalOS`
   - **Interface:** *SwiftUI*
   - **Language:** *Swift*
   - **Storage:** *None* (kein SwiftData / CoreData – wir nutzen CloudKit)
5. Speicherort wählen → *Erstellen*.

### 2. Quelldateien einbinden

1. Im Finder den Ordner `apple-app/LegalOS/` öffnen.
2. **Alle Unterordner (`Models`, `Services`, `Views`, `Resources`) gleichzeitig
   markieren** und in den Project-Navigator von Xcode **direkt unter den
   Hauptgruppen-Ordner `LegalOS` ziehen**.
3. Im Dialog:
   - "Copy items if needed" **aktivieren**.
   - "Create groups" **aktivieren** (nicht „Folder references“).
   - Target **`LegalOS`** ankreuzen.
4. Die zwei `Info.plist`/`LegalOS.entitlements`-Dateien in den Project-Settings
   später als *Info Plist File* / *Code Signing Entitlements* zuweisen
   (siehe Schritt 4).

### 3. Capabilities aktivieren

Im Target **`LegalOS`** → Reiter **Signing & Capabilities** → `+ Capability`:

1. **iCloud**
   - Häkchen bei *CloudKit*.
   - Container hinzufügen: `iCloud.<deine.bundle.id>` (z.B.
     `iCloud.de.deinefirma.LegalOS`).
   - Diesen Identifier auch in `Resources/Info.plist` und
     `Resources/LegalOS.entitlements` eintragen (Platzhalter
     `iCloud.com.example.legalos` ersetzen).
2. **Sign in with Apple**
   - Einfach hinzufügen, keine weiteren Einstellungen nötig.
3. **Keychain Sharing** (optional)
   - Falls Bestandteil deiner Apple-Suite.

### 4. Info.plist und Entitlements verknüpfen

- **Build Settings → Info.plist File:** auf `LegalOS/Resources/Info.plist` setzen.
- **Build Settings → Code Signing Entitlements:** auf
  `LegalOS/Resources/LegalOS.entitlements` setzen.
- Im **Deployment Info** (Target → General):
  - iOS-Mindestversion: **17.0**
  - macOS-Mindestversion: **14.0**

### 5. Anthropic API-Key hinterlegen

Beim ersten App-Start gehst du in **Module & Einstellungen** und trägst deinen
Anthropic API-Key ein. Er wird im **Keychain** (sicher) und parallel als
Convenience-Kopie in `UserDefaults` abgelegt.

API-Konfiguration ist in `Services/ClaudeAPIService.swift` zentralisiert:

- Endpoint: `https://api.anthropic.com/v1/messages`
- Header: `x-api-key: <KEY>`, `anthropic-version: 2023-06-01`
- Default-Modell: `claude-sonnet-4-6`

### 6. Bauen & Starten

1. Schema **`LegalOS`** auswählen (mac- oder iOS-Simulator / Gerät).
2. **`⌘R`** – die App startet mit dem Login-Screen.
3. Konto registrieren oder „Mit Apple anmelden“.
4. Onboarding durchlaufen (Jurisdiktion + NDA).
5. Loslegen.

## Projektstruktur

```
LegalOS/
├── LegalOSApp.swift          – @main, RootView, EnvironmentObjects
├── Models/                   – Entities (Codable + CloudKit-Mapping)
├── Services/
│   ├── AuthService.swift      – Email/PW + Sign in with Apple
│   ├── CloudKitService.swift  – generisches CRUD
│   ├── ClaudeAPIService.swift – Anthropic-Client
│   ├── KIProvider.swift       – invokeLLM(prompt, schema)
│   └── LegalAlgorithms.swift  – Prognose / Vergleichsempfehlung
├── Views/
│   ├── Auth/                 – Login, Register, Onboarding
│   ├── Shell/                – AppShell, SidebarView
│   ├── Pages/                – 16 Haupt-Screens (1:1 zu src/pages/)
│   └── Components/           – DSGVOBanner, JurisdictionToggle, KICreditsBadge
└── Resources/
    ├── Info.plist
    └── LegalOS.entitlements
```

## Mapping React-Page → SwiftUI-View

| React (`src/pages/`)        | SwiftUI                                          |
|-----------------------------|--------------------------------------------------|
| `Home.jsx`                  | `Views/Pages/HomeView.swift`                     |
| `LexaraDashboard.jsx`       | `Views/Pages/LexaraDashboardView.swift`          |
| `CaseDetail.jsx`            | `Views/Pages/CaseDetailView.swift`               |
| `Strategos.jsx`             | `Views/Pages/StrategosView.swift`                |
| `FallAssistentChat.jsx`     | `Views/Pages/FallAssistentChatView.swift`        |
| `Zeitleiste.jsx`            | `Views/Pages/ZeitleisteView.swift`               |
| `MandantenView.jsx`         | `Views/Pages/MandantenView.swift`                |
| `Aufgaben.jsx`              | `Views/Pages/AufgabenView.swift`                 |
| `KanzleiCockpit.jsx`        | `Views/Pages/KanzleiCockpitView.swift`           |
| `KanzleiAnalytik.jsx`       | `Views/Pages/KanzleiAnalytikView.swift`          |
| `KICompliance.jsx`          | `Views/Pages/KIComplianceView.swift`             |
| `Modules.jsx`               | `Views/Pages/ModulesView.swift`                  |
| `PlattformAgent.jsx`        | `Views/Pages/PlattformAgentView.swift`           |
| `RichterProfile.jsx`        | `Views/Pages/RichterProfileView.swift`           |
| `SunTzuMachiavel.jsx`       | `Views/Pages/SunTzuMachiavelView.swift`          |
| `OnboardingSetup.jsx`       | `Views/Auth/OnboardingView.swift`                |

## Tests im CloudKit-Dashboard

Nach dem ersten Speichern (z.B. neuer Fall) müssen in
[CloudKit Console](https://icloud.developer.apple.com/dashboard/) ggf. **Indizes**
hinzugefügt werden:

- `Case` → recordName **QUERYABLE**
- `Argument`, `Evidence`, `Person`, `Deadline`, `TimelineEvent` →
  `case_id` **QUERYABLE**
- `User` → `email` **QUERYABLE**, `apple_user_id` **QUERYABLE**
- Für jeden Typ `creationDate` **SORTABLE** (zur Sortierung im Service).

## Lizenz

Privat – nicht zur Weitergabe bestimmt.
