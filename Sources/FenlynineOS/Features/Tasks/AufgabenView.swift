import SwiftUI
import Charts

struct AufgabenView: View {
@State private var aufgaben: [CaseTask] = []
@State private var isLoading = false
@State private var filter: CaseTask.AufgabeStatus? = nil
@State private var zeigeNeueAufgabe = false
@State private var suchtext = ""

var gefiltert: [CaseTask] {
  var result = aufgaben
  if let f = filter { result = result.filter { $0.status == f } }
  if !suchtext.isEmpty {
    result = result.filter { $0.title.localizedCaseInsensitiveContains(suchtext) }
  }
  return result.sorted { ($0.due_date ?? .distantFuture) < ($1.due_date ?? .distantFuture) }
}

var body: some View {
  VStack(spacing: 0) {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        FilterChip(titel: "Alle", aktiv: filter == nil) { filter = nil }
        ForEach(CaseTask.AufgabeStatus.allCases, id: \.self) { status in
          FilterChip(
            titel: "\(status.rawValue) (\(aufgaben.filter { $0.status == status }.count))",
            aktiv: filter == status
          ) { filter = filter == status ? nil : status }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
    }
    .visionOSGlass(cornerRadius: 0, elevated: false)

    if isLoading {
      ProgressView().frame(maxHeight: .infinity)
    } else if gefiltert.isEmpty {
      PlatzhalterView(nachricht: "Keine Aufgaben")
    } else {
      List {
        ForEach(gefiltert) { aufgabe in
          AufgabeListenZeile(aufgabe: aufgabe) { geaendert in
            Task { try? await Services.tasks.update(id: geaendert.id ?? "", entity: geaendert) }
            if let idx = aufgaben.firstIndex(where: { $0.id == geaendert.id }) {
              aufgaben[idx] = geaendert
            }
          }
        }
        .onDelete { idx in
          let ids = idx.map { gefiltert[$0].id ?? "" }
          ids.forEach { id in
            aufgaben.removeAll { $0.id == id }
            Task { try? await Services.tasks.delete(id: id) }
          }
        }
      }
      .listStyle(.plain)
    }
  }
  .fenlynineOSAdaptiveNavigationTitle("Aufgaben")
  .searchable(text: $suchtext, prompt: "Aufgaben suchen…")
  .toolbar {
    ToolbarItem(placement: .primaryAction) {
      Button { zeigeNeueAufgabe = true } label: {
        Label("Neu", systemImage: "plus")
      }
      .buttonStyle(FenlynineOSPrimaryButtonStyle())
    }
  }
  .task { await laden() }
  .sheet(isPresented: $zeigeNeueAufgabe) {
    NeueAufgabeSheet(caseId: "") { neue in
      aufgaben.insert(neue, at: 0)
    }
  }
}

private func laden() async {
  isLoading = true
  aufgaben = (try? await Services.tasks.list()) ?? []
  isLoading = false
}
}

struct AufgabeListenZeile: View {
let aufgabe: CaseTask
let onAendern: (CaseTask) -> Void

var body: some View {
  HStack(spacing: 12) {
    Button {
      var geaendert = aufgabe
      geaendert.status = aufgabe.status == .erledigt ? .offen : .erledigt
      onAendern(geaendert)
    } label: {
      Image(systemName: aufgabe.status == .erledigt ? "checkmark.circle.fill" : "circle")
        .font(.system(size: 18))
       .foregroundStyle(aufgabe.status == .erledigt ? .green : .secondary)
   }
   .buttonStyle(.plain)

   VStack(alignment: .leading, spacing: 3) {
     Text(aufgabe.title)
       .font(.system(size: 13, weight: .medium))
       .strikethrough(aufgabe.status == .erledigt)
       .foregroundStyle(aufgabe.status == .erledigt ? .secondary : .primary)

     HStack(spacing: 8) {
       if let due = aufgabe.due_date {
         HStack(spacing: 3) {
           Image(systemName: "clock").font(.caption2)
           Text(due.formatted(date: .abbreviated, time: .omitted))
             .font(.caption2)
         }
         .foregroundStyle(due < Date() && aufgabe.status != .erledigt ? .red : .secondary)
       }
       Text(aufgabe.priority.rawValue)
         .font(.caption2)
         .foregroundStyle(prioritaetFarbe(aufgabe.priority))
     }
   }

   Spacer()
 }
 .padding(.vertical, 2)
}

private func prioritaetFarbe(_ p: CaseTask.Prioritaet) -> Color {
 switch p {
 case .niedrig: return .gray
 case .mittel: return .blue
 case .hoch: return .orange
 case .kritisch: return .red
 }
}
}

struct FilterChip: View {
let titel: String
let aktiv: Bool
let aktion: () -> Void
@Environment(\.fenlynineOSVisionOSChrome) private var chrome

var body: some View {
 Button(action: aktion) {
   Text(titel)
     .font(.system(size: 12, weight: aktiv ? .semibold : .regular))
     .foregroundStyle(aktiv ? .white : FenlynineOSTheme.textPrimary)
     .padding(.horizontal, 14)
     .padding(.vertical, 7)
     .background {
       if aktiv {
         VisionOSGlasFlaeche.button(stil: .primaerBlau)
       } else if chrome {
         VisionOSGlasFlaeche.button(stil: .ghost)
       } else {
         Capsule().fill(Color.gray.opacity(0.1))
       }
     }
 }
 .buttonStyle(.plain)
}
}

