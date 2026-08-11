import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// STUDIO-INSPEKTOR -- aus FenlynineOS (additiv, Premium-Tokens)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Kern-Graph · aktiver Fall · Schnellzugriff · Audit-Hinweise
// Bestehendes Design bleibt; Inspektor ist optional einblendbar.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct StudioInspektor: View {
@EnvironmentObject var appState: AppState
@Bindable private var kernStore = FenlynineOSKernStore.shared
@Bindable private var wissen = RechtswissenStore.shared

let onNavigiere: (SeitenleistenEintrag) -> Void
let onOeffneFenster: (SeitenleistenEintrag) -> Void

@State private var auditorFunde: [FenlynineOSAuditorFund] = []

var body: some View {
  VStack(alignment: .leading, spacing: 0) {
    HStack {
      Text("Inspektor")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(Premium.textSoft)
      Spacer()
      Text("\(auditorFunde.count) Audit")
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .foregroundStyle(auditorFunde.isEmpty ? Premium.textFaint : Premium.proposed)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)

    Divider().overlay(Premium.hairline)

    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        kernKarte
        fallKarte
        wissenKarte
        schnellzugriff
        if !auditorFunde.isEmpty { auditKarte }
      }
      .padding(12)
    }
  }
  .frame(width: 268)
  .background(Premium.ink)
  .overlay(alignment: .leading) {
    Rectangle().fill(Premium.hairline).frame(width: 1)
  }
  .onAppear { refreshAudit() }
  .onChange(of: kernStore.knoten.count) { _, _ in refreshAudit() }
  .onChange(of: kernStore.kanten.count) { _, _ in refreshAudit() }
}

private var kernKarte: some View {
  inspectorCard {
    VStack(alignment: .leading, spacing: 10) {
      Label("Kern-Graph", systemImage: "point.3.connected.trianglepath.dotted")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(Premium.textSoft)

      HStack(spacing: 8) {
        stat("\(kernStore.knoten.count)", "Knoten")
        stat("\(kernStore.kanten.count)", "Kanten")
      }

      Button("Schreibtisch / Kern") {
        onNavigiere(.schreibtisch)
      }
      .buttonStyle(.plain)
      .font(.system(size: 11, weight: .semibold))
      .foregroundStyle(Premium.onAction)
      .padding(.horizontal, 12).padding(.vertical, 6)
      .background(RoundedRectangle(cornerRadius: 7).fill(Premium.action))
    }
  }
}

private var fallKarte: some View {
  inspectorCard {
    VStack(alignment: .leading, spacing: 8) {
      Text("Kontext")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(Premium.textSoft)

      Text("Aktiver Vorgang und Lexara-Fall sind getrennte Konzepte -- Vorgänge = Studio-Home, Fälle = Lexara-Mandate.")
        .font(.system(size: 10))
        .foregroundStyle(Premium.textFaint)
        .fixedSize(horizontal: false, vertical: true)

      if let v = VorgangStore.shared.vorgaenge.first {
        Text("Aktiver Vorgang (Studio)")
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(Premium.textFaint)
        Text(v.titel)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(Premium.text)
         .lineLimit(2)
       Text("\(VorgangStore.shared.vorgaenge.count) Vorgänge insgesamt")
         .font(.system(size: 10))
         .foregroundStyle(Premium.textFaint)
       Button("Vorgänge") { onNavigiere(.vorgaenge) }
         .buttonStyle(StudioSoftButton())
     } else {
       Text("Aktiver Vorgang: keiner")
         .font(.system(size: 12))
         .foregroundStyle(Premium.textFaint)
       Button("Vorgänge") { onNavigiere(.vorgaenge) }
         .buttonStyle(StudioSoftButton())
     }

     Divider().overlay(Premium.hairline)

     Text("Aktiver Fall (Lexara)")
       .font(.system(size: 10, weight: .semibold))
       .foregroundStyle(Premium.textFaint)

     if let id = appState.selectedCaseId {
       Text(id)
         .font(.system(size: 12, weight: .semibold))
         .foregroundStyle(Premium.text)
         .lineLimit(2)
       HStack(spacing: 8) {
         Button("Lexara") { onNavigiere(.lexara) }
           .buttonStyle(StudioSoftButton())
         Button("Fenster") { onOeffneFenster(.lexara) }
           .buttonStyle(StudioSoftButton())
       }
     } else {
       Text("Kein Fall ausgewählt")
         .font(.system(size: 12))
         .foregroundStyle(Premium.textFaint)
       Button("Fälle öffnen") { onNavigiere(.lexara) }
         .buttonStyle(StudioSoftButton())
     }
   }
 }
}

