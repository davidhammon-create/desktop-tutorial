import SwiftUI

struct OrganonCanvasView: View {
@Bindable var vm: OrganonViewModel
var onPersonDetail: (() -> Void)? = nil
@State private var dragStart: CGSize = .zero
@State private var zeigeProfil = false
@State private var layoutErledigt = false

var body: some View {
  HSplitView {
    VStack(spacing: 0) {
      OrganonCanvasToolbar(vm: vm)
      zoomHinweisLeiste
      if let von = vm.neueKanteVonId {
        HStack {
          Text("Kantenmodus: Zielknoten wählen (von \(vm.knoten(von)?.name ?? von))")
            .font(.caption)
            .foregroundStyle(FenlynineOSTheme.accent)
          Spacer()
          Button("Abbrechen") { vm.neueKanteVonId = nil }
            .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(FenlynineOSTheme.accent.opacity(0.08))
      }
      Divider()
      GeometryReader { geo in
        ZStack(alignment: .topLeading) {
          OrganonCanvasHintergrund()
          // Ebenen-Beschriftung links
          ebenenLabels(geo: geo)

          Canvas { ctx, size in
            zeichneKanten(ctx: ctx, size: size)
          }
          .allowsHitTesting(false)

          ForEach(vm.knotenFuerZoom()) { kn in
            OrganonKnotenView(
              knoten: kn,
              istAusgewaehlt: vm.ausgewaehlterKnoten?.id == kn.id,
              istTreffer: vm.suchTreffer.contains(where: { $0.id == kn.id }),
              overlayAktiv: vm.aktiveOverlays,
              projektlast: kn.typ == .bereich ? vm.projektlastNormiert(fuer: kn.id) : nil
            )
            .position(canvasPunkt(fuer: kn, in: geo.size))
            .onTapGesture {
              if let _ = vm.neueKanteVonId {
                vm.schliesseKante(zu: kn.id)
              } else {
                vm.ausgewaehlterKnoten = kn
                if kn.typ == .person { zeigeProfil = true }
              }
            }
          }
        }
        .gesture(
          DragGesture()
            .onChanged { v in
              vm.canvasOffset = CGSize(
                width: dragStart.width + v.translation.width,
                height: dragStart.height + v.translation.height
              )
            }
            .onEnded { _ in dragStart = vm.canvasOffset }
        )
        .onAppear {
          dragStart = vm.canvasOffset
          if !layoutErledigt {
            vm.legeHierarchieAn(still: true)
            dragStart = vm.canvasOffset
            layoutErledigt = true
          }
        }
      }
    }
    .frame(minWidth: 500)

    if let kn = vm.ausgewaehlterKnoten {
      OrganonProfilDetailPanel(knoten: kn, vm: vm, onEdit: onPersonDetail)
        .frame(minWidth: 280, idealWidth: 320, maxWidth: 380)
    } else {
      OrganonCanvasHilfePanel()
        .frame(minWidth: 280, idealWidth: 320, maxWidth: 360)
    }
  }
  .sheet(isPresented: $zeigeProfil) {
    if let kn = vm.ausgewaehlterKnoten {
      OrganonProfilSheet(knoten: kn, vm: vm)
    }
  }
  .onChange(of: vm.zoomStufe) { _, _ in
    withAnimation(.easeInOut(duration: 0.35)) {
      vm.legeHierarchieAn(still: true)
    }
    dragStart = vm.canvasOffset
  }
 .onChange(of: vm.flugZuKnoten?.id) { _, _ in
   if let kn = vm.flugZuKnoten {
     withAnimation(.spring(duration: 0.5)) {
       vm.canvasOffset = CGSize(
         width: -kn.posX * vm.canvasZoom + 200,
         height: -kn.posY * vm.canvasZoom + 150
       )
     }
     dragStart = vm.canvasOffset
     vm.flugZuKnoten = nil
   }
 }
}

private var zoomHinweisLeiste: some View {
 HStack(spacing: 8) {
   Image(systemName: "eye")
     .font(.caption)
     .foregroundStyle(.secondary)
   Text(zoomHinweisText)
     .font(.caption)
     .foregroundStyle(.secondary)
   Spacer()
   Text("\(vm.knotenFuerZoom().count) sichtbar")
     .font(.caption2.monospacedDigit())
     .foregroundStyle(.tertiary)
 }
 .padding(.horizontal, 16)
 .padding(.vertical, 5)
 .background(Color.secondary.opacity(0.06))
}

private var zoomHinweisText: String {
 switch vm.zoomStufe {
 case .konzern: return "Stufe Kanzlei -- nur die Gesellschaft"
 case .bereich: return "Stufe Abteilungen -- Gesellschaft + Abteilungen"
 case .team: return "Stufe Teams -- Teams unter ihren Abteilungen"
 case .person: return "Stufe Personen -- alle Berufsträger in einer Zeile unter Team/Abteilung"
 }
}

@ViewBuilder
private func ebenenLabels(geo: GeometryProxy) -> some View {
 let labels: [(OrganonKnotenTyp, String)] = [
   (.gesellschaft, "Kanzlei"),
   (.bereich, "Abteilungen"),
   (.team, "Teams"),
   (.person, "Personen")
 ]
 Group {
   ForEach(labels, id: \.0) { typ, titel in
     if vm.typenFuerZoom.contains(typ),
      let y = vm.knotenFuerZoom().first(where: { $0.typ == typ })?.posY {
       Text(titel.uppercased())
         .font(.system(size: 9, weight: .bold))
         .tracking(1.0)
         .foregroundStyle(typ.farbe.opacity(0.7))
         .position(
           x: 36,
           y: y * vm.canvasZoom + vm.canvasOffset.height + 40
         )
     }
   }
 }
 .allowsHitTesting(false)
}

private func canvasPunkt(fuer kn: OrganonKnoten, in size: CGSize) -> CGPoint {
 CGPoint(
   x: kn.position.x * vm.canvasZoom + vm.canvasOffset.width + size.width / 2 - 400 * vm.canvasZoom,
   y: kn.position.y * vm.canvasZoom + vm.canvasOffset.height + 40
 )
}

private func zeichneKanten(ctx: GraphicsContext, size: CGSize) {
 for kante in vm.sichtbareKanten() {
   guard let von = vm.knoten(kante.vonId), let zu = vm.knoten(kante.zuId) else { continue }
   // Auch bei Zoom: nur Kanten zeichnen, wenn beide Enden sichtbar sind
   guard vm.typenFuerZoom.contains(von.typ) || (von.istVakanz && vm.aktiveOverlays.contains(.vakanz)) else { continue }
   guard vm.typenFuerZoom.contains(zu.typ) || (zu.istVakanz && vm.aktiveOverlays.contains(.vakanz)) else { continue }

   let p1 = canvasPunkt(fuer: von, in: size)
   let p2 = canvasPunkt(fuer: zu, in: size)
   var path = Path()
   // Rechtwinklige Hierarchie-Linien statt Kreuzgewirr
   if kante.typ == .disziplinarisch {
     let midY = (p1.y + p2.y) / 2
     path.move(to: p1)
     path.addLine(to: CGPoint(x: p1.x, y: midY))
     path.addLine(to: CGPoint(x: p2.x, y: midY))
     path.addLine(to: p2)
     ctx.stroke(path, with: .color(von.typ.farbe.opacity(0.45)),
          style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
   } else {
     path.move(to: p1)
     path.addLine(to: p2)
     ctx.stroke(path, with: .color(kante.typ.farbe.opacity(0.4)),
          style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
   }
 }
}
}

struct OrganonCanvasToolbar: View {
@Bindable var vm: OrganonViewModel

var body: some View {
 HStack(spacing: 12) {
   Picker("Stufe", selection: $vm.zoomStufe) {
     ForEach(OrganonZoomStufe.allCases, id: \.self) { stufe in
       Text(stufe.bezeichnung).tag(stufe)
     }
   }
   .pickerStyle(.segmented)
   .frame(maxWidth: 420)
   .help("Sichtbare Hierarchie-Stufe: Kanzlei -> Abteilungen -> Teams -> Personen")

   HStack(spacing: 4) {
     Button { vm.canvasZoom = max(0.4, vm.canvasZoom - 0.15) } label: {
       Image(systemName: "minus.magnifyingglass")
     }
     Text("\(Int(vm.canvasZoom * 100))%")
       .font(.caption.monospacedDigit())
       .frame(width: 44)
     Button { vm.canvasZoom = min(2.5, vm.canvasZoom + 0.15) } label: {
       Image(systemName: "plus.magnifyingglass")
     }
   }
   .buttonStyle(FenlynineOSGlassBorderedButtonStyle())

   Button {
     withAnimation(.easeInOut(duration: 0.3)) {
       vm.legeHierarchieAn()
     }
   } label: {
     Label("Neu anordnen", systemImage: "arrow.up.and.down.text.horizontal")
   }
   .buttonStyle(FenlynineOSGlassProminentButtonStyle())
   .help("Knoten als sauberen Hierarchie-Baum neu positionieren")

   Divider().frame(height: 20)

   Menu("Kanten") {
     ForEach(OrganonKantenTyp.allCases, id: \.self) { typ in
       Toggle(typ.bezeichnung, isOn: Binding(
         get: { vm.sichtbareKantenTypen.contains(typ) },
         set: { on in
           if on { vm.sichtbareKantenTypen.insert(typ) }
           else { vm.sichtbareKantenTypen.remove(typ) }
         }
       ))
     }
   }

   Menu("Overlays") {
     ForEach(OrganonOverlay.allCases) { overlay in
       Toggle(overlay.bezeichnung, isOn: Binding(
         get: { vm.aktiveOverlays.contains(overlay) },
         set: { on in
           if on { vm.aktiveOverlays.insert(overlay) }
           else { vm.aktiveOverlays.remove(overlay) }
         }
       ))
     }
   }

   Spacer()

   TextField("Schnellsuche…", text: $vm.suchFilter.query)
     .textFieldStyle(.roundedBorder)
     .frame(maxWidth: 160)
     .onSubmit { vm.sucheAusfuehren() }

   Button {
     vm.neuePerson(unter: vm.ausgewaehlterKnoten?.id)
     vm.legeHierarchieAn()
   } label: {
     Label("Person", systemImage: "person.badge.plus")
   }
   .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
 }
 .padding(.horizontal, 16)
 .padding(.vertical, 8)
}
}

struct OrganonCanvasHintergrund: View {
@Bindable private var design = FenlynineOSDesignStore.shared

var body: some View {
 ZStack {
   FenlynineOSTheme.background
   if design.tokens.useGrid {
     OrganonRasterVorschau()
   }
 }
}
}

struct OrganonKnotenView: View {
let knoten: OrganonKnoten
let istAusgewaehlt: Bool
let istTreffer: Bool
let overlayAktiv: Set<OrganonOverlay>
var projektlast: Double? = nil
@Bindable private var design = FenlynineOSDesignStore.shared

private var stil: OrganonKartenStil { design.tokens.organonStil }

var body: some View {
 VStack(spacing: 4) {
   knotenKoerper
   Text(knoten.name)
     .font(.system(size: knoten.typ == .person ? 10 : 11, weight: .semibold))
     .foregroundStyle(FenlynineOSTheme.textPrimary)
     .lineLimit(2)
     .multilineTextAlignment(.center)
     .frame(width: knotenGroesse.width + 24)

   // Keine langen Claims auf der Karte -- machen die Personen-Stufe unlesbar.
   // Details stehen im Seitenpanel.

   if overlayAktiv.contains(.kapazitaet), let kap = knoten.kapazitaet {
     Circle().fill(kap.farbe).frame(width: 8, height: 8)
   }
   if overlayAktiv.contains(.vakanz), knoten.istVakanz {
     Text("VAKANZ")
       .font(.system(size: 7, weight: .bold))
       .foregroundStyle(FenlynineOSTheme.warning)
   }
   if overlayAktiv.contains(.projektlast), let last = projektlast, knoten.typ == .bereich {
     ProgressView(value: last)
       .tint(.orange)
       .frame(width: 56)
   }
 }
 .opacity(overlayAktiv.contains(.vakanz) && !knoten.istVakanz && knoten.typ == .person ? 0.35 : 1)
}

@ViewBuilder
private var knotenKoerper: some View {
 switch stil {
 case .bubbles:
   bubbleKnoten
 case .metro:
   metroKnoten
 case .orbit:
   orbitKnoten
 case .treemap:
   treemapKnoten
 default:
   standardKnoten
 }
}

private var standardKnoten: some View {
 ZStack {
   RoundedRectangle(cornerRadius: knoten.typ == .person ? 22 : FenlynineOSDesign.cornerRadiusLarge, style: .continuous)
     .fill(FenlynineOSTheme.useGlass ? FenlynineOSTheme.glassFill : hintergrundFarbe)
     .frame(width: knotenGroesse.width, height: knotenGroesse.height)
     .overlay(
       RoundedRectangle(cornerRadius: knoten.typ == .person ? 22 : FenlynineOSDesign.cornerRadiusLarge, style: .continuous)
         .stroke(rahmenFarbe, lineWidth: istAusgewaehlt || istTreffer ? 2 : 0.5)
     )
     .shadow(color: glowFarbe, radius: design.tokens.glowOnSelection && (istAusgewaehlt || istTreffer) ? 12 : 0)

   VStack(spacing: 3) {
     Image(systemName: knoten.istVakanz ? "person.crop.circle.badge.questionmark" : knoten.typ.symbol)
       .font(.system(size: knoten.typ == .person ? 16 : 14))
       .foregroundStyle(knoten.istVakanz ? FenlynineOSTheme.warning : knoten.typ.farbe)
     if knoten.typ != .person {
       Text("\(knoten.mitarbeiterAnzahl ?? 0)")
         .font(.system(size: 9, weight: .bold))
         .foregroundStyle(FenlynineOSTheme.textSecondary)
     }        else if knoten.istVakanz {
       Text("offen")
         .font(.system(size: 7, weight: .bold))
         .foregroundStyle(FenlynineOSTheme.warning)
     }
   }
 }
}

private var bubbleKnoten: some View {
 Circle()
   .fill(FenlynineOSTheme.accent.opacity(0.2))
   .frame(width: knotenGroesse.width * bubbleScale, height: knotenGroesse.width * bubbleScale)
   .overlay(Circle().stroke(rahmenFarbe, lineWidth: istAusgewaehlt ? 2.5 : 1))
   .overlay {
     Text(knoten.typ == .person ? String(knoten.name.prefix(2)) : "\(knoten.mitarbeiterAnzahl ?? 0)")
       .font(.system(size: 10, weight: .bold))
       .foregroundStyle(FenlynineOSTheme.textPrimary)
   }
}

private var bubbleScale: CGFloat {
 CGFloat(knoten.mitarbeiterAnzahl ?? 4) / 12.0 + 0.6
}

private var metroKnoten: some View {
 VStack(spacing: 2) {
   RoundedRectangle(cornerRadius: 2)
     .fill(metroLinienFarbe)
     .frame(width: knotenGroesse.width, height: 4)
   Circle()
     .fill(metroLinienFarbe)
     .frame(width: knoten.typ == .person ? 14 : 10, height: knoten.typ == .person ? 14 : 10)
     .overlay(Circle().stroke(istAusgewaehlt ? FenlynineOSTheme.accent : .clear, lineWidth: 2))
 }
}

private var orbitKnoten: some View {
 ZStack {
   if knoten.typ != .gesellschaft {
     Circle()
       .stroke(FenlynineOSTheme.accent.opacity(0.15), lineWidth: 1)
       .frame(width: knotenGroesse.width + 16, height: knotenGroesse.width + 16)
   }
   standardKnoten
 }
}

private var treemapKnoten: some View {
 RoundedRectangle(cornerRadius: 4, style: .continuous)
   .fill(FenlynineOSTheme.accent.opacity(Double(knoten.mitarbeiterAnzahl ?? 3) / 20.0 + 0.1))
   .frame(width: knotenGroesse.width, height: knotenGroesse.height)
   .overlay(RoundedRectangle(cornerRadius: 4).stroke(rahmenFarbe, lineWidth: 1))
   .overlay(alignment: .topLeading) {
     Text(knoten.name)
       .font(.system(size: 8, weight: .semibold))
       .padding(4)
       .foregroundStyle(FenlynineOSTheme.textPrimary)
   }
}

private var metroLinienFarbe: Color {
 let farben: [Color] = [.orange, .blue, .green, .purple, .pink]
 let idx = abs(knoten.id.hashValue) % farben.count
 return farben[idx]
}

private var glowFarbe: Color {
 if istTreffer { return FenlynineOSTheme.accent.opacity(0.5) }
 if istAusgewaehlt && design.tokens.glowOnSelection { return FenlynineOSTheme.accent.opacity(0.4) }
 return .clear
}

private var knotenGroesse: CGSize {
 switch knoten.typ {
 case .gesellschaft: return CGSize(width: 140, height: 70)
 case .bereich: return CGSize(width: 110, height: 56)
 case .team: return CGSize(width: 90, height: 48)
 case .person: return CGSize(width: 44, height: 44)
 }
}

private var hintergrundFarbe: Color {
 if knoten.istVakanz { return FenlynineOSTheme.warning.opacity(0.12) }
 return knoten.typ.farbe.opacity(knoten.istPerson ? 0.08 : 0.14)
}

private var rahmenFarbe: Color {
 if istTreffer { return FenlynineOSTheme.accent }
 if istAusgewaehlt { return FenlynineOSTheme.accent }
 if knoten.istVakanz { return FenlynineOSTheme.warning.opacity(0.6) }
 return FenlynineOSTheme.glassBorder
}
}

struct OrganonCanvasHilfePanel: View {
var body: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 16) {
     Text("Karte bedienen")
       .font(.headline)
     hilfeZeile("hand.draw", "Ziehen", "Karte verschieben")
     hilfeZeile("square.split.2x1", "Stufen", "Kanzlei -> Abteilungen -> Teams -> Personen -- jede Stufe blendet eine Ebene ein")
     hilfeZeile("arrow.up.and.down.text.horizontal", "Neu anordnen", "Ordnet den Baum sauber untereinander an")
     hilfeZeile("point.3.connected.trianglepath.dotted", "Kanten", "Bis Teams nur Berichtslinien; bei Personen auch Projekte/Mandate")
     hilfeZeile("magnifyingglass", "Suche", "Skills, Rollen, Standorte -- Karte fliegt zum Treffer")
     Divider()
     Text("Kanten-Legende")
       .font(.subheadline.bold())
     ForEach(OrganonKantenTyp.allCases, id: \.self) { typ in
       HStack(spacing: 8) {
         Rectangle().fill(typ.farbe).frame(width: 20, height: 2)
         Text(typ.bezeichnung).font(.caption)
       }
     }
   }
   .padding(20)
 }
 .background { VisionOSGlasFlaeche.adaptivePanel(cornerRadius: 16) }
}

private func hilfeZeile(_ symbol: String, _ titel: String, _ text: String) -> some View {
 HStack(alignment: .top, spacing: 10) {
   Image(systemName: symbol)
     .foregroundStyle(FenlynineOSTheme.accent)
     .frame(width: 20)
   VStack(alignment: .leading, spacing: 2) {
     Text(titel).font(.subheadline.weight(.semibold))
     Text(text).font(.caption).foregroundStyle(.secondary)
   }
 }
}
}

