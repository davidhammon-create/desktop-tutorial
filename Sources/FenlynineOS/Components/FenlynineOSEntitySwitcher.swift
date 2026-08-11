import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// ENTITY-SWITCHER -- Fall / Richter / Situation wechseln OHNE
// den ganzen Reiter/die ganze Funktion zu verlassen.
// Immer sichtbar über dem Detailinhalt.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct FenlynineOSEntityItem: Identifiable, Hashable {
let id: String
let titel: String
var untertitel: String? = nil
var gruppe: String? = nil
var symbol: String? = nil
}

struct FenlynineOSEntitySwitcher: View {
let label: String
let symbol: String
let items: [FenlynineOSEntityItem]
@Binding var selectedId: String?
var onListe: (() -> Void)? = nil
var listenLabel: String = "Liste"

private var selected: FenlynineOSEntityItem? {
  items.first { $0.id == selectedId } ?? items.first
}

private var selectedIndex: Int? {
  items.firstIndex { $0.id == selectedId }
}

var body: some View {
  HStack(spacing: 8) {
    Label(label, systemImage: symbol)
      .font(.system(size: 10, weight: .bold))
      .foregroundStyle(Premium.textFaint)
      .labelStyle(.titleAndIcon)

    // Vorher / Nachher
    HStack(spacing: 2) {
      Button {
        springe(-1)
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 11, weight: .semibold))
          .frame(width: 26, height: 26)
      }
      .buttonStyle(.plain)
      .disabled(items.count < 2)

      Button {
        springe(1)
      } label: {
        Image(systemName: "chevron.right")
          .font(.system(size: 11, weight: .semibold))
          .frame(width: 26, height: 26)
      }
      .buttonStyle(.plain)
      .disabled(items.count < 2)
    }
    .foregroundStyle(Premium.action)
    .background(RoundedRectangle(cornerRadius: 6).fill(Premium.well))

    // Auswahlmenü -- gruppiert wenn Gruppen vorhanden
    Menu {
      if items.contains(where: { $0.gruppe != nil }) {
        let gruppen = Dictionary(grouping: items) { $0.gruppe ?? "Weitere" }
        ForEach(gruppen.keys.sorted(), id: \.self) { g in
          Section(g) {
            ForEach(gruppen[g] ?? []) { item in
              Button {
                selectedId = item.id
              } label: {
                if selectedId == item.id {
                  Label(item.titel, systemImage: "checkmark")
                } else {
                  Text(item.titel)
                }
              }
            }
          }
        }
      } else {
        ForEach(items) { item in
          Button {
            selectedId = item.id
          } label: {
            if selectedId == item.id {
              Label(item.titel, systemImage: "checkmark")
            } else {
              Text(item.titel)
            }
          }
        }
      }
    } label: {
      HStack(spacing: 6) {
        if let s = selected?.symbol {
         Image(systemName: s).font(.system(size: 11))
       }
       VStack(alignment: .leading, spacing: 1) {
         Text(selected?.titel ?? "Auswählen…")
           .font(.system(size: 12, weight: .semibold))
           .lineLimit(1)
         if let u = selected?.untertitel, !u.isEmpty {
           Text(u)
             .font(.system(size: 9))
             .foregroundStyle(Premium.textFaint)
             .lineLimit(1)
         }
       }
       Image(systemName: "chevron.up.chevron.down")
         .font(.system(size: 9, weight: .bold))
         .foregroundStyle(Premium.textFaint)
     }
     .foregroundStyle(Premium.text)
     .padding(.horizontal, 10)
     .padding(.vertical, 5)
     .frame(maxWidth: 360, alignment: .leading)
     .background(RoundedRectangle(cornerRadius: 7).fill(Premium.well))
   }
   .menuStyle(.borderlessButton)

   if let n = selectedIndex {
     Text("\(n + 1)/\(items.count)")
       .font(.system(size: 10, weight: .medium, design: .monospaced))
       .foregroundStyle(Premium.textFaint)
   }

   Spacer(minLength: 4)

   if let onListe {
     Button(action: onListe) {
       Label(listenLabel, systemImage: "sidebar.left")
         .font(.system(size: 11, weight: .semibold))
     }
     .buttonStyle(.plain)
     .foregroundStyle(Premium.action)
     .padding(.horizontal, 8)
     .padding(.vertical, 5)
     .background(RoundedRectangle(cornerRadius: 6).fill(Premium.action.opacity(0.1)))
     .help("Seitenliste einblenden")
   }
 }
 .padding(.horizontal, 12)
 .padding(.vertical, 7)
 .background(Premium.ink.opacity(0.55))
 .overlay(alignment: .bottom) {
   Rectangle().fill(Premium.hairline).frame(height: 1)
 }
}

private func springe(_ delta: Int) {
 guard !items.isEmpty else { return }
 let aktuell = selectedIndex ?? 0
 let neu = (aktuell + delta + items.count) % items.count
 selectedId = items[neu].id
}
}

