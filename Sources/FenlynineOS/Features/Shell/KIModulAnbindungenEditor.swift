import SwiftUI

/// UI: globale API für alle KIs ODER eigene Anbindung je Modul.
struct KIModulAnbindungenEditor: View {
@State private var selected: KIModulSlot = .lexara
@State private var draft = KIModulAnbindung()

var body: some View {
  VStack(alignment: .leading, spacing: 12) {
    Picker("Modul", selection: $selected) {
      ForEach(KIModulSlot.allCases.filter { $0 != .global }) { slot in
        Text(slot.titel).tag(slot)
      }
    }
    .onChange(of: selected) { _, s in
      draft = KIKonfiguration.shared.modulAnbindungen[s.rawValue] ?? KIModulAnbindung()
    }

    Toggle("Globale API verwenden (empfohlen)", isOn: $draft.nutzeGlobal)

    if !draft.nutzeGlobal {
      Picker("Modus", selection: $draft.modus) {
        ForEach(KIModus.allCases, id: \.self) { Text($0.bezeichnung).tag($0) }
      }
      if draft.modus == .offline {
        TextField("Offline-URL", text: $draft.offlineURL)
        TextField("Modell", text: $draft.offlineModell)
      }
      TextField("Modell-Override (Base44, optional)", text: Binding(
        get: { draft.modellOverride ?? "" },
        set: { draft.modellOverride = $0.isEmpty ? nil : $0 }
      ))
    } else {
      Text(selected.untertitel)
        .font(.caption)
        .foregroundStyle(Premium.textSoft)
    }

    Button("Modul-Anbindung speichern") {
      var cfg = KIKonfiguration.shared
      cfg.setzeAnbindung(selected, draft)
      KIKonfiguration.syncShared(from: cfg)
    }
    .buttonStyle(.bordered)

    Divider()

    Text("Aktive Slots mit eigener API")
      .font(.caption.bold())
    let eigene = KIModulSlot.allCases.filter {
      $0 != .global && (KIKonfiguration.shared.modulAnbindungen[$0.rawValue]?.nutzeGlobal == false)
    }
    if eigene.isEmpty {
      Text("Keine -- alle Module nutzen die globale Anbindung.")
        .font(.caption2)
        .foregroundStyle(Premium.textSoft)
    } else {
      ForEach(eigene) { s in
        Label(s.titel, systemImage: "link")
          .font(.caption)
      }
    }
  }
  .onAppear {
    draft = KIKonfiguration.shared.modulAnbindungen[selected.rawValue] ?? KIModulAnbindung()
  }
}
}

