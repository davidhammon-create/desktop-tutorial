import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// SELBSTREPARATUR -- Dashboard des automatischen Wartungs-Agenten
// Scans · Auto-Reparaturen · Known-Good-Snapshot · Beschwerden · KI-Failover
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct SelbstreparaturView: View {
@ObservedObject private var agent = SelbstreparaturAgent.shared
@State private var beschwerdeText = ""

var body: some View {
  ScrollView {
    VStack(alignment: .leading, spacing: 16) {
      kopf
      statusKarten
      befundeBlock
      reparaturenBlock
      snapshotBlock
      beschwerdenBlock
      datenschutzBlock
    }
    .padding(20)
    .frame(maxWidth: 860, alignment: .leading)
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Color.clear)
}

// MARK: Kopf

private var kopf: some View {
  VStack(alignment: .leading, spacing: 6) {
    HStack(spacing: 10) {
      Image(systemName: "wrench.and.screwdriver.fill")
        .font(.system(size: 20))
        .foregroundStyle(Premium.action)
      Text("Selbstreparatur-Agent")
        .font(.system(size: 20, weight: .bold))
        .foregroundStyle(Premium.text)
      Spacer()
      Toggle(isOn: $agent.aktiv) {
        Text("Automatisch")
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(Premium.textSoft)
      }
      .toggleStyle(.switch)
    }
    Text("Scannt das Programm automatisch alle 15 Minuten: Datenintegrität, KI-Gesundheit, Module/Buttons, Speicher. Erkannte Probleme werden selbstständig repariert -- beschädigte Dateien aus dem Known-Good-Snapshot wiederhergestellt, ausgefallene KI-Anbieter automatisch ersetzt (Base44 « Apple Intelligence « Offline).")
      .font(.system(size: 11))
      .foregroundStyle(Premium.textSoft)
      .fixedSize(horizontal: false, vertical: true)
  }
}

// MARK: Statuskarten

private var statusKarten: some View {
  HStack(spacing: 10) {
    statusKarte("Gesundheit", "\(Int(agent.gesundheit * 100))%",
          symbol: "heart.fill",
          farbe: agent.gesundheit > 0.85 ? .green : (agent.gesundheit > 0.6 ? .orange : .red))
    statusKarte("Letzter Scan",
          agent.letzterScan.map { $0.formatted(date: .omitted, time: .shortened) } ?? "--",
          symbol: "clock.fill", farbe: Premium.action)
    statusKarte("Reparaturen", "\(agent.reparaturen.count)",
          symbol: "wrench.fill", farbe: Premium.proposed)
    statusKarte("Snapshot",
          agent.letzterSnapshot.map { $0.formatted(date: .numeric, time: .shortened) } ?? "noch keiner",
          symbol: "externaldrive.fill.badge.checkmark", farbe: Premium.computed)
    Spacer()
    Button {
      Task { await agent.scanJetzt() }
    } label: {
      Label(agent.scanLaeuft ? "Scan läuft …" : "Jetzt scannen",
         systemImage: agent.scanLaeuft ? "hourglass" : "magnifyingglass")
        .font(.system(size: 11.5, weight: .semibold))
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Premium.action))
        .foregroundStyle(Premium.onAction)
    }
    .buttonStyle(.plain)
    .disabled(agent.scanLaeuft)
  }
}

private func statusKarte(_ titel: String, _ wert: String, symbol: String, farbe: Color) -> some View {
  HStack(spacing: 8) {
    Image(systemName: symbol)
      .font(.system(size: 12))
      .foregroundStyle(farbe)
    VStack(alignment: .leading, spacing: 1) {
      Text(titel.uppercased())
        .font(.system(size: 8, weight: .black))
        .kerning(0.4)
        .foregroundStyle(Premium.textFaint)
      Text(wert)
        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
        .foregroundStyle(Premium.text)
   }
 }
 .padding(.horizontal, 12).padding(.vertical, 8)
 .background(RoundedRectangle(cornerRadius: 9).fill(Premium.panel.opacity(0.6)))
 .overlay(RoundedRectangle(cornerRadius: 9).stroke(Premium.hairline, lineWidth: 1))
}

// MARK: Befunde

private var befundeBlock: some View {
 abschnitt("Aktuelle Systemchecks", symbol: "checklist") {
   if agent.befunde.isEmpty {
     Text(agent.aktiv
       ? "Noch kein Scan gelaufen -- der erste startet automatisch kurz nach dem App-Start."
       : "Agent ist pausiert. Automatik oben aktivieren oder manuell scannen.")
       .font(.system(size: 11))
       .foregroundStyle(Premium.textFaint)
   } else {
     VStack(spacing: 5) {
       ForEach(agent.befunde) { b in
         HStack(alignment: .top, spacing: 9) {
           Image(systemName: b.schwere.symbol)
             .font(.system(size: 11))
             .foregroundStyle(b.schwere.farbe)
             .padding(.top, 1)
           VStack(alignment: .leading, spacing: 2) {
             HStack(spacing: 6) {
               Text(b.bereich.uppercased())
                 .font(.system(size: 8, weight: .black))
                 .kerning(0.4)
                 .foregroundStyle(Premium.action)
               Text(b.titel)
                 .font(.system(size: 11.5, weight: .semibold))
                 .foregroundStyle(Premium.text)
             }
             Text(b.detail)
               .font(.system(size: 10.5))
               .foregroundStyle(Premium.textSoft)
               .fixedSize(horizontal: false, vertical: true)
           }
           Spacer()
         }
         .padding(.horizontal, 10).padding(.vertical, 7)
         .background(RoundedRectangle(cornerRadius: 7).fill(Premium.panel.opacity(0.45)))
       }
     }
   }
 }
}