private var wissenKarte: some View {
 inspectorCard {
   VStack(alignment: .leading, spacing: 6) {
     Text("Rechtswissen")
       .font(.system(size: 11, weight: .semibold))
       .foregroundStyle(Premium.textSoft)
     Text("\(wissen.eintraege.count) Einträge")
       .font(.system(size: 11))
       .foregroundStyle(Premium.textFaint)
     if !wissen.agentStatus.isEmpty {
       Text(wissen.agentStatus)
         .font(.system(size: 10))
         .foregroundStyle(Premium.textFaint)
         .lineLimit(2)
     }
   }
 }
}

private var schnellzugriff: some View {
 VStack(alignment: .leading, spacing: 6) {
   Text("Schnellzugriff")
     .font(.system(size: 11, weight: .semibold))
     .foregroundStyle(Premium.textSoft)

   ForEach([SeitenleistenEintrag.lexara, .strategos, .opportunisma, .organon, .kiChat], id: \.self) { e in
     HStack(spacing: 6) {
       Button {
         onNavigiere(e)
       } label: {
         HStack(spacing: 8) {
           Image(systemName: e.symbol)
             .font(.system(size: 11))
             .foregroundStyle(Premium.action)
             .frame(width: 16)
           Text(e.bezeichnung)
             .font(.system(size: 11, weight: .medium))
             .foregroundStyle(Premium.textSoft)
             .lineLimit(1)
           Spacer()
         }
         .padding(.horizontal, 10)
         .padding(.vertical, 7)
         .background(RoundedRectangle(cornerRadius: 7).fill(Premium.panel))
       }
       .buttonStyle(.plain)

       Button {
         onOeffneFenster(e)
       } label: {
         Image(systemName: "macwindow")
           .font(.system(size: 11, weight: .medium))
           .foregroundStyle(Premium.textFaint)
           .frame(width: 28, height: 28)
           .background(RoundedRectangle(cornerRadius: 7).fill(Premium.panel))
       }
       .buttonStyle(.plain)
       .help("Als eigenes Fenster öffnen")
     }
   }
 }
}

private var auditKarte: some View {
 inspectorCard {
   VStack(alignment: .leading, spacing: 8) {
     Text("Audit-Hinweise")
       .font(.system(size: 11, weight: .semibold))
       .foregroundStyle(Premium.proposed)
     ForEach(auditorFunde.prefix(5)) { f in
       VStack(alignment: .leading, spacing: 2) {
         Text(f.pruefung)
           .font(.system(size: 10, weight: .semibold))
           .foregroundStyle(f.schwere == .kritisch ? Premium.critical : Premium.proposed)
         Text(f.begruendung)
           .font(.system(size: 10))
           .foregroundStyle(Premium.textFaint)
           .lineLimit(3)
       }
     }
   }
 }
}

private func inspectorCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
 content()
   .padding(12)
   .frame(maxWidth: .infinity, alignment: .leading)
   .background(RoundedRectangle(cornerRadius: 10).fill(Premium.panel))
   .overlay(RoundedRectangle(cornerRadius: 10).stroke(Premium.hairline, lineWidth: 1))
}