struct OrganonProfilDetailPanel: View {
let knoten: OrganonKnoten
let vm: OrganonViewModel
var onEdit: (() -> Void)? = nil

var body: some View {
 ScrollView {
   OrganonProfilInhalt(knoten: knoten, vm: vm, onEdit: onEdit)
     .padding(16)
 }
 .background { VisionOSGlasFlaeche.adaptivePanel(cornerRadius: 16) }
}
}

struct OrganonProfilSheet: View {
let knoten: OrganonKnoten
let vm: OrganonViewModel
@Environment(\.dismiss) private var dismiss

var body: some View {
 NavigationStack {
   ScrollView {
     OrganonProfilInhalt(knoten: knoten, vm: vm)
       .padding(24)
   }
   .navigationTitle(knoten.name)
   .toolbar {
     ToolbarItem(placement: .cancellationAction) {
       Button("Schließen") { dismiss() }
     }
   }
 }
 .frame(minWidth: 480, minHeight: 400)
}
}

struct OrganonProfilInhalt: View {
let knoten: OrganonKnoten
let vm: OrganonViewModel
var onEdit: (() -> Void)? = nil

var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   if let rolle = knoten.rolle {
     Text(rolle).font(.subheadline).foregroundStyle(FenlynineOSTheme.accent)
   }
   if let claim = knoten.taetigkeitsclaim {
     Text(claim).font(.body)
   }
   if let kap = knoten.kapazitaet {
     Label("Kapazität: \(kap.bezeichnung)", systemImage: "gauge")
       .font(.caption)
       .foregroundStyle(kap.farbe)
   }
   if let standort = knoten.standort {
     Label(standort, systemImage: "mappin")
       .font(.caption)
       .foregroundStyle(.secondary)
   }
   if let email = knoten.email {
     Label(email, systemImage: "envelope")
       .font(.caption)
       .foregroundStyle(.secondary)
   }

