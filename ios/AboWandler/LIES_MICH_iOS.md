# AboWandler für iOS & macOS (Swift/SwiftUI)

Native Portierung der AboWandler-App — komplett in **Swift** (SwiftUI), lauffähig auf
**iPhone, iPad und Mac** aus einem einzigen Projekt.

## Was drin ist

- **Konten & Umsätze**: Anbieter-Katalog (Sparkasse, PayPal, Klarna, Amex, ING, DKB, N26 …),
  CSV/Text-Import mit 30-Sekunden-Exportanleitung pro Bank. Banking-Passwörter werden nie abgefragt.
- **Algorithmus-Scanner (ohne KI)**: identische Logik wie die Web-App — wiederholte IBANs,
  Namen, Betreffe, regelmäßige Intervalle & Beträge; Preiserhöhungs- und Verdachts-Erkennung.
- **Abos verwalten**: Status, Pausieren, Kündigungs-Direktlinks (Kündigungsbutton-Gesetz),
  geführter Sparplan-Flow mit Broker-Links und 3-Punkte-Checkliste.
- **Investieren**: Anlage-Universum (ETFs, Aktien, Anleihen, Rohstoffe, Mixe), Rechner mit
  Chart, Prognose & Renten-Boost.
- **Finanz-Radar**: Alltags-Taktiken (Kredite, Währungen, Immobilien, Steuern & Erben, …).
- **Apple Intelligence**: KI-Funktionen laufen über das **FoundationModels-Framework**
  komplett **on-device** — kostenlos, ohne API-Schlüssel, deine Daten verlassen das Gerät nicht.
  (Seriositäts-Einschätzung, Kündigungsschreiben, Anlage-Einordnung.)

## Voraussetzungen

- **Xcode 16 oder neuer** auf einem Mac (kostenlos im Mac App Store).
- Fürs Bauen/Testen reicht der iOS-Simulator; fürs eigene iPhone genügt ein kostenloses
  Apple-Entwicklerkonto (Xcode → Settings → Accounts → Apple-ID hinzufügen).
- **Apple Intelligence** (die KI-Funktionen) braucht **iOS 26 / macOS 26** auf einem
  Apple-Intelligence-fähigen Gerät (iPhone 15 Pro oder neuer, M-Serie-Macs). Auf älteren
  Geräten läuft die App vollständig — nur die KI-Buttons melden sich als nicht verfügbar.

## Öffnen & Starten

1. Ordner entpacken.
2. `AboWandler.xcodeproj` doppelklicken (öffnet Xcode).
3. Oben Zielgerät wählen (iPhone-Simulator oder „My Mac“).
4. ▶︎ drücken. Fertig.

Falls Xcode beim Signieren meckert: Projekt anklicken → Target „AboWandler“ →
„Signing & Capabilities“ → bei „Team“ deine Apple-ID wählen.

## Ehrliche Hinweise

- **Dieses Projekt wurde in einer Linux-Cloud-Umgebung geschrieben und konnte dort nicht
  kompiliert werden** (Xcode existiert nur auf macOS). Der Code nutzt bewusst
  Standard-APIs — kleinere Anpassungen durch Xcode sind aber möglich.
- Das On-Device-Modell von Apple Intelligence hat **keinen Internetzugang**: Es kann
  einschätzen und formulieren, aber nicht live im Web recherchieren. Für Web-Recherche
  (Firmenberichte mit Quellen, aktuelle Kreditzinsen) nutze die Web-App mit Anthropic-Key.
- Falls das Projekt in einer älteren Xcode-Version nicht öffnet: Neues iOS-App-Projekt
  „AboWandler" (SwiftUI) anlegen und alle `.swift`-Dateien aus `AboWandler/` hineinziehen.
