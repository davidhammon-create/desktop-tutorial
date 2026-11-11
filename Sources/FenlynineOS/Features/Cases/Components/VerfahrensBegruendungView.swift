import SwiftUI
struct VerfahrensBegruendungView: View {
    let viewModel: CaseDetailViewModel
    @State private var aufgeklappt = false
    @State private var kiText: KIBegruendung? = nil
    @State private var laeuft = false
    @State private var zeigeVoll = false
    @State private var kiFehler: String?
    struct KIBegruendung {
        var verfahrensbegruendung: String
        var kritische_handlungen: [(handlung: String, risiko: String, empfehlung: String)]
        var dokumentationspflichten: [String]
        var empfehlung: String
    }
    private var fallTyp: FallTyp? {
        guard let fall = viewModel.fall else { return nil }
        return FallTyp.erkenne(fall: fall)
    }
    private var istSensibel: Bool {
        guard let fall = viewModel.fall else { return false }
        return FallTyp.istSensibel(fall: fall)
    }
    var body: some View {
        if let typ = fallTyp ?? (istSensibel ? .sensibel : nil) {
            VStack(spacing: 0) {
                Button {
                    withAnimation { aufgeklappt.toggle() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundStyle(typ.farbe)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(typ.icon) Begründungspflichtige Verfahrensführung — \(typ.label)")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Dieser Fall erfordert dokumentierte Begründung aller Verfahrensschritte")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: aufgeklappt ? "chevron.up" : "chevron.down")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(12)
                }
                .buttonStyle(.plain)
                .background(typ.farbe.opacity(0.06))
                if aufgeklappt {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(typ.begruendungspflicht)
                            .font(.system(size: 11))
                            .padding(10)
                            .background(typ.farbe.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                        WrapLayout(typ.normen) { norm in
                            Text(norm)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Besondere Risiken & Fallstricke").font(.caption.bold())
                            ForEach(typ.risiken, id: \.self) { r in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("▪").font(.caption2)
                                    Text(r).font(.caption2)
                                }
                            }
                        }
                        if kiText == nil {
                            Button {
                                Task { await generiereKIBegruendung(typ: typ) }
                            } label: {
                                if laeuft {
                                    ProgressView().scaleEffect(0.7)
                                    Text("KI erstellt Verfahrensbegründung…").font(.caption)
                                } else {
                                    Label("KI-Verfahrensbegründung generieren", systemImage: "wand.and.stars")
                                }
                            }
                            .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                            .tint(typ.farbe)
                            .disabled(laeuft || !viewModel.kiMode)
                            if let err = kiFehler {
                                Text(err).font(.caption).foregroundStyle(.red)
                            }
                        } else if let ki = kiText {
                            HStack {
                                Label("KI-Verfahrensbegründung", systemImage: "brain")
                                    .font(.system(size: 12, weight: .semibold))
                                Spacer()
                                Button("↺ Neu") { Task { await generiereKIBegruendung(typ: typ) } }
                                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.mini)
                                    .disabled(laeuft || !viewModel.kiMode)
                            }
                            if zeigeVoll || !ki.verfahrensbegruendung.isEmpty {
                                if !ki.verfahrensbegruendung.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Verfahrensbegründung").font(.caption.bold())
                                        Text(ki.verfahrensbegruendung).font(.system(size: 11))
                                    }
                                }
                                ForEach(Array(ki.kritische_handlungen.enumerated()), id: \.offset) { _, h in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(h.handlung).font(.system(size: 11, weight: .semibold))
                                        Text("Risiko: \(h.risiko)").font(.caption2).foregroundStyle(.red)
                                        Text("Empfehlung: \(h.empfehlung)").font(.caption2).foregroundStyle(.green)
                                    }
                                    .padding(8)
                                    .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                                }
                                if !ki.empfehlung.isEmpty {
                                    Text("Nächste Schritte: \(ki.empfehlung)").font(.caption)
                                }
                            }
                        }
                    }
                    .padding(12)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 10).stroke((fallTyp ?? .sensibel).farbe.opacity(0.2), lineWidth: 1))
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .onAppear { hydrateVerfahrensBegruendung() }
        }
    }
    private func hydrateVerfahrensBegruendung() {
        guard kiText == nil,
              let d = viewModel.fall?.ki_berater_result?.dictValue?["verfahrensbegruendung_ki"] as? [String: Any]
        else { return }
        let handlungen = (d["kritische_handlungen"] as? [[String: Any]] ?? []).map {
            (handlung: $0["handlung"] as? String ?? "", risiko: $0["risiko"] as? String ?? "", empfehlung: $0["empfehlung"] as? String ?? "")
        }
        kiText = KIBegruendung(
            verfahrensbegruendung: d["verfahrensbegruendung"] as? String ?? "",
            kritische_handlungen: handlungen,
            dokumentationspflichten: d["dokumentationspflichten"] as? [String] ?? [],
            empfehlung: d["empfehlung"] as? String ?? ""
        )
        zeigeVoll = true
    }
    private func generiereKIBegruendung(typ: FallTyp) async {
        guard let fall = viewModel.fall else { return }
        laeuft = true
        kiFehler = nil
        defer { laeuft = false }
        let prompt = """
        Du bist ein Senior-Strafverteidiger / Fachanwalt. Erstelle eine strukturierte anwaltliche Begründung, WARUM in diesem Fall so verfahren wird.
        Fall: \(fall.fallname)
        Rechtsgebiet: \(fall.rechtsgebiet ?? "—")
        Typ: \(typ.label)
        Zentrale Rechtsfrage: \(fall.zentrale_rechtsfrage ?? "—")
        Prozessziel: \(fall.prozessziel ?? "—")
        Erkannte Risiken: \(typ.risiken.joined(separator: ", "))
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: [
                    "type": "object",
                    "properties": [
                        "verfahrensbegruendung": ["type": "string"],
                        "kritische_handlungen": ["type": "array", "items": ["type": "object", "properties": [
                            "handlung": ["type": "string"], "risiko": ["type": "string"], "empfehlung": ["type": "string"]
                        ]]],
                        "dokumentationspflichten": ["type": "array", "items": ["type": "string"]],
                        "empfehlung": ["type": "string"]
                    ] as [String: Any]
                ] as [String: Any],
                model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId,
                logKiName: "Verfahrensbegründung"
            )
            let d = try KIJson.requireObject(result, kontext: "Verfahrensbegründung")
            let handlungen = (d["kritische_handlungen"] as? [[String: Any]] ?? []).map {
                (handlung: $0["handlung"] as? String ?? "", risiko: $0["risiko"] as? String ?? "", empfehlung: $0["empfehlung"] as? String ?? "")
            }
            await MainActor.run {
                kiText = KIBegruendung(
                    verfahrensbegruendung: d["verfahrensbegruendung"] as? String ?? "",
                    kritische_handlungen: handlungen,
                    dokumentationspflichten: d["dokumentationspflichten"] as? [String] ?? [],
                    empfehlung: d["empfehlung"] as? String ?? ""
                )
                zeigeVoll = true
            }
            if var fallUpd = viewModel.fall {
                let saved = try await KIResultStore.mergeBeraterSubKey(
                    caseId: viewModel.caseId,
                    fall: &fallUpd,
                    key: "verfahrensbegruendung_ki",
                    value: d
                )
                await MainActor.run { viewModel.fall = saved }
            }
        } catch {
            await MainActor.run { kiFehler = error.localizedDescription }
        }
    }
}
enum FallTyp {
    case sexualdelikt, massnahmen, strafrecht, sensibel
    var icon: String {
        switch self {
        case .sexualdelikt: return "⚠️"
        case .massnahmen: return "🦠"
        case .strafrecht: return "⚖️"
        case .sensibel: return "⚠️"
        }
    }
    var label: String {
        switch self {
        case .sexualdelikt: return "Sexualdelikt / Sittlichkeitsdelikt"
        case .massnahmen: return "Corona / Pandemiemaßnahmen"
        case .strafrecht: return "Allgemeines Strafrecht"
        case .sensibel: return "Sensibler Fall"
        }
    }
    var farbe: Color {
        switch self {
        case .sexualdelikt: return .red
        case .massnahmen: return .orange
        case .strafrecht: return .purple
        case .sensibel: return .orange
        }
    }
    var normen: [String] {
        switch self {
        case .sexualdelikt: return ["§ 177 StGB", "§ 184b StGB", "§ 68a StPO", "§ 156 StGB", "Art. 6 EMRK"]
        case .massnahmen: return ["Art. 2 GG", "Art. 8 GG", "§§ 28 ff. IfSG", "§ 113 BGB", "VwGO"]
        case .strafrecht: return ["Art. 6 EMRK", "Art. 103 GG", "§ 136 StPO", "§ 140 StPO", "§ 244 StPO"]
        case .sensibel: return ["Art. 6 EMRK", "Art. 103 GG"]
        }
    }
    var risiken: [String] {
        switch self {
        case .sexualdelikt: return [
            "Eidesstattliche Erklärungen (§ 156 StGB) — Falschaussage strafbar",
            "Gefahr der Zeugeneinflussnahme (§ 258 StGB)",
            "Aussage-gegen-Aussage-Konstellation — hohe Beweisanforderungen"
        ]
        case .massnahmen: return [
            "Grundrechtskonflikte (Art. 2, 8, 11 GG) — Verhältnismäßigkeit prüfen",
            "Beweisprobleme bei behördlichen Ermessensfehlern"
        ]
        case .strafrecht: return [
            "Unschuldsvermutung (Art. 6 II EMRK) — dokumentieren",
            "In dubio pro reo — Beweislast liegt bei Staatsanwaltschaft",
            "Beweisverwertungsverbote (§ 136a StPO) identifizieren"
        ]
        case .sensibel: return ["Besondere Sorgfaltspflicht des Anwalts", "Dokumentationspflicht erhöht"]
        }
    }
    var begruendungspflicht: String {
        switch self {
        case .sexualdelikt: return "Bei Sexualdelikten ist die Verfahrensführung besonders zu begründen, da Aussagen oft ohne weitere Beweise stehen."
        case .massnahmen: return "Staatliche Maßnahmen erfordern besondere Verhältnismäßigkeitsprüfung und dokumentierte Begründung."
        case .strafrecht: return "Strafrechtliche Verfahren erfordern lückenlose Dokumentation aller Verfahrensschritte."
        case .sensibel: return "Dieser Fall weist besondere Merkmale auf, die eine erhöhte Dokumentation erfordern."
        }
    }
    static func istSensibel(fall: LegalCase) -> Bool {
        let felder = [fall.rechtsgebiet, fall.fallname, fall.zentrale_rechtsfrage].compactMap { $0 }.joined(separator: " ").lowercased()
        let sensible = ["strafrecht", "sexualdelikt", "corona", "covid", "terrorismus", "mord", "betrug"]
        return sensible.contains { felder.contains($0) }
    }
    static func erkenne(fall: LegalCase) -> FallTyp? {
        let f = [fall.rechtsgebiet, fall.fallname, fall.zentrale_rechtsfrage, fall.notes, fall.prozessziel].compactMap { $0 }.joined(separator: " ").lowercased()
        if f.contains("sexuell") || f.contains("missbrauch") || f.contains("§ 177") || f.contains("hebephil") { return .sexualdelikt }
        if f.contains("corona") || f.contains("covid") || f.contains("pandem") || f.contains("impfpflicht") { return .massnahmen }
        if f.contains("strafrecht") || f.contains("anklag") || f.contains("stgb") || f.contains("beschuldig") { return .strafrecht }
        return nil
    }
}
