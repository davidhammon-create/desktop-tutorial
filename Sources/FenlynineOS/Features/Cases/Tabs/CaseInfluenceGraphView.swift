import SwiftUI

// MARK: - Fallanalyse-Netzwerk (wie CaseInfluenceGraph.jsx -- ohne KI)

struct CaseInfluenceGraphView: View {
let viewModel: CaseDetailViewModel
@State private var filterTyp = "all"

private struct NetzKnoten: Identifiable {
  let id: String
  let label: String
  let typ: String
  let staerke: Int
  let farbe: Color
}

private var knoten: [NetzKnoten] {
  var items: [NetzKnoten] = []
  for a in viewModel.argumente {
    items.append(NetzKnoten(
      id: a.id ?? UUID().uuidString,
      label: a.title ?? "Argument",
      typ: "argument",
      staerke: Int(a.ki_strength ?? Double(a.strength)),
      farbe: a.side == .eigen ? .blue : .red
    ))
  }
  for e in viewModel.beweise {
    items.append(NetzKnoten(
      id: e.id ?? UUID().uuidString,
      label: e.title ?? "Beweis",
      typ: "evidence",
      staerke: Int(e.ki_weight ?? Double(e.weight)),
      farbe: .green
    ))
  }
  for d in viewModel.fristen {
    items.append(NetzKnoten(
      id: d.id ?? UUID().uuidString,
      label: d.title,
      typ: "deadline",
      staerke: 7,
      farbe: .orange
    ))
  }
  for p in viewModel.personen {
    items.append(NetzKnoten(
      id: p.id ?? UUID().uuidString,
      label: p.name ?? "Person",
      typ: "person",
      staerke: p.glaubwuerdigkeit ?? 5,
      farbe: .purple
    ))
  }
  return items
}

private var gefiltert: [NetzKnoten] {
  filterTyp == "all" ? knoten : knoten.filter { $0.typ == filterTyp }
}

var body: some View {
  VStack(alignment: .leading, spacing: 16) {
    Label("Fallanalyse-Netzwerk", systemImage: "point.3.connected.trianglepath.dotted")
      .font(.title2.bold())

    Text("Verknüpfungen zwischen Argumenten, Beweisen, Fristen und Personen")
      .font(.caption).foregroundStyle(.secondary)

    HStack(spacing: 8) {
      ForEach([("all", "Alle"), ("argument", "Argumente"), ("evidence", "Beweise"), ("deadline", "Fristen"), ("person", "Personen")], id: \.0) { key, label in
        Button(label) { filterTyp = key }
          .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
          .controlSize(.small)
          .tint(filterTyp == key ? .primary : .secondary)
      }
    }

    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 10) {
      ForEach(gefiltert) { k in
        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Circle().fill(k.farbe).frame(width: 8, height: 8)
            Text(k.label).font(.caption.bold()).lineLimit(2)
          }
          Text(k.typ.capitalized).font(.caption2).foregroundStyle(.secondary)
          ProgressView(value: Double(k.staerke), total: 10)
            .tint(k.farbe)
        }
        .padding(10)
        .background(k.farbe.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
      }
    }

    if knoten.isEmpty {
      InfoHinweis(titel: "Keine Daten", nachricht: "Erfassen Sie Argumente, Beweise und Personen in den vorherigen Reitern.", symbol: "network")
    } else {
      HStack(spacing: 16) {
        NetzwerkStat(label: "Knoten gesamt", wert: "\(knoten.count)")
       NetzwerkStat(label: "Argumente", wert: "\(viewModel.argumente.count)")
       NetzwerkStat(label: "Beweise", wert: "\(viewModel.beweise.count)")
       NetzwerkStat(label: "Verknüpfungen", wert: "\(viewModel.argumente.filter { !($0.linked_evidence_ids ?? []).isEmpty }.count)")
     }
   }
 }
}
}

private struct NetzwerkStat: View {
let label: String
let wert: String
var body: some View {
 VStack(spacing: 2) {
   Text(wert).font(.headline.bold())
   Text(label).font(.caption2).foregroundStyle(.secondary)
 }
 .frame(maxWidth: .infinity)
 .padding(8)
 .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
}
}

