import SwiftUI
import AppKit
struct OpportunismaProJourneyView: View {
    @Bindable var vm: OpportunismaViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Setup-Journey")
                    .font(OpportunismaPro.hero)
                    .foregroundStyle(OpportunismaPro.text)
                Text("In fünf Schritten von Rohlage zu Entscheidungsreife — das Produktversprechen für Counsel & Leitung.")
                    .font(OpportunismaPro.body)
                    .foregroundStyle(OpportunismaPro.textSoft)
                    .frame(maxWidth: 560, alignment: .leading)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [OpportunismaPro.accent, OpportunismaPro.signal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * vm.journeyFortschritt)
                            .shadow(color: OpportunismaPro.accent.opacity(0.5), radius: 8, y: 0)
                    }
                }
                .frame(height: 8)
                .padding(.top, 4)
                HStack {
                    Text("\(Int(vm.journeyFortschritt * 100))% entscheidungsreif")
                        .font(OpportunismaPro.caption.weight(.semibold))
                        .foregroundStyle(vm.entscheidungsreif ? OpportunismaPro.signal : OpportunismaPro.textSoft)
                    Spacer()
                    if vm.entscheidungsreif {
                        Label("Freigabe empfohlen", systemImage: "checkmark.seal.fill")
                            .font(OpportunismaPro.caption)
                            .foregroundStyle(OpportunismaPro.signal)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opportunismaGlass(elevated: true, corner: OpportunismaPro.radiusWindow)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(Array(vm.journeySchritte.enumerated()), id: \.offset) { i, step in
                    Button { vm.selectedTab = step.tab } label: {
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(step.ok ? OpportunismaPro.signal.opacity(0.25) : OpportunismaPro.accentSoft)
                                    .frame(width: 36, height: 36)
                                if step.ok {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(OpportunismaPro.signal)
                                } else {
                                    Text("\(i + 1)")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(OpportunismaPro.accent)
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.titel)
                                    .font(OpportunismaPro.title)
                                    .foregroundStyle(OpportunismaPro.text)
                                Text(step.ok ? "Erledigt — tippen zum Öffnen" : "Offen — jetzt bearbeiten")
                                    .font(OpportunismaPro.caption)
                                    .foregroundStyle(OpportunismaPro.textSoft)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(OpportunismaPro.textFaint)
                        }
                        .padding(18)
                        .opportunismaGlass(elevated: true)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack(spacing: 12) {
                Button { vm.selectedTab = .warRoom } label: {
                    Label("War Room öffnen", systemImage: "shield.lefthalf.filled")
                }
                .buttonStyle(OpportunismaProPrimaryButton())
                .disabled(!vm.entscheidungsreif)
                .opacity(vm.entscheidungsreif ? 1 : 0.45)
                Button { vm.selectedTab = .playbooks } label: {
                    Label("Playbooks", systemImage: "book.closed.fill")
                }
                .buttonStyle(OpportunismaProGhostButton())
                Button { vm.selectedTab = .weeklyBrief } label: {
                    Label("Weekly Brief", systemImage: "newspaper.fill")
                }
                .buttonStyle(OpportunismaProGhostButton())
                Button { vm.selectedTab = .exportStudio } label: {
                    Label("Export Studio", systemImage: "square.and.arrow.up.on.square")
                }
                .buttonStyle(OpportunismaProGhostButton())
            }
        }
    }
}
struct OpportunismaProWarRoomView: View {
    @Bindable var vm: OpportunismaViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("War Room")
                        .font(OpportunismaPro.hero)
                        .foregroundStyle(OpportunismaPro.text)
                    Text("Eine Decision Surface: Lage · Gegner · Zug. Für Partner-Meetings und Krisenmoderation.")
                        .font(OpportunismaPro.body)
                        .foregroundStyle(OpportunismaPro.textSoft)
                }
                Spacer()
                OpportunismaProScoreRing(wert: vm.machtIndex, label: "Lage")
            }
            HStack(alignment: .top, spacing: 14) {
                OpportunismaProSection(titel: "Lage", untertitel: "Was wir wissen") {
                    VStack(alignment: .leading, spacing: 10) {
                        labeled("Ausgang", vm.situationText)
                        labeled("Ziel", vm.zielText)
                        HStack(spacing: 10) {
                            miniStat("Chance", "\(vm.chanceScore)")
                            miniStat("Züge offen", "\(vm.offenActions)")
                            miniStat("Risiko-Peak", "\(vm.risikoMatrix.flatMap { $0 }.max() ?? 0)")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                OpportunismaProSection(titel: "Gegner", untertitel: "Druck & Bedrohung", accent: OpportunismaPro.warn) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(vm.gegner.prefix(5)) { g in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(g.name).font(OpportunismaPro.section).foregroundStyle(OpportunismaPro.text)
                                    Text("\(g.einfluss) · \(g.kontrolle)")
                                        .font(OpportunismaPro.micro)
                                        .foregroundStyle(OpportunismaPro.textFaint)
                                }
                                Spacer()
                                Text(g.bedrohung)
                                    .font(OpportunismaPro.micro.weight(.bold))
                                    .foregroundStyle(OpportunismaPro.warn)
                            }
                            .padding(.vertical, 4)
                        }
                        Button("Wettbewerb vertiefen") { vm.selectedTab = .gegneranalyse }
                            .buttonStyle(OpportunismaProGhostButton())
                    }
                }
                .frame(maxWidth: .infinity)
                OpportunismaProSection(titel: "Nächster Zug", untertitel: "Entscheidung jetzt", accent: OpportunismaPro.signal) {
                    VStack(alignment: .leading, spacing: 10) {
                        if let top = vm.actionItems.first(where: { $0.status != .erledigt }) {
                            Text(top.titel)
                                .font(OpportunismaPro.title)
                                .foregroundStyle(OpportunismaPro.text)
                            Text(top.detail)
                                .font(OpportunismaPro.caption)
                                .foregroundStyle(OpportunismaPro.textSoft)
                            HStack {
                                Button("Als erledigt") { vm.setzeActionStatus(top.id, .erledigt) }
                                    .buttonStyle(OpportunismaProPrimaryButton())
                                Button("Modul") { vm.selectedTab = top.tab }
                                    .buttonStyle(OpportunismaProGhostButton())
                            }
                        } else {
                            Text("Keine offenen Züge — Action Board regenerieren.")
                                .font(OpportunismaPro.caption)
                                .foregroundStyle(OpportunismaPro.textSoft)
                            Button("Action Board") { vm.selectedTab = .actionBoard }
                                .buttonStyle(OpportunismaProPrimaryButton())
                        }
                        Divider().overlay(Color.white.opacity(0.1))
                        Button("Strategie-Baum") { vm.selectedTab = .machtStrategie }
                            .buttonStyle(OpportunismaProGhostButton())
                        Button("Szenarien") { vm.selectedTab = .szenarien }
                            .buttonStyle(OpportunismaProGhostButton())
                    }
                }
                .frame(width: 300)
            }
            OpportunismaProSection(titel: "Schnellpfade", untertitel: "War Room Shortcuts") {
                HStack(spacing: 10) {
                    ForEach([OpportunismaTab.hegemonogramm, .risiken, .netzwerk, .zeitplan, .exportStudio], id: \.self) { tab in
                        Button { vm.selectedTab = tab } label: {
                            Label(tab.proTitel, systemImage: tab.symbol)
                        }
                        .buttonStyle(OpportunismaProGhostButton())
                    }
                }
            }
        }
    }
    private func labeled(_ t: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(t.uppercased()).font(OpportunismaPro.micro).foregroundStyle(OpportunismaPro.textFaint).tracking(0.5)
            Text(v.isEmpty ? "—" : v).font(OpportunismaPro.caption).foregroundStyle(OpportunismaPro.textSoft).lineLimit(4)
        }
    }
    private func miniStat(_ t: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(t.uppercased()).font(OpportunismaPro.micro).foregroundStyle(OpportunismaPro.textFaint)
            Text(v).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(OpportunismaPro.text)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
struct OpportunismaProWeeklyBriefView: View {
    @Bindable var vm: OpportunismaViewModel
    @State private var kopiert = false
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weekly Brief")
                        .font(OpportunismaPro.hero)
                        .foregroundStyle(OpportunismaPro.text)
                    Text("Der wöchentliche CI-Brief für Partnerschaft und Mandatsleitung — verkaufsfähiges Lieferobjekt.")
                        .font(OpportunismaPro.body)
                        .foregroundStyle(OpportunismaPro.textSoft)
                        .frame(maxWidth: 520, alignment: .leading)
                }
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(vm.weeklyBriefMarkdown(), forType: .string)
                    kopiert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { kopiert = false }
                } label: {
                    Label(kopiert ? "Kopiert" : "Brief kopieren", systemImage: kopiert ? "checkmark" : "doc.on.clipboard")
                }
                .buttonStyle(OpportunismaProPrimaryButton())
            }
            HStack(spacing: 14) {
                OpportunismaProMetricTile(label: "Position", value: "\(vm.machtIndex)")
                OpportunismaProMetricTile(label: "Chance", value: "\(vm.chanceScore)", tone: OpportunismaPro.signal)
                OpportunismaProMetricTile(label: "Offene Züge", value: "\(vm.offenActions)", tone: OpportunismaPro.warn)
                OpportunismaProMetricTile(label: "Setup", value: "\(Int(vm.journeyFortschritt * 100))%", hint: vm.entscheidungsreif ? "reif" : "offen", tone: vm.entscheidungsreif ? OpportunismaPro.signal : OpportunismaPro.warn)
            }
            OpportunismaProSection(titel: "Vorschau", untertitel: "Markdown — so landet es bei der Leitung") {
                ScrollView {
                    Text(vm.weeklyBriefMarkdown())
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(OpportunismaPro.textSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(minHeight: 280)
            }
        }
    }
}
struct OpportunismaProExportStudioView: View {
    @Bindable var vm: OpportunismaViewModel
    @State private var status = ""
    @State private var preview = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Export Studio")
                .font(OpportunismaPro.hero)
                .foregroundStyle(OpportunismaPro.text)
            Text("Sechs Lieferformate — Board, Weekly, Counsel, Krise, Beirat, Mandatsmemo.")
                .font(OpportunismaPro.body)
                .foregroundStyle(OpportunismaPro.textSoft)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(OpportunismaExportPack.allCases) { pack in
                    Button {
                        let md = vm.exportMarkdown(fuer: pack)
                        preview = md
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(md, forType: .string)
                        status = "\(pack.titel) kopiert"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { status = "" }
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: pack.symbol)
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(OpportunismaPro.accent)
                            Text(pack.titel)
                                .font(OpportunismaPro.title)
                                .foregroundStyle(OpportunismaPro.text)
                            Text(pack.detail)
                                .font(OpportunismaPro.caption)
                                .foregroundStyle(OpportunismaPro.textSoft)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Kopieren")
                                .font(OpportunismaPro.micro.weight(.bold))
                                .foregroundStyle(OpportunismaPro.accent)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
                        .opportunismaGlass(elevated: true)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            if !status.isEmpty {
                Label(status, systemImage: "checkmark.circle.fill")
                    .font(OpportunismaPro.caption)
                    .foregroundStyle(OpportunismaPro.signal)
            }
            if !preview.isEmpty {
                OpportunismaProSection(titel: "Vorschau", untertitel: "Zuletzt kopiert") {
                    ScrollView {
                        Text(preview)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(OpportunismaPro.textSoft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(minHeight: 160)
                }
            }
            OpportunismaProSection(titel: "Weiter", untertitel: "Nach dem Export") {
                HStack(spacing: 10) {
                    Button("War Room") { vm.selectedTab = .warRoom }.buttonStyle(OpportunismaProGhostButton())
                    Button("Dossier") { vm.selectedTab = .dossier }.buttonStyle(OpportunismaProGhostButton())
                    Button("Action Board") { vm.selectedTab = .actionBoard }.buttonStyle(OpportunismaProGhostButton())
                }
            }
        }
    }
}
struct OpportunismaProWettbewerbView: View {
    @Bindable var vm: OpportunismaViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header("Wettbewerb", "Peer-Druck und Bedrohung — Grundlage für Sector-CI und Pitch-Differenzierung.")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(vm.gegner) { g in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(g.name).font(OpportunismaPro.title).foregroundStyle(OpportunismaPro.text)
                            Spacer()
                            Text(g.bedrohung.uppercased())
                                .font(OpportunismaPro.micro)
                                .foregroundStyle(OpportunismaPro.warn)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Capsule().fill(OpportunismaPro.warn.opacity(0.15)))
                        }
                        labeled("Einfluss", g.einfluss)
                        labeled("Kontrolle", g.kontrolle)
                        Button("Als Action") {
                            vm.actionItems.insert(
                                .init(titel: "Gegen \(g.name) positionieren", detail: g.bedrohung, status: .offen, prio: .hoch, tab: .gegneranalyse),
                                at: 0
                            )
                            vm.selectedTab = .actionBoard
                        }
                        .buttonStyle(OpportunismaProGhostButton())
                    }
                    .padding(16)
                    .opportunismaGlass(elevated: true)
                }
            }
            if vm.gegner.isEmpty {
                empty("Keine Wettbewerber — KI-Lageanalyse oder Fragebogen.")
            }
        }
    }
    private func labeled(_ t: String, _ v: String) -> some View {
        HStack {
            Text(t).font(OpportunismaPro.micro).foregroundStyle(OpportunismaPro.textFaint)
            Spacer()
            Text(v).font(OpportunismaPro.caption).foregroundStyle(OpportunismaPro.textSoft)
        }
    }
}
struct OpportunismaProRisikenView: View {
    @Bindable var vm: OpportunismaViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header("Risiken", "Heatmap Impact × Wahrscheinlichkeit — Resilienz für Board und Counsel.")
            let peak = vm.risikoMatrix.flatMap { $0 }.max() ?? 0
            HStack(spacing: 14) {
                OpportunismaProMetricTile(label: "Peak", value: "\(peak)", hint: peak >= 4 ? "kritisch" : "moderat", tone: peak >= 4 ? OpportunismaPro.danger : OpportunismaPro.warn)
                OpportunismaProMetricTile(label: "Felder", value: "\(vm.risikoMatrix.count * (vm.risikoMatrix.first?.count ?? 0))", hint: "Matrix")
                OpportunismaProMetricTile(label: "Offene Mitigations", value: "\(vm.offenActions)", hint: "Action Board")
            }
            OpportunismaProSection(titel: "Heatmap", untertitel: "Klassische Risikomatrix") {
                PragRisikoHeatmap(matrix: vm.risikoMatrix)
                    .frame(minHeight: 220)
            }
            Button("Mitigation ins Action Board") {
                vm.actionItems.insert(
                    .init(titel: "Kritisches Risikofeld mitigieren", detail: "Peak \(peak) — Resilienzplan", status: .offen, prio: .hoch, tab: .risiken),
                    at: 0
                )
                vm.selectedTab = .actionBoard
            }
            .buttonStyle(OpportunismaProPrimaryButton())
        }
    }
}
struct OpportunismaProSzenarienView: View {
    @Bindable var vm: OpportunismaViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header("Szenarien", "Pfade vergleichen — Wahrscheinlichkeit × Kontrolle.")
            ForEach(vm.szenarien) { s in
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(s.name).font(OpportunismaPro.title).foregroundStyle(OpportunismaPro.text)
                        Text("P(Erfolg) \(s.wahrscheinlichkeit)% · Kontrolle \(s.kontrolle)% · \(s.ergebnis)")
                            .font(OpportunismaPro.caption)
                            .foregroundStyle(OpportunismaPro.textSoft)
                    }
                    Spacer()
                    ProgressView(value: Double(s.wahrscheinlichkeit) / 100)
                        .tint(OpportunismaPro.accent)
                        .frame(width: 120)
                    Button("Als Zug") {
                        vm.actionItems.insert(
                            .init(titel: "Szenario „\(s.name)“ verfolgen", detail: "P=\(s.wahrscheinlichkeit)%", status: .offen, prio: .mittel, tab: .szenarien),
                            at: 0
                        )
                        vm.selectedTab = .actionBoard
                    }
                    .buttonStyle(OpportunismaProGhostButton())
                }
                .padding(16)
                .opportunismaGlass(elevated: true)
            }
        }
    }
}
struct OpportunismaProStakeholderView: View {
    @Bindable var vm: OpportunismaViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header("Stakeholder-CRM", "Beziehungen mit Rolle, Stance und nächstem Zug — nicht nur eine Karte.")
            HStack(spacing: 14) {
                ForEach(["kontrolliert", "verbündet", "neutral", "feindlich"], id: \.self) { typ in
                    let n = vm.netzKnoten.filter { $0.typ == typ }.count
                    OpportunismaProMetricTile(
                        label: typ.capitalized,
                        value: "\(n)",
                        hint: "Knoten",
                        tone: typ == "feindlich" ? OpportunismaPro.danger : (typ == "verbündet" ? OpportunismaPro.signal : OpportunismaPro.accent)
                    )
                }
            }
            OpportunismaProSection(titel: "Kontaktbuch", untertitel: "Priorisierte Ansprache") {
                ForEach(vm.kontakte.sorted(by: { $0.prioritaet > $1.prioritaet })) { k in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(k.name).font(OpportunismaPro.title).foregroundStyle(OpportunismaPro.text)
                            Text("\(k.rolle) · \(k.organisation)")
                                .font(OpportunismaPro.caption)
                                .foregroundStyle(OpportunismaPro.textSoft)
                            Text(k.stance)
                                .font(OpportunismaPro.micro)
                                .foregroundStyle(OpportunismaPro.accent)
                            if !k.notiz.isEmpty {
                                Text(k.notiz).font(OpportunismaPro.micro).foregroundStyle(OpportunismaPro.textFaint)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("\(k.prioritaet)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(OpportunismaPro.text)
                            Text(k.naechsterZug)
                                .font(OpportunismaPro.micro)
                                .foregroundStyle(OpportunismaPro.textSoft)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 160, alignment: .trailing)
                            Button("Als Action") {
                                vm.actionItems.insert(
                                    .init(titel: k.naechsterZug, detail: "\(k.name) · \(k.rolle)", status: .offen, prio: k.prioritaet >= 85 ? .hoch : .mittel, tab: .netzwerk, owner: "PA"),
                                    at: 0
                                )
                                vm.speichereProSession()
                                vm.selectedTab = .actionBoard
                            }
                            .buttonStyle(OpportunismaProGhostButton())
                        }
                    }
                    .padding(14)
                    .opportunismaGlass(elevated: true)
                }
            }
            OpportunismaProSection(titel: "Karte", untertitel: "Lage der Akteure") {
                PragNetzwerkGraph(knoten: vm.netzKnoten, kanten: vm.netzKanten)
                    .frame(minHeight: 220)
            }
        }
    }
}
struct OpportunismaProAkteureView: View {
    @Bindable var vm: OpportunismaViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header("Akteure", "Institutionelle Schlüsselpersonen — Ansprache und Einfluss.")
            let akteure = vm.aktivesSzenario.akteure
            if akteure.isEmpty {
                empty("Keine Akteure — Fragebogen oder KI-Lageanalyse.")
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(akteure, id: \.self) { a in
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(OpportunismaPro.accent)
                            Text(a)
                                .font(OpportunismaPro.title)
                                .foregroundStyle(OpportunismaPro.text)
                                .fixedSize(horizontal: false, vertical: true)
                            Button("In Action Board") {
                                vm.actionItems.insert(
                                    .init(titel: "Akteur \(a) ansprechen", detail: "Schlüsselperson im Szenario", status: .offen, prio: .hoch, tab: .zielpersonen),
                                    at: 0
                                )
                                vm.selectedTab = .actionBoard
                            }
                            .buttonStyle(OpportunismaProGhostButton())
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
                        .opportunismaGlass(elevated: true)
                    }
                }
            }
        }
    }
}
struct OpportunismaProUmsetzungsplanView: View {
    @Bindable var vm: OpportunismaViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header("Umsetzungsplan", "Meilensteine mit Druck — aus Strategie wird Kalender.")
            HStack(spacing: 14) {
                OpportunismaProMetricTile(label: "Meilensteine", value: "\(vm.meilensteine.count)")
                OpportunismaProMetricTile(label: "Offene Züge", value: "\(vm.offenActions)", tone: OpportunismaPro.warn)
                OpportunismaProMetricTile(label: "Ziele", value: "\(vm.strategischeZiele.count)", tone: OpportunismaPro.signal)
            }
            OpportunismaProSection(titel: "Gantt", untertitel: "Zeithorizont") {
                PragGantt(meilensteine: vm.meilensteine, gesamtMonate: 10)
                    .frame(minHeight: 160)
            }
            OpportunismaProSection(titel: "Meilenstein-Board", untertitel: "Direkt in Ausführung überführen") {
                ForEach(vm.meilensteine) { m in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.titel).font(OpportunismaPro.section).foregroundStyle(OpportunismaPro.text)
                            Text("Monat \(m.start) · Dauer \(m.dauer)")
                                .font(OpportunismaPro.micro)
                                .foregroundStyle(OpportunismaPro.textFaint)
                        }
                        Spacer()
                        Button("Als Action") {
                            vm.actionItems.insert(
                                .init(titel: m.titel, detail: "Meilenstein M\(m.start)+ \(m.dauer)", status: .offen, prio: .mittel, tab: .zeitplan),
                                at: 0
                            )
                            vm.selectedTab = .actionBoard
                        }
                        .buttonStyle(OpportunismaProGhostButton())
                    }
                    .padding(12)
                    .opportunismaGlass(elevated: true)
                }
            }
        }
    }
}
struct OpportunismaProDossierView: View {
    @Bindable var vm: OpportunismaViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header("Unternehmens-Dossier", "Gesamtsicht für Mandant, Board und Counsel.")
            HStack(spacing: 14) {
                OpportunismaProMetricTile(label: "Position", value: "\(vm.machtIndex)%")
                OpportunismaProMetricTile(label: "Setup", value: "\(Int(vm.journeyFortschritt * 100))%", hint: vm.entscheidungsreif ? "reif" : "offen", tone: vm.entscheidungsreif ? OpportunismaPro.signal : OpportunismaPro.warn)
                OpportunismaProMetricTile(label: "Chancen", value: "\(vm.chancen.count)", tone: OpportunismaPro.signal)
                OpportunismaProMetricTile(label: "Actions", value: "\(vm.offenActions)", tone: OpportunismaPro.accent)
            }
            OpportunismaProSection(titel: "Lage-Synopsis", untertitel: "Fragebogen / KI") {
                Text(vm.fragebogenZusammenfassung ?? vm.kiAnalyse ?? "Starten Sie den Lagefragebogen oder eine KI-Lageanalyse.")
                    .font(OpportunismaPro.body)
                    .foregroundStyle(OpportunismaPro.textSoft)
                    .textSelection(.enabled)
            }
            if !vm.kausalitaeten.isEmpty {
                OpportunismaProSection(titel: "Kausalitäten", untertitel: "Ursache → Wirkung") {
                    PragKausalitaetenTabelle(zeilen: vm.kausalitaeten)
                }
            }
            if !vm.prognosen.isEmpty {
                OpportunismaProSection(titel: "Prognosen", untertitel: "Fragebogen / KI") {
                    ForEach(vm.prognosen.prefix(6)) { p in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.option).font(OpportunismaPro.section).foregroundStyle(OpportunismaPro.text)
                            Text("→ \(p.fuehrt_zu) · P=\(p.wahrscheinlichkeit)% · \(p.dimension)")
                                .font(OpportunismaPro.caption)
                                .foregroundStyle(OpportunismaPro.textSoft)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            OpportunismaProSection(titel: "Strategische Ziele", untertitel: "Fortschritt") {
                OpportunismaProZieleView(vm: vm)
            }
            HStack(spacing: 10) {
                Button { vm.selectedTab = .weeklyBrief } label: { Label("Weekly Brief", systemImage: "newspaper.fill") }
                    .buttonStyle(OpportunismaProPrimaryButton())
                Button { vm.selectedTab = .exportStudio } label: { Label("Export Studio", systemImage: "square.and.arrow.up.on.square") }
                    .buttonStyle(OpportunismaProGhostButton())
                Button { vm.selectedTab = .warRoom } label: { Label("War Room", systemImage: "shield.lefthalf.filled") }
                    .buttonStyle(OpportunismaProGhostButton())
            }
        }
    }
}
private func header(_ titel: String, _ unter: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(titel).font(OpportunismaPro.display).foregroundStyle(OpportunismaPro.text)
        Text(unter).font(OpportunismaPro.caption).foregroundStyle(OpportunismaPro.textSoft)
    }
}
private func empty(_ t: String) -> some View {
    Text(t)
        .font(OpportunismaPro.caption)
        .foregroundStyle(OpportunismaPro.textFaint)
        .padding(24)
        .frame(maxWidth: .infinity)
        .opportunismaGlass()
}
