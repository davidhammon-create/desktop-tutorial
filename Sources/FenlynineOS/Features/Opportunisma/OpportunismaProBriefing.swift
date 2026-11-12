import SwiftUI
import AppKit
struct OpportunismaProBriefingView: View {
    @Bindable var vm: OpportunismaViewModel
    @State private var kopiert = false
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            hero
            HStack(alignment: .top, spacing: 14) {
                lageKarte
                naechsteZuege
            }
            HStack(alignment: .top, spacing: 14) {
                wettbewerbKarte
                risikenKarte
                intelKarte
            }
            boardPackLeiste
            if let tipp = vm.kiTipp, !tipp.isEmpty {
                OpportunismaProSection(titel: "KI-Hinweis", untertitel: "Transparente Ableitung") {
                    Text(tipp)
                        .font(OpportunismaPro.body)
                        .foregroundStyle(OpportunismaPro.textSoft)
                        .lineSpacing(5)
                }
            }
        }
    }
    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OPPORTUNISMA")
                .font(OpportunismaPro.micro)
                .tracking(1.6)
                .foregroundStyle(OpportunismaPro.accent)
            Text("Competitive Intelligence,\ndie Entscheidungen trägt.")
                .font(OpportunismaPro.hero)
                .foregroundStyle(OpportunismaPro.text)
                .fixedSize(horizontal: false, vertical: true)
            Text("Counsel · BD · Strategie: Lage → Hebel → nächste Züge. CI als Liefergegenstand für Board und Mandatsleitung — nicht als Dashboard-Archiv.")
                .font(OpportunismaPro.body)
                .foregroundStyle(OpportunismaPro.textSoft)
                .frame(maxWidth: 560, alignment: .leading)
            HStack(spacing: 10) {
                Button {
                    vm.selectedTab = .fragebogen
                } label: {
                    Label(vm.fragebogenAbgeschlossen ? "Fragebogen öffnen" : "Lagefragebogen starten", systemImage: "list.bullet.clipboard")
                }
                .buttonStyle(OpportunismaProPrimaryButton())
                Button {
                    Task { await OpportunismaService.analysiereLage(vm: vm) }
                } label: {
                    if vm.kiLaeuft { ProgressView().controlSize(.small) }
                    else { Label("KI-Lageanalyse", systemImage: "wand.and.stars") }
                }
                .buttonStyle(OpportunismaProGhostButton())
                .disabled(vm.kiLaeuft || !vm.kiBereit)
                Button { vm.selectedTab = .actionBoard } label: {
                    Label("Action Board", systemImage: "rectangle.3.group")
                }
                .buttonStyle(OpportunismaProGhostButton())
                Button { vm.selectedTab = .chancen } label: {
                    Label("Chancenradar", systemImage: "scope")
                }
                .buttonStyle(OpportunismaProGhostButton())
                Button { vm.berechneAusEingaben() } label: {
                    Label("Index berechnen", systemImage: "function")
                }
                .buttonStyle(OpportunismaProGhostButton())
                .help("Machtindex aus Fragebogen, Hegemonogramm, Hebeln und Strategos — ohne Zufall.")
                Button { vm.ladeDemoDaten() } label: {
                    Label("Demo laden", systemImage: "square.stack.3d.up")
                }
                .buttonStyle(OpportunismaProGhostButton())
                .help("Nur zur Illustration. Ersetzt keine Berechnung aus Eingaben.")
            }
        }
        .padding(26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .opportunismaGlass(elevated: true, corner: OpportunismaPro.radiusWindow)
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(OpportunismaPro.accent.opacity(0.22))
                .frame(width: 160, height: 160)
                .blur(radius: 40)
                .offset(x: 40, y: -30)
                .allowsHitTesting(false)
        }
    }
    private var lageKarte: some View {
        OpportunismaProSection(titel: "Lage auf einen Blick", untertitel: "30 Sekunden für das Board") {
            HStack(alignment: .center, spacing: 18) {
                OpportunismaProScoreRing(wert: vm.machtIndex)
                VStack(alignment: .leading, spacing: 8) {
                    labeled("Ausgangslage", text: kurz(vm.situationText, fallback: "Noch keine Ausgangslage — Fragebogen oder Strategos-Link."))
                    labeled("Ziel", text: kurz(vm.zielText, fallback: "Ziel noch offen."))
                    if vm.fragebogenAbgeschlossen {
                        Label("Fragebogen abgeschlossen", systemImage: "checkmark.seal.fill")
                            .font(OpportunismaPro.caption)
                            .foregroundStyle(OpportunismaPro.signal)
                    } else {
                        Label("Fragebogen offen — Graphen bleiben grob", systemImage: "exclamationmark.triangle.fill")
                            .font(OpportunismaPro.caption)
                            .foregroundStyle(OpportunismaPro.warn)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
    }
    private var naechsteZuege: some View {
        OpportunismaProSection(titel: "Nächste 3 Züge", untertitel: "Handlung vor Analyse-Flut", accent: OpportunismaPro.signal) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(empfohleneZuege.enumerated()), id: \.offset) { i, zug in
                    Button { vm.selectedTab = zug.tab } label: {
                        HStack(spacing: 10) {
                            Text("\(i + 1)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(OpportunismaPro.accent))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(zug.titel)
                                    .font(OpportunismaPro.caption.weight(.semibold))
                                    .foregroundStyle(OpportunismaPro.text)
                                Text(zug.detail)
                                    .font(OpportunismaPro.micro)
                                    .foregroundStyle(OpportunismaPro.textFaint)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(OpportunismaPro.textFaint)
                        }
                        .padding(11)
                        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 340)
    }
    private var wettbewerbKarte: some View {
        OpportunismaProSection(titel: "Wettbewerb", untertitel: "Top-Signale") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(vm.gegner.prefix(4)) { g in
                    HStack {
                        Text(g.name).font(OpportunismaPro.caption).foregroundStyle(OpportunismaPro.text).lineLimit(1)
                        Spacer()
                        Text(g.bedrohung).font(OpportunismaPro.micro).foregroundStyle(OpportunismaPro.warn)
                    }
                }
                if vm.gegner.isEmpty {
                    Text("Noch keine Wettbewerber — KI-Lageanalyse oder Fragebogen.")
                        .font(OpportunismaPro.caption)
                        .foregroundStyle(OpportunismaPro.textFaint)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    private var risikenKarte: some View {
        OpportunismaProSection(titel: "Risiko-Signal", untertitel: "Heatmap-Spitze", accent: OpportunismaPro.danger) {
            let peak = vm.risikoMatrix.flatMap { $0 }.max() ?? 0
            HStack(spacing: 14) {
                Text("\(peak)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(peak >= 4 ? OpportunismaPro.danger : OpportunismaPro.warn)
                VStack(alignment: .leading, spacing: 4) {
                    Text(peak >= 4 ? "Kritisches Feld aktiv" : "Moderate Belastung")
                        .font(OpportunismaPro.caption.weight(.semibold))
                        .foregroundStyle(OpportunismaPro.text)
                    Button("Risiken öffnen") { vm.selectedTab = .risiken }
                        .buttonStyle(OpportunismaProGhostButton())
                        .padding(.top, 4)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
    }
    private var intelKarte: some View {
        OpportunismaProSection(titel: "Intelligence & Delivery", untertitel: "Module mit Lieferwert", accent: OpportunismaPro.accent) {
            VStack(alignment: .leading, spacing: 8) {
                Button { vm.selectedTab = .journey } label: {
                    Label("Setup-Journey · \(Int(vm.journeyFortschritt * 100))%", systemImage: "map.fill")
                }
                .buttonStyle(OpportunismaProGhostButton())
                Button { vm.selectedTab = .warRoom } label: {
                    Label("War Room", systemImage: "shield.lefthalf.filled")
                }
                .buttonStyle(OpportunismaProGhostButton())
                Button { vm.selectedTab = .feed } label: {
                    Label("CI-Feed öffnen", systemImage: "dot.radiowaves.up.forward")
                }
                .buttonStyle(OpportunismaProGhostButton())
                Button { vm.selectedTab = .chancen } label: {
                    Label("Chancenradar · Score \(vm.chanceScore)", systemImage: "scope")
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
                Text("\(vm.feedEvents.count) Ereignisse · \(vm.chancen.count) Chancen · Setup \(Int(vm.journeyFortschritt * 100))%")
                    .font(OpportunismaPro.micro)
                    .foregroundStyle(OpportunismaPro.textFaint)
            }
        }
        .frame(width: 280)
    }
    private var boardPackLeiste: some View {
        OpportunismaProSection(titel: "Board Pack", untertitel: "Eine Seite für Mandatsleitung / Beirat") {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Markdown-Briefing in die Zwischenablage")
                        .font(OpportunismaPro.caption.weight(.semibold))
                        .foregroundStyle(OpportunismaPro.text)
                    Text("Position \(vm.machtIndex)% · Chance \(vm.chanceScore) · \(vm.offenActions) offene Züge")
                        .font(OpportunismaPro.micro)
                        .foregroundStyle(OpportunismaPro.textFaint)
                }
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(boardPackMarkdown(), forType: .string)
                    withAnimation { kopiert = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { kopiert = false }
                } label: {
                    Label(kopiert ? "Kopiert" : "Board Pack kopieren", systemImage: kopiert ? "checkmark" : "doc.on.clipboard")
                }
                .buttonStyle(OpportunismaProPrimaryButton())
                Button { vm.selectedTab = .dossier } label: {
                    Label("Volles Dossier", systemImage: "doc.text")
                }
                .buttonStyle(OpportunismaProGhostButton())
            }
        }
    }
    private struct Zug {
        let titel: String
        let detail: String
        let tab: OpportunismaTab
    }
    private var empfohleneZuege: [Zug] {
        var z: [Zug] = []
        if !vm.fragebogenAbgeschlossen {
            z.append(.init(titel: "Lagefragebogen schließen", detail: "Ohne Struktur bleiben Prognosen weich.", tab: .fragebogen))
        }
        z.append(.init(titel: "Action Board abarbeiten", detail: "\(vm.offenActions) offene Züge.", tab: .actionBoard))
        z.append(.init(titel: "Chancen priorisieren", detail: "Sector-Score \(vm.chanceScore).", tab: .chancen))
        z.append(.init(titel: "Strategie-Zug wählen", detail: "Wirksamkeit vs. Risiko.", tab: .machtStrategie))
        return Array(z.prefix(3))
    }
    private func labeled(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(OpportunismaPro.micro)
                .foregroundStyle(OpportunismaPro.textFaint)
                .tracking(0.5)
            Text(text)
                .font(OpportunismaPro.caption)
                .foregroundStyle(OpportunismaPro.textSoft)
                .lineLimit(3)
        }
    }
    private func kurz(_ s: String, fallback: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? fallback : t
    }
    private func boardPackMarkdown() -> String {
        let ziele = vm.strategischeZiele.prefix(5).map { "- \($0.ziel) (\($0.status), \($0.fortschritt)%)" }.joined(separator: "\n")
        let gegner = vm.gegner.prefix(5).map { "- \($0.name): \($0.bedrohung)" }.joined(separator: "\n")
        let chancen = vm.chancen.prefix(4).map { "- [\($0.score)] \($0.titel) (\($0.sektor))" }.joined(separator: "\n")
        let actions = vm.actionItems.filter { $0.status != .erledigt }.prefix(5).map { "- \($0.titel) · \($0.prio.label)" }.joined(separator: "\n")
        return """
        # Opportunisma Board Pack
        Generiert: \(ISO8601DateFormatter().string(from: Date()))
        ## Kennzahlen
        - Positionsindex: **\(vm.machtIndex)%**
        - Chance Ø: **\(vm.chanceScore)**
        - Offene Züge: **\(vm.offenActions)**
        ## Ausgangslage
        \(kurz(vm.situationText, fallback: "—"))
        ## Ziel
        \(kurz(vm.zielText, fallback: "—"))
        ## Strategische Ziele
        \(ziele.isEmpty ? "- —" : ziele)
        ## Wettbewerb
        \(gegner.isEmpty ? "- —" : gegner)
        ## Chancen (Sector)
        \(chancen.isEmpty ? "- —" : chancen)
        ## Action Board
        \(actions.isEmpty ? "- —" : actions)
        ## KI-Tipp
        \(vm.kiTipp ?? "—")
        ---
        FenlynineOS Legal Suite · Opportunisma CI Strategy Desk
        """
    }
}