private func stat(_ value: String, _ label: String) -> some View {
 VStack(spacing: 2) {
   Text(value)
     .font(.system(size: 15, weight: .semibold, design: .monospaced))
     .foregroundStyle(Premium.text)
   Text(label)
     .font(.system(size: 9))
     .foregroundStyle(Premium.textFaint)
 }
 .frame(maxWidth: .infinity)
 .padding(.vertical, 8)
 .background(RoundedRectangle(cornerRadius: 7).fill(Premium.well))
}

private func refreshAudit() {
 auditorFunde = FenlynineOSAuditorService.pruefen(store: kernStore)
}
}

struct StudioSoftButton: ButtonStyle {
func makeBody(configuration: Configuration) -> some View {
 configuration.label
   .font(.system(size: 11, weight: .medium))
   .foregroundStyle(Premium.text)
   .padding(.horizontal, 10).padding(.vertical, 5)
   .background(
     RoundedRectangle(cornerRadius: 7)
       .fill(Premium.well.opacity(configuration.isPressed ? 0.7 : 1))
   )
   .overlay(RoundedRectangle(cornerRadius: 7).stroke(Premium.hairline, lineWidth: 1))
}
}

struct UpdatePanelView: View {
@Bindable private var updates = UpdateService.shared
@State private var feedDraft = ""

var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   Text("Updates")
     .font(.system(size: 18, weight: .semibold))
     .foregroundStyle(Premium.text)
   Text("Aktuell \(updates.aktuelleVersion) · Build \(updates.aktuellerBuild)")
     .font(.system(size: 12))
     .foregroundStyle(Premium.textSoft)

   statusZeile

   TextField("Feed-URL (optional)", text: $feedDraft)
     .textFieldStyle(.roundedBorder)
     .onAppear { feedDraft = updates.feedURLString }
     .onSubmit {
       updates.feedURLString = feedDraft
     }

   HStack(spacing: 10) {
     Button("Auf Updates prüfen") {
       updates.feedURLString = feedDraft
       Task { await updates.pruefen() }
     }
     .buttonStyle(.borderedProminent)

     if case .available(let m) = updates.status {
       Button("Installieren \(m.version)") {
         Task { await updates.installiere(m) }
       }
       .buttonStyle(.bordered)
     }
   }

   if case .available(let m) = updates.status {
     VStack(alignment: .leading, spacing: 6) {
       Text("Neu in \(m.version)")
         .font(.system(size: 12, weight: .semibold))
       ForEach(m.notesZeilen, id: \.self) { z in
         Text("(cid:127) \(z)")
           .font(.system(size: 11))
           .foregroundStyle(Premium.textSoft)
       }
     }
     .padding(12)
     .background(RoundedRectangle(cornerRadius: 10).fill(Premium.panel))
   }

   if let h = updates.installierterHinweis {
     Text(h)
       .font(.system(size: 11))
       .foregroundStyle(Premium.computed)
   }

   Text("Lokaler Feed: FenlynineOS-App/updates/manifest.json · Publish: scripts/publish-update.sh")
     .font(.system(size: 10))
     .foregroundStyle(Premium.textFaint)
 }
 .padding(24)
 .frame(maxWidth: .infinity, alignment: .leading)
 .onAppear {
   Task { await updates.pruefen(automatisch: true) }
 }
}

@ViewBuilder
private var statusZeile: some View {
 switch updates.status {
 case .idle:
   Text("Noch nicht geprüft").foregroundStyle(Premium.textFaint)
 case .checking:
   HStack { ProgressView().controlSize(.small); Text("Prüfe…") }
 case .upToDate:
   Label("Auf dem neuesten Stand", systemImage: "checkmark.circle.fill")
     .foregroundStyle(Premium.computed)
 case .available(let m):
   Label("Update \(m.version) verfügbar", systemImage: "arrow.down.circle.fill")
     .foregroundStyle(Premium.action)
 case .downloading(let p):
   ProgressView(value: p) { Text("Lade… \(Int(p * 100)) %") }
 case .installing:
   HStack { ProgressView().controlSize(.small); Text("Installiere…") }
 case .failed(let e):
   Text(e).foregroundStyle(Premium.critical)
 }
}
}