// MARK: Reparaturen

private var reparaturenBlock: some View {
 abschnitt("Automatische Reparaturen", symbol: "wrench.and.screwdriver") {
   if agent.reparaturen.isEmpty {
     Text("Noch keine Reparaturen nötig -- das Programm läuft fehlerfrei.")
       .font(.system(size: 11))
       .foregroundStyle(Premium.textFaint)
   } else {
     VStack(spacing: 4) {
       ForEach(agent.reparaturen.prefix(15)) { r in
         HStack(alignment: .top, spacing: 8) {
           Image(systemName: r.erfolgreich ? "checkmark.circle.fill" : "xmark.circle.fill")
             .font(.system(size: 10))
             .foregroundStyle(r.erfolgreich ? .green : .red)
             .padding(.top, 2)
           VStack(alignment: .leading, spacing: 1) {
             Text(r.aktion)
               .font(.system(size: 11, weight: .semibold))
               .foregroundStyle(Premium.text)
             Text(r.detail)
               .font(.system(size: 10))
               .foregroundStyle(Premium.textSoft)
               .fixedSize(horizontal: false, vertical: true)
           }
           Spacer()
           Text(r.zeit.formatted(date: .numeric, time: .shortened))
             .font(.system(size: 9, design: .monospaced))
             .foregroundStyle(Premium.textFaint)
         }
         .padding(.horizontal, 10).padding(.vertical, 6)
         .background(RoundedRectangle(cornerRadius: 7).fill(Premium.panel.opacity(0.4)))
       }
     }
   }
 }
}

// MARK: Snapshot

private var snapshotBlock: some View {
 abschnitt("Known-Good-Snapshot (Referenz „voll funktionsfähig")", symbol: "externaldrive.badge.checkmark") {
   VStack(alignment: .leading, spacing: 8) {
     Text("Nach jedem vollständig gesunden Scan sichert der Agent automatisch eine Kopie aller Datendateien. Wird später eine Datei beschädigt, stellt er sie ohne Zutun aus dieser Referenz wieder her.")
       .font(.system(size: 10.5))
       .foregroundStyle(Premium.textSoft)
       .fixedSize(horizontal: false, vertical: true)
     HStack(spacing: 12) {
       if let d = agent.letzterSnapshot {
         Label("\(agent.snapshotDateien) Dateien · \(d.formatted(date: .abbreviated, time: .shortened))",
            systemImage: "internaldrive")
           .font(.system(size: 10.5))
           .foregroundStyle(Premium.text)
       } else {
         Label("Noch kein Snapshot -- wird nach dem ersten gesunden Scan angelegt.",
            systemImage: "internaldrive")
           .font(.system(size: 10.5))
           .foregroundStyle(Premium.textFaint)
       }
       Spacer()
       Button {
         agent.erstelleSnapshot()
       } label: {
         Label("Snapshot jetzt anlegen", systemImage: "arrow.down.doc")
           .font(.system(size: 10.5, weight: .semibold))
           .padding(.horizontal, 10).padding(.vertical, 6)
           .background(RoundedRectangle(cornerRadius: 7).fill(Premium.panel))
           .overlay(RoundedRectangle(cornerRadius: 7).stroke(Premium.hairline, lineWidth: 1))
           .foregroundStyle(Premium.text)
       }
       .buttonStyle(.plain)
     }
   }
 }
}

// MARK: Beschwerden