   if let matrix = knoten.skillMatrix, !matrix.isEmpty {
     VStack(alignment: .leading, spacing: 6) {
       Text("Skills").font(.caption.bold()).foregroundStyle(.secondary)
       ForEach(matrix) { s in
         HStack {
           Text(s.name).font(.caption)
           Spacer()
           Text(s.level.bezeichnung).font(.caption2).foregroundStyle(.secondary)
         }
       }
     }
   } else if let skills = knoten.skills, !skills.isEmpty {
     profilSektion("Skills", items: skills, farbe: .indigo)
   }
   if let projekte = knoten.projekte, !projekte.isEmpty {
     profilSektion("Projekte / Mandate", items: projekte, farbe: .orange)
   }
   if let tags = knoten.tags, !tags.isEmpty {
     profilSektion("Tags", items: tags, farbe: .teal)
   }
   if let notizen = knoten.notizen, !notizen.isEmpty {
     Text(notizen).font(.caption).foregroundStyle(.secondary)
   }

   let vorgaenge = vm.verknuepfteVorgaenge(fuer: knoten)
   if !vorgaenge.isEmpty {
     VStack(alignment: .leading, spacing: 4) {
       Text("Vorgänge").font(.caption.bold()).foregroundStyle(.secondary)
       ForEach(vorgaenge.prefix(5)) { v in
         Text("\(v.kurzId) · \(v.titel)")
           .font(.caption2)
           .lineLimit(1)
       }
     }
   }

   if knoten.typ != .person {
     let kinder = vm.kinder(von: knoten.id)
     if !kinder.isEmpty {
       Text("Enthält \(kinder.count) Einheiten")
         .font(.caption)
         .foregroundStyle(.secondary)
     }
   }

   HStack {
     if let onEdit {
       Button("Bearbeiten") { onEdit() }
         .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     }
     if knoten.typ == .person && !knoten.istVakanz {
       Button {
         vm.aktualisiereKapazitaetAusLast(fuer: knoten.id)
       } label: {
         Label("Kapazität sync", systemImage: "arrow.triangle.2.circlepath")
       }
       .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
     }
   }
 }
 .frame(maxWidth: .infinity, alignment: .leading)
}

private func profilSektion(_ titel: String, items: [String], farbe: Color) -> some View {
 VStack(alignment: .leading, spacing: 6) {
   Text(titel).font(.caption.bold()).foregroundStyle(.secondary)
   FlowLayout(spacing: 6) {
     ForEach(items, id: \.self) { item in
       Text(item)
         .font(.caption2)
         .padding(.horizontal, 8)
         .padding(.vertical, 4)
         .background(farbe.opacity(0.12), in: Capsule())
     }
   }
 }
}
}

