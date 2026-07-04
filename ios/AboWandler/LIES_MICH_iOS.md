# AboWandler für iOS & macOS (Swift/SwiftUI)

Die Haupt-Version von AboWandler — **Frontend UND Backend komplett in Swift**:
SwiftUI-Oberfläche im nativen Apple-Design, Datenhaltung/Scanner/Abrechnung als
Swift-Logik direkt in der App (kein separater Server nötig), Stripe-Anbindung in
reinem Swift (URLSession). Lauffähig auf **iPhone, iPad und Mac** aus einem Projekt.
Einzige Nicht-Swift-Berührungspunkte: die externe Stripe-REST-API (unvermeidbar)
und die optionale Web-App für PC/Android.

## Neu in Version 2: Profile, Abo-Modell & Stripe

- **Profile (Accounts)**: Auswahl beim Start; jedes Profil hat eigene Konten,
  Umsätze, Abos — und ein **eigenes Kosten-Ledger**.
- **Abo-Modell**: Free (nur Algorithmus, kostenlos) vs. **Pro (4,99 €/Monat)**,
  schaltet die KI-Funktionen frei. Plan-Seite im App-Store-Karten-Stil.
- **KI kostet — transparent**: Jede KI-Aktion zeigt ihren Preis am Button
  (KI-Scan 0,10 €, Seriositäts-Check 0,05 €, Kündigungsschreiben 0,05 €,
  Anlage-Einordnung 0,05 €) und landet als Einzelposten im Ledger des Profils.
- **Stripe-Pflicht**: Ohne verknüpftes Stripe-Kundenkonto (und hinterlegten
  Stripe-Schlüssel, Admin → Einstellungen) sind **alle kostenpflichtigen
  Services gesperrt**. „Jetzt abrechnen“ erzeugt eine echte Stripe-Rechnung
  (Testmodus mit sk_test_-Schlüssel empfohlen — keine echten Abbuchungen).
- **Scan-Methode wählbar**: Algorithmus (kostenlos) / KI / Beide — direkt auf
  der Übersicht umschaltbar.

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
