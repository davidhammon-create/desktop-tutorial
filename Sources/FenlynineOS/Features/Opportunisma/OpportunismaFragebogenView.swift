import SwiftUI
struct OpportunismaFragebogenView: View {
    @Bindable var vm: OpportunismaViewModel
    @Environment(\.opportunismaProMode) private var proMode
    private var ink: Color { proMode ? OpportunismaPro.text : OpportunismaTheme.ink }
    private var gray: Color { proMode ? OpportunismaPro.textSoft : OpportunismaTheme.gray }
    private var accent: Color { proMode ? OpportunismaPro.accent : OpportunismaTheme.red }
    var body: some View {
        VStack(spacing: 0) {
            fragebogenKopf
            switch vm.fragebogenPhase {
            case .fragen:
                if vm.fragebogenSchrittIndex >= vm.fragebogenSchritte.count {
                    reviewSchritt
                } else {
                    schrittInhalt(vm.aktuellerFragebogenSchritt)
                }
            case .auswertung, .abgeschlossen:
                ergebnisAnsicht
            }
        }
    }
    private var fragebogenKopf: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(proMode ? "Lagefragebogen" : "LAGEFRAGEBOGEN")
                    .font(proMode ? OpportunismaPro.title : .system(size: 14, weight: .black))
                    .foregroundStyle(ink)
                Spacer()
                if vm.fragebogenPhase == .fragen {
                    Text("Schritt \(min(vm.fragebogenSchrittIndex + 1, vm.fragebogenSchritte.count + 1)) / \(vm.fragebogenSchritte.count + 1)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(gray)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(proMode ? Color.white.opacity(0.12) : OpportunismaTheme.grayLight)
                    Capsule()
                        .fill(accent)
                        .frame(width: geo.size.width * vm.fragebogenFortschritt)
                        .shadow(color: accent.opacity(proMode ? 0.45 : 0), radius: 6, y: 0)
                }
            }
            .frame(height: proMode ? 5 : 4)
            Text(proMode
                 ? "Strukturierte Lageaufnahme — jede Antwort speist Module, Kausalitäten und Prognosen."
                 : "Unternehmenslage erfassen (Multiple Choice) — alle Module werden verknüpft befüllt. Erweiterung von Strategos.")
                .font(.system(size: 9))
                .foregroundStyle(gray)
        }
        .padding(.bottom, 16)
    }
    private func schrittInhalt(_ schritt: PragFragebogenSchritt) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(schritt.titel)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(accent)
                Text(schritt.untertitel)
                    .font(.system(size: 10))
                    .foregroundStyle(gray)
                if let sg = schritt.strategosBezug {
                    Label(sg, systemImage: "link")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(accent)
                }
            }
            ForEach(schritt.fragen) { frage in
                PragFrageKarte(vm: vm, frage: frage)
            }
            navigationLeiste(istReview: false)
        }
    }
    private var reviewSchritt: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ZUSAMMENFASSUNG")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(OpportunismaTheme.red)
            Text("Prüfen Sie Ihre Antworten. Opportunisma wertet sie aus, befüllt alle Module und zeigt Kausalitäten, Prognosen und beeinflussbare vs. feste Faktoren für das Unternehmen.")
                .font(.system(size: 10))
                .foregroundStyle(OpportunismaTheme.gray)
            ForEach(OpportunismaFragebogenBank.alleFragen(fuer: vm.verknuepftesStrategos)) { frage in
                let a = vm.antwort(fuer: frage.id)
                if a.istAusgefuellt {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(frage.text)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(OpportunismaTheme.ink)
                        Text(a.zusammenfassung(optionen: frage.optionen))
                            .font(.system(size: 10))
                            .foregroundStyle(OpportunismaTheme.gray)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .pragCardStyle()
                }
            }
            if vm.fragebogenLaeuft {
                HStack(spacing: 12) {
                    ProgressView().scaleEffect(0.8).tint(OpportunismaTheme.red)
                    Text("Opportunisma analysiert Lage, Kausalitäten und Prognosen …")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(OpportunismaTheme.ink)
                }
                .padding(.vertical, 8)
            }
            navigationLeiste(istReview: true)
        }
    }
    private var ergebnisAnsicht: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(OpportunismaTheme.red)
                Text("LAGEBILD & KAUSALITÄTEN")
                    .font(.system(size: 16, weight: .black))
            }
            if let summary = vm.fragebogenZusammenfassung {
                PragWidgetCard(titel: "Executive Summary", transparenz: .opportunismaKI(
                    titel: "Fragebogen-Auswertung",
                    begruendung: "KI-Synthese aller Fragebogen-Antworten",
                    ausgabe: summary
                )) {
                    Text(summary)
                        .font(.system(size: 11))
                        .foregroundStyle(OpportunismaTheme.gray)
                        .lineSpacing(4)
                }
            }
            if !vm.kausalitaeten.isEmpty {
                PragWidgetCard(titel: "Kausalitäten — Ursache → Wirkung", transparenz: .opportunismaWidget(
                    titel: "Kausalitäts-Matrix",
                    formel: "Ursache → Wirkung × Beeinflussbarkeit × Bewertung",
                    begruendung: "Welche Faktoren führen wohin — und was kann das Unternehmen steuern?",
                    ergebnis: "\(vm.kausalitaeten.count) Ketten"
                )) {
                    PragKausalitaetenTabelle(zeilen: vm.kausalitaeten)
                }
            }
            if !vm.prognosen.isEmpty {
                PragWidgetCard(titel: "Situations-Prognosen", transparenz: .opportunismaWidget(
                    titel: "Prognose-Matrix",
                    formel: "Situation × Option → Folge (P × Kontrolle)",
                    begruendung: "Welche Lage führt zu welchen Vorteilen oder Risiken?",
                    ergebnis: "\(vm.prognosen.count) Pfade"
                )) {
                    PragPrognosenTabelle(zeilen: vm.prognosen)
                }
            }
            HStack(spacing: 12) {
                Button {
                    vm.selectedTab = .uebersicht
                } label: {
                    Label("Zum Dashboard", systemImage: "square.grid.2x2")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .tint(OpportunismaTheme.red)
                Button {
                    vm.selectedTab = .strategosLink
                } label: {
                    Label("Strategos-Verknüpfung", systemImage: "link.circle")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                Button {
                    vm.selectedTab = .machtStrategie
                } label: {
                    Label("Strategie-Baum", systemImage: "arrow.triangle.branch")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                Button("Fragebogen neu starten") {
                    vm.fragebogenZuruecksetzen()
                }
                .font(.system(size: 10))
                .foregroundStyle(OpportunismaTheme.gray)
                .buttonStyle(.plain)
            }
        }
    }
    private func navigationLeiste(istReview: Bool) -> some View {
        HStack {
            if vm.fragebogenSchrittIndex > 0 || istReview {
                Button {
                    if istReview {
                        vm.fragebogenSchrittIndex = vm.fragebogenSchritte.count - 1
                    } else {
                        vm.fragebogenSchrittIndex -= 1
                    }
                } label: {
                    Label("Zurück", systemImage: "chevron.left")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
            }
            Spacer()
            if istReview {
                Button {
                    Task { await OpportunismaService.auswertenFragebogen(vm: vm) }
                } label: {
                    Label(vm.fragebogenLaeuft ? "Analysiere …" : "Opportunisma auswerten", systemImage: "wand.and.stars")
                        .font(.system(size: 11, weight: .black))
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .tint(OpportunismaTheme.red)
                .disabled(vm.fragebogenLaeuft || !vm.kiBereit)
            } else {
                Button {
                    vm.fragebogenSchrittIndex += 1
                } label: {
                    Label(
                        vm.fragebogenSchrittIndex >= vm.fragebogenSchritte.count - 1 ? "Zur Zusammenfassung" : "Weiter",
                        systemImage: "chevron.right"
                    )
                    .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .tint(OpportunismaTheme.red)
                .disabled(!vm.fragebogenKannWeiter)
            }
        }
        .padding(.top, 8)
    }
}
struct PragFrageKarte: View {
    @Bindable var vm: OpportunismaViewModel
    let frage: PragFrage
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(frage.text)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(OpportunismaTheme.ink)
                Spacer()
                if !frage.module.isEmpty {
                    Text(frage.module.map(\.titel).joined(separator: " · "))
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(OpportunismaTheme.gray)
                        .lineLimit(1)
                }
            }
            if let h = frage.hinweis {
                Text(h).font(.system(size: 9)).foregroundStyle(OpportunismaTheme.gray)
            }
            VStack(spacing: 6) {
                ForEach(frage.optionen) { opt in
                    let selected = vm.antwort(fuer: frage.id).optionId == opt.id
                    Button {
                        var a = PragFrageAntwort()
                        a.optionId = opt.id
                        vm.setAntwort(a, fuer: frage.id)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(selected ? OpportunismaTheme.red : OpportunismaTheme.gray)
                                .font(.system(size: 12))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(opt.label)
                                    .font(.system(size: 10, weight: selected ? .bold : .medium))
                                    .foregroundStyle(OpportunismaTheme.ink)
                                if let d = opt.detail {
                                    Text(d).font(.system(size: 8)).foregroundStyle(OpportunismaTheme.gray)
                                }
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(selected ? OpportunismaTheme.red.opacity(0.12) : OpportunismaTheme.card, in: OpportunismaTheme.buttonShape)
                        .overlay(OpportunismaTheme.buttonShape.stroke(selected ? OpportunismaTheme.red : OpportunismaTheme.line))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .pragCardStyle()
    }
}
struct PragKausalitaetenTabelle: View {
    let zeilen: [PragKausalitaet]
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("URSACHE").frame(maxWidth: .infinity, alignment: .leading)
                Text("WIRKUNG").frame(maxWidth: .infinity, alignment: .leading)
                Text("STEUERBAR").frame(width: 70)
                Text("BEWERTUNG").frame(width: 72)
            }
            .font(.system(size: 7, weight: .bold))
            .foregroundStyle(OpportunismaTheme.gray)
            .padding(.vertical, 6)
            ForEach(zeilen) { z in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text(z.ursache).font(.system(size: 9)).frame(maxWidth: .infinity, alignment: .leading)
                        Text(z.wirkung).font(.system(size: 9)).frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: z.beeinflussbar ? "hand.point.up.fill" : "lock.fill")
                            .foregroundStyle(z.beeinflussbar ? OpportunismaTheme.red : OpportunismaTheme.gray)
                            .frame(width: 70)
                        Text(z.bewertung.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(bewertungsFarbe(z.bewertung))
                            .frame(width: 72, alignment: .leading)
                    }
                    if !z.betroffene.isEmpty {
                        Text("Betroffen: \(z.betroffene.joined(separator: ", "))")
                            .font(.system(size: 8))
                            .foregroundStyle(OpportunismaTheme.gray)
                    }
                    if let e = z.empfehlung, !e.isEmpty {
                        Text("→ \(e)").font(.system(size: 8)).foregroundStyle(OpportunismaTheme.red)
                    }
                    if let sg = z.strategosBezug, !sg.isEmpty {
                        Text("Strategos: \(sg)").font(.system(size: 7)).foregroundStyle(OpportunismaTheme.gray)
                    }
                }
                .padding(.vertical, 8)
                .overlay(OpportunismaTheme.line.frame(height: 1), alignment: .bottom)
            }
        }
    }
    private func bewertungsFarbe(_ b: String) -> Color {
        switch b.lowercased() {
        case "positiv", "chance": return .green
        case "risiko", "gefahr": return OpportunismaTheme.red
        default: return OpportunismaTheme.gray
        }
    }
}
struct PragPrognosenTabelle: View {
    let zeilen: [PragPrognoseZeile]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(zeilen) { p in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(p.situation).font(.system(size: 10, weight: .black))
                        Spacer()
                        Text("P:\(p.wahrscheinlichkeit)% · K:\(p.kontrolle)%")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(OpportunismaTheme.red)
                    }
                    Text("Option: \(p.option)")
                        .font(.system(size: 9, weight: .bold))
                    Text("Führt zu: \(p.fuehrt_zu)")
                        .font(.system(size: 9))
                        .foregroundStyle(OpportunismaTheme.gray)
                    if !p.vorteile.isEmpty {
                        Text("Vorteile: \(p.vorteile.joined(separator: "; "))")
                            .font(.system(size: 8)).foregroundStyle(.green)
                    }
                    if !p.risiken.isEmpty {
                        Text("Risiken: \(p.risiken.joined(separator: "; "))")
                            .font(.system(size: 8)).foregroundStyle(OpportunismaTheme.red)
                    }
                    if !p.mittel.isEmpty {
                        Text("Mittel: \(p.mittel.joined(separator: ", "))")
                            .font(.system(size: 8)).foregroundStyle(OpportunismaTheme.gray)
                    }
                    Label(
                        p.beeinflussbar ? "Beeinflussbar" : "Extern / schwer steuerbar",
                        systemImage: p.beeinflussbar ? "hand.raised.fill" : "exclamationmark.triangle"
                    )
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(p.beeinflussbar ? OpportunismaTheme.red : OpportunismaTheme.gray)
                }
                .padding(10)
                .pragCardStyle()
            }
        }
    }
}