private var beschwerdenBlock: some View {
 abschnitt("Beschwerde / Problem melden", symbol: "bubble.left.and.exclamationmark.bubble.right") {
   VStack(alignment: .leading, spacing: 10) {
     Text("Funktioniert etwas nicht -- ein Button, eine KI, ein Ablauf? Direkt dem Agenten melden. Er triagiert die Meldung (KI-gestützt, ohne Zugriff auf Ihre Falldaten), startet sofort einen Systemscan und antwortet hier.")
       .font(.system(size: 10.5))
       .foregroundStyle(Premium.textSoft)
       .fixedSize(horizontal: false, vertical: true)

     HStack(spacing: 8) {
       TextField("z. B. „Lexara-Prognose antwortet nicht" oder „Button X ohne Funktion" …", text: $beschwerdeText, axis: .vertical)
         .textFieldStyle(.plain)
         .font(.system(size: 11.5))
         .lineLimit(1...4)
         .padding(.horizontal, 10).padding(.vertical, 8)
         .background(RoundedRectangle(cornerRadius: 8).fill(Premium.well))
       Button {
         agent.beschwerdeEinreichen(beschwerdeText)
         beschwerdeText = ""
       } label: {
         Label("Senden", systemImage: "paperplane.fill")
           .font(.system(size: 11, weight: .semibold))
           .padding(.horizontal, 12).padding(.vertical, 8)
           .background(RoundedRectangle(cornerRadius: 8).fill(Premium.action))
           .foregroundStyle(Premium.onAction)
       }
       .buttonStyle(.plain)
       .disabled(beschwerdeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
     }

     if !agent.beschwerden.isEmpty {
       VStack(spacing: 6) {
         ForEach(agent.beschwerden.prefix(10)) { b in
           VStack(alignment: .leading, spacing: 4) {
             HStack(spacing: 6) {
               Text(b.status.label.uppercased())
                 .font(.system(size: 8, weight: .black))
                 .kerning(0.4)
                 .padding(.horizontal, 6).padding(.vertical, 2)
                 .background(Capsule().fill(statusFarbe(b.status).opacity(0.18)))
                 .foregroundStyle(statusFarbe(b.status))
               if let bereich = b.betroffenerBereich {
                 Text(bereich)
                   .font(.system(size: 9, weight: .semibold))
                   .foregroundStyle(Premium.action)
               }
               Spacer()
               Text(b.datum.formatted(date: .numeric, time: .shortened))
                 .font(.system(size: 9, design: .monospaced))
                 .foregroundStyle(Premium.textFaint)
             }
             Text("„\(b.text)"")
               .font(.system(size: 11))
               .foregroundStyle(Premium.text)
               .fixedSize(horizontal: false, vertical: true)
             if let antwort = b.antwort {
               HStack(alignment: .top, spacing: 6) {
                 Image(systemName: "wrench.and.screwdriver.fill")
                   .font(.system(size: 9))
                   .foregroundStyle(Premium.computed)
                   .padding(.top, 2)
                 Text(antwort)
                   .font(.system(size: 10.5))
                   .foregroundStyle(Premium.textSoft)
                   .fixedSize(horizontal: false, vertical: true)
               }
               .padding(8)
               .background(RoundedRectangle(cornerRadius: 7).fill(Premium.computed.opacity(0.07)))
             }
           }
           .padding(.horizontal, 10).padding(.vertical, 8)
           .background(RoundedRectangle(cornerRadius: 8).fill(Premium.panel.opacity(0.45)))
           .overlay(RoundedRectangle(cornerRadius: 8).stroke(Premium.hairline, lineWidth: 1))
         }
       }
     }
   }
 }
}

private func statusFarbe(_ s: SelbstreparaturAgent.BeschwerdeStatus) -> Color {
 switch s {
 case .offen: return .orange
 case .inArbeit: return Premium.action
 case .beantwortet: return .green
 }
}

// MARK: Datenschutz

private var datenschutzBlock: some View {
 abschnitt("Datenschutz & Grenzen des Agenten", symbol: "lock.shield.fill") {
   VStack(alignment: .leading, spacing: 5) {
     punkt("Kein Zugriff auf persönliche Daten -- geprüft wird nur, OB Dateien lesbar sind (Parse-Test), nie deren Inhalt.")
     punkt("An die KI gehen ausschließlich technische Metadaten (Fehlerzähler, Modulnamen, Beschwerdetext) -- niemals Mandats- oder Falldaten.")
     punkt("Reparaturen betreffen nur Programm & Konfiguration: Dateien aus dem Known-Good-Snapshot wiederherstellen, KI-Anbieter umschalten, Registry prüfen.")
     punkt("Jede Reparatur wird protokolliert und ist hier nachvollziehbar -- Maßstab ist immer der Nutzen für die anwaltliche Arbeit.")
     punkt("Vor jeder Änderung existiert die funktionsfähige Referenz (Snapshot) -- schlägt etwas fehl, bleibt der letzte gute Stand erhalten.")
   }
 }
}

private func punkt(_ text: String) -> some View {
 HStack(alignment: .top, spacing: 7) {
   Image(systemName: "checkmark.shield.fill")
     .font(.system(size: 10))
     .foregroundStyle(Premium.computed)
     .padding(.top, 2)
   Text(text)
     .font(.system(size: 10.5))
     .foregroundStyle(Premium.textSoft)
     .fixedSize(horizontal: false, vertical: true)
 }
}

// MARK: Baustein

private func abschnitt<Inhalt: View>(_ titel: String, symbol: String, @ViewBuilder inhalt: () -> Inhalt) -> some View {
 VStack(alignment: .leading, spacing: 10) {
   Label(titel, systemImage: symbol)
     .font(.system(size: 12, weight: .bold))
     .foregroundStyle(Premium.text)
   inhalt()
 }
 .padding(14)
 .frame(maxWidth: .infinity, alignment: .leading)
 .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Premium.panel.opacity(0.5)))
 .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Premium.hairline, lineWidth: 1))
}
}

