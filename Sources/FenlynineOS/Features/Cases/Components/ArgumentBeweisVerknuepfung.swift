import SwiftUI
enum ArgumentBeweisVerknuepfung {
    static func verknuepfteBeweise(fuer argument: Argument, in alle: [Evidence]) -> [Evidence] {
        let argId = argument.id ?? ""
        var ids = Set(argument.linked_evidence_ids ?? [])
        for ev in alle where (ev.linked_argument_ids ?? []).contains(argId) {
            if let eid = ev.id { ids.insert(eid) }
        }
        return ids.compactMap { id in alle.first { $0.id == id } }
            .sorted { $0.effectiveWeight > $1.effectiveWeight }
    }
    static func istBewiesen(argument: Argument, beweise: [Evidence]) -> Bool {
        !verknuepfteBeweise(fuer: argument, in: beweise).isEmpty
    }
    static func unverknuepfteBeweise(argumente: [Argument], beweise: [Evidence]) -> [Evidence] {
        beweise.filter { ev in
            let linkedToArg = !(ev.linked_argument_ids ?? []).isEmpty
            let inArgList = argumente.contains { ($0.linked_evidence_ids ?? []).contains(ev.id ?? "") }
            return !linkedToArg && !inArgList
        }
    }
    @MainActor
    static func verknuepfe(
        argumentId: String,
        evidenceId: String,
        argumente: inout [Argument],
        beweise: inout [Evidence],
        persist: Bool = true
    ) async throws {
        guard let aIdx = argumente.firstIndex(where: { $0.id == argumentId }),
              let eIdx = beweise.firstIndex(where: { $0.id == evidenceId }) else { return }
        var arg = argumente[aIdx]
        var ev = beweise[eIdx]
        var evIds = Set(arg.linked_evidence_ids ?? [])
        evIds.insert(evidenceId)
        arg.linked_evidence_ids = Array(evIds)
        var argIds = Set(ev.linked_argument_ids ?? [])
        argIds.insert(argumentId)
        ev.linked_argument_ids = Array(argIds)
        if persist {
            if let id = arg.id {
                arg = try await Services.arguments.update(id: id, entity: arg)
            }
            if let id = ev.id {
                ev = try await Services.evidence.update(id: id, entity: ev)
            }
        }
        argumente[aIdx] = arg
        beweise[eIdx] = ev
    }
    @MainActor
    static func loeseVerknuepfung(
        argumentId: String,
        evidenceId: String,
        argumente: inout [Argument],
        beweise: inout [Evidence],
        persist: Bool = true
    ) async throws {
        guard let aIdx = argumente.firstIndex(where: { $0.id == argumentId }),
              let eIdx = beweise.firstIndex(where: { $0.id == evidenceId }) else { return }
        var arg = argumente[aIdx]
        var ev = beweise[eIdx]
        arg.linked_evidence_ids = (arg.linked_evidence_ids ?? []).filter { $0 != evidenceId }
        ev.linked_argument_ids = (ev.linked_argument_ids ?? []).filter { $0 != argumentId }
        if persist {
            if let id = arg.id {
                arg = try await Services.arguments.update(id: id, entity: arg)
            }
            if let id = ev.id {
                ev = try await Services.evidence.update(id: id, entity: ev)
            }
        }
        argumente[aIdx] = arg
        beweise[eIdx] = ev
    }
    @MainActor
    static func wendeZuordnungenAn(
        paare: [(argumentId: String, evidenceId: String)],
        argumente: inout [Argument],
        beweise: inout [Evidence]
    ) async throws {
        for p in paare {
            try await verknuepfe(
                argumentId: p.argumentId,
                evidenceId: p.evidenceId,
                argumente: &argumente,
                beweise: &beweise,
                persist: true
            )
        }
    }
}
struct ArgumentBeweisBaumView: View {
    let argument: Argument
    let beweise: [Evidence]
    let viewModel: CaseDetailViewModel
    let kiMode: Bool
    let onArgumentUpdate: (Argument) -> Void
    let onEvidenceUpdate: (Evidence) -> Void
    var onLinkEvidence: ((String) -> Void)?
    @State private var loesenFehler: String?
    private var verknuepfteBeweise: [Evidence] {
        ArgumentBeweisVerknuepfung.verknuepfteBeweise(fuer: argument, in: beweise)
    }
    private var istBewiesen: Bool { !verknuepfteBeweise.isEmpty }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let loesenFehler {
                Text(loesenFehler).font(.caption2).foregroundStyle(.red).padding(.horizontal, 8)
            }
            ArgumentKarteKI(
                argument: argument,
                viewModel: viewModel,
                kiMode: kiMode,
                beweisStatus: istBewiesen ? .bewiesen(count: verknuepfteBeweise.count) : .ohneBeleg,
                onUpdate: onArgumentUpdate
            )
            if istBewiesen {
                VerknuepfungsLinie(typ: .argumentZuBeweis)
                    .padding(.leading, 28)
                ForEach(Array(verknuepfteBeweise.enumerated()), id: \.element.id) { index, ev in
                    if index > 0 {
                        VerknuepfungsLinie(typ: .beweisZuBeweis)
                            .padding(.leading, 44)
                    }
                    BeweisKarteKI(
                        beweis: ev,
                        viewModel: viewModel,
                        kiMode: kiMode,
                        eingerueckt: true,
                        verknuepftMit: argument.title,
                        onUpdate: onEvidenceUpdate,
                        onLoesen: {
                            Task {
                                var args = viewModel.argumente
                                var evs = viewModel.beweise
                                do {
                                    try await ArgumentBeweisVerknuepfung.loeseVerknuepfung(
                                        argumentId: argument.id ?? "",
                                        evidenceId: ev.id ?? "",
                                        argumente: &args,
                                        beweise: &evs
                                    )
                                    await MainActor.run {
                                        loesenFehler = nil
                                        viewModel.argumente = args
                                        viewModel.beweise = evs
                                    }
                                } catch {
                                    await MainActor.run { loesenFehler = error.localizedDescription }
                                }
                            }
                        }
                    )
                    .padding(.leading, 36)
                }
            } else if kiMode {
                HStack(spacing: 8) {
                    VerknuepfungsLinie(typ: .argumentZuBeweis, gestrichelt: true)
                        .frame(width: 24)
                    Text("Kein Beleg verknüpft — KI-Zuordnung oder Beweis hinzufügen")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Spacer()
                    if let onLink = onLinkEvidence {
                        Button("Beweis verknüpfen") { onLink(argument.id ?? "") }
                            .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                            .controlSize(.mini)
                    }
                }
                .padding(.leading, 28)
                .padding(.vertical, 6)
            }
        }
        .padding(.vertical, 4)
    }
}
enum ArgumentBeweisStatus {
    case bewiesen(count: Int)
    case ohneBeleg
}
struct VerknuepfungsLinie: View {
    enum LinieTyp { case argumentZuBeweis, beweisZuBeweis }
    var typ: LinieTyp = .argumentZuBeweis
    var gestrichelt: Bool = false
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.secondary.opacity(gestrichelt ? 0.25 : 0.45))
                .frame(width: 1.5, height: typ == .argumentZuBeweis ? 14 : 10)
        }
        .frame(height: typ == .argumentZuBeweis ? 14 : 10)
    }
}
