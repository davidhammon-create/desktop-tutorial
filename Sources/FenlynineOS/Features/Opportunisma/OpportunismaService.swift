import Foundation

enum OpportunismaService {

@MainActor
static func analysiereLage(vm: OpportunismaViewModel) async {
  vm.kiLaeuft = true
  vm.kiFehler = nil
  defer { vm.kiLaeuft = false }

  let prompt = """
  Du bist Opportunisma -- Unternehmensstrategie-Erweiterung von Strategos.
  Analysiere die UNTERNEHMENSPOSITION in Politik, Wirtschaft und Wissenschaft -- nicht Einzelpersonen.

  UNTERNEHMENSSITUATION: \(vm.situationText)
  UNTERNEHMENSZIEL: \(vm.zielText)
  POSITIONSINDEX: \(vm.machtIndex)%
  STRATEGOS: \(vm.verknuepftesStrategosName ?? "nicht verknüpft")

  Liefere unternehmensbezogene Updates (legal & compliant).
  TRANSPARENZ in methodik.
  """

  let schema: [String: Any] = [
    "type": "object",
    "properties": [
      "analyse_text": ["type": "string"],
      "ki_tipp": ["type": "string"],
      "macht_index": ["type": "number"],
      "methodik": ["type": "string"],
      "hebel": ["type": "array", "items": ["type": "object", "properties": [
        "name": ["type": "string"], "wert": ["type": "number"]
      ]]],
      "ziele": ["type": "array", "items": ["type": "object", "properties": [
        "ziel": ["type": "string"], "status": ["type": "string"], "fortschritt": ["type": "number"]
      ]]]
    ] as [String: Any]
  ] as [String: Any]

  do {
    let result: AnyCodable = try await LLMService.shared.invoke(
      prompt: prompt,
      schema: schema,
      model: "claude_sonnet_4_6"
    )
    let d = try KIJson.requireObject(result, kontext: "Opportunisma Lageanalyse")

    let analyse = KIJson.string(in: d, keys: "analyse_text", "analyse") ?? ""
    let methodik = KIJson.string(in: d, keys: "methodik") ?? ""
    vm.kiAnalyse = [analyse, methodik.isEmpty ? nil : "Methodik: \(methodik)"]
      .compactMap { $0 }
      .joined(separator: "\n\n")
    vm.kiTipp = KIJson.string(in: d, keys: "ki_tipp", "tipp", "empfehlung")

    if let idx = KIJson.intValue(d["macht_index"]) {
      vm.machtIndex = min(100, max(0, idx))
    }

    let hebel = KIJson.array(in: d, keys: "hebel")
    if !hebel.isEmpty {
      vm.hebel = hebel.compactMap { row in
        guard let name = row["name"] as? String,
           let w = KIJson.intValue(row["wert"]) else { return nil }
        return PragBarItem(name: name, wert: w)
      }
    }

    let ziele = KIJson.array(in: d, keys: "ziele")
    if !ziele.isEmpty {
      vm.strategischeZiele = ziele.compactMap { row in
        guard let z = row["ziel"] as? String else { return nil }
        return PragZielZeile(
          ziel: z,
          status: row["status"] as? String ?? "Aktiv",
          fortschritt: KIJson.intValue(row["fortschritt"]) ?? 50
        )
      }
    }

    if vm.kiTipp == nil, !analyse.isEmpty {
      vm.kiTipp = String(analyse.prefix(280))
    }
  } catch {
    vm.kiFehler = error.localizedDescription
  }
}

@MainActor
static func erweitereStrategiebaum(vm: OpportunismaViewModel) async {
  vm.kiLaeuft = true
  vm.kiFehler = nil
  defer { vm.kiLaeuft = false }

  let parentId = vm.selectedNodeId.isEmpty ? vm.aktivesSzenario.root.id : vm.selectedNodeId
  let parentLabel = vm.flacheKnoten.first(where: { $0.id == parentId })?.label ?? "Wurzel"

  let prompt = """
  Erweitere den UNTERNEHMENS-Strategiebaum (Opportunisma, Erweiterung von Strategos):
  Unternehmenssituation: \(vm.situationText)
 Unternehmensziel: \(vm.zielText)
 Szenario: \(vm.aktivesSzenario.label)
 Strategos: \(vm.verknuepftesStrategosName ?? "--")
 Anker-Knoten: \(parentLabel)

 Liefere EINE institutionelle Handlung (Verband, Regulatorik, F&E, Markt) mit outcomes und goal.
 Nur legale, unternehmensethische Optionen -- kein individuelles Machtspiel.
 """

 let schema: [String: Any] = [
   "type": "object",
   "properties": [
     "ki_tipp": ["type": "string"],
     "move": ["type": "object", "properties": [
       "label": ["type": "string"],
       "detail": ["type": "string"],
       "efficacy": ["type": "number"],
       "risk": ["type": "number"],
       "reversibility": ["type": "number"],
       "harm": ["type": "number"]
     ]],
     "outcomes": ["type": "array", "items": ["type": "object", "properties": [
       "label": ["type": "string"],
       "detail": ["type": "string"],
       "efficacy": ["type": "number"],
       "risk": ["type": "number"],
       "reversibility": ["type": "number"],
       "harm": ["type": "number"],
       "goal_label": ["type": "string"],
       "goal_detail": ["type": "string"]
     ]]]
   ] as [String: Any]
 ] as [String: Any]

 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: schema,
     model: "claude_sonnet_4_6"
   )
   let d = try KIJson.requireObject(result, kontext: "Opportunisma Strategiebaum")

   guard let moveDict = d["move"] as? [String: Any],
      let move = parseTreeNode(from: moveDict, typ: .move) else {
     vm.kiFehler = "KI lieferte keinen gültigen Strategie-Pfad"
     return
   }

   let outcomes = KIJson.array(in: d, keys: "outcomes")
   var moveNode = move
   moveNode.children = outcomes.compactMap { outcomeDict -> PragTreeNode? in
     guard var outcome = parseTreeNode(from: outcomeDict, typ: .outcome) else { return nil }
     if let goalLabel = outcomeDict["goal_label"] as? String, !goalLabel.isEmpty {
       let goal = PragTreeNode(
         id: "ki-\(UUID().uuidString.prefix(6))",
         typ: .goal,
         label: goalLabel,
         detail: outcomeDict["goal_detail"] as? String ?? "",
         scores: parseScores(from: outcomeDict),
         children: []
       )
       outcome.children = [goal]
     }
     return outcome
   }

   vm.fuegeBaumKnoten(parentId: parentId, knoten: moveNode)
   vm.kiTipp = KIJson.string(in: d, keys: "ki_tipp", "empfehlung")
     ?? "Neuer KI-Pfad: \(moveNode.label)"
   vm.selectedNodeId = moveNode.id
 } catch {
   vm.kiFehler = error.localizedDescription
 }
}

// MARK: - Fragebogen-Auswertung

@MainActor
static func auswertenFragebogen(vm: OpportunismaViewModel) async {
 vm.fragebogenLaeuft = true
 vm.kiFehler = nil
 defer { vm.fragebogenLaeuft = false }

 let strategosCtx = await strategosKontextText()
 let antworten = vm.fragebogenAntwortenText

 let prompt = """
 Du bist Opportunisma -- die Umsetzungsebene von Strategos für UNTERNEHMEN (nicht Einzelpersonen).
 Ziel: Position des Unternehmens in Politik, Wirtschaft und Wissenschaft stärken und absichern.
 IMMER legal, compliant, ethisch vertretbar.

 STRATEGOS-SZENARIO: \(vm.verknuepftesStrategosName ?? "--")
 STRATEGOS-KONTEXT:
 \(strategosCtx)

 FRAGEBOGEN (Multiple Choice):
 \(antworten)

 AUFGABE -- alles auf UNTERNEHMENSEBENE:
 1. situation_kurz & ziel_kurz für das Unternehmen
 2. positions_index (0-100) statt individueller Macht
 3. dimensionen: Politik, Wirtschaft, Wissenschaft, Recht, Innovation, Reputation
 4. KAUSALITÄTEN: Ursache->Wirkung; betroffene nur: Firma, Markt, Politik, Wissenschaft, Regulatorik, Wettbewerb
 5. PROGNOSEN mit dimension (Politik/Wirtschaft/Wissenschaft)
 6. Verknüpfung zu Strategos-Analysen (Vertrag, Patent, Situation) in strategos_bezug-Feldern
 7. Netzwerk: Unternehmen, Verbände, Forschung, Regulatoren -- keine persönlichen Karriereziele
 8. executive_summary & ki_tipp: nächster Schritt für die Organisation (48h)
 """

 let schema: [String: Any] = [
   "type": "object",
   "properties": [
     "situation_kurz": ["type": "string"],
     "ziel_kurz": ["type": "string"],
     "executive_summary": ["type": "string"],
     "ki_tipp": ["type": "string"],
     "methodik": ["type": "string"],
     "macht_index": ["type": "number"],
     "hebel": ["type": "array", "items": ["type": "object", "properties": [
       "name": ["type": "string"], "wert": ["type": "number"]
     ]]],
     "dimensionen": ["type": "array", "items": ["type": "object", "properties": [
       "name": ["type": "string"], "wert": ["type": "number"]
     ]]],
     "ziele": ["type": "array", "items": ["type": "object", "properties": [
       "ziel": ["type": "string"], "status": ["type": "string"], "fortschritt": ["type": "number"]
     ]]],
     "gegner": ["type": "array", "items": ["type": "object", "properties": [
       "name": ["type": "string"], "einfluss": ["type": "string"],
       "bedrohung": ["type": "string"], "kontrolle": ["type": "string"]
     ]]],
     "szenarien": ["type": "array", "items": ["type": "object", "properties": [
       "name": ["type": "string"], "wahrscheinlichkeit": ["type": "number"],
       "kontrolle": ["type": "number"], "ergebnis": ["type": "string"]
     ]]],
     "ressourcen": ["type": "array", "items": ["type": "object", "properties": [
       "name": ["type": "string"], "wert": ["type": "number"]
     ]]],
     "narrativ": ["type": "array", "items": ["type": "object", "properties": [
       "label": ["type": "string"], "value": ["type": "number"]
     ]]],
     "influence": ["type": "array", "items": ["type": "object", "properties": [
       "name": ["type": "string"], "wert": ["type": "number"]
     ]]],
     "hegemonogramm": ["type": "array", "items": ["type": "object", "properties": [
       "label": ["type": "string"], "ist": ["type": "number"], "soll": ["type": "number"]
     ]]],
     "netzwerk_knoten": ["type": "array", "items": ["type": "object", "properties": [
       "label": ["type": "string"], "typ": ["type": "string"],
       "x": ["type": "number"], "y": ["type": "number"]
     ]]],
     "netzwerk_kanten": ["type": "array", "items": ["type": "object", "properties": [
       "von": ["type": "string"], "zu": ["type": "string"]
     ]]],
     "meilensteine": ["type": "array", "items": ["type": "object", "properties": [
       "titel": ["type": "string"], "start": ["type": "number"], "dauer": ["type": "number"]
     ]]],
     "risiko_matrix": ["type": "array", "items": ["type": "array", "items": ["type": "number"]]],
     "kausalitaeten": ["type": "array", "items": ["type": "object", "properties": [
       "ursache": ["type": "string"], "wirkung": ["type": "string"],
       "beeinflussbar": ["type": "boolean"], "bewertung": ["type": "string"],
       "betroffene": ["type": "array", "items": ["type": "string"]],
       "empfehlung": ["type": "string"], "strategos_bezug": ["type": "string"]
     ]]],
     "prognosen": ["type": "array", "items": ["type": "object", "properties": [
       "situation": ["type": "string"], "option": ["type": "string"],
       "fuehrt_zu": ["type": "string"],
       "vorteile": ["type": "array", "items": ["type": "string"]],
       "risiken": ["type": "array", "items": ["type": "string"]],
       "wahrscheinlichkeit": ["type": "number"], "kontrolle": ["type": "number"],
       "beeinflussbar": ["type": "boolean"],
       "mittel": ["type": "array", "items": ["type": "string"]],
       "dimension": ["type": "string"]
     ]]]
   ] as [String: Any]
 ] as [String: Any]

 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: schema,
     model: "claude_sonnet_4_6"
   )
   let d = try KIJson.requireObject(result, kontext: "Opportunisma Fragebogen")
   applyFragebogenErgebnis(vm: vm, from: d)
   vm.modulQuellen = OpportunismaFragebogenBank.moduleFuerAntworten(vm.fragebogenAntworten, szenario: vm.verknuepftesStrategos).map { mq in
     var m = mq
     if m.modul != .fragebogen && m.modul != .strategosLink {
       m.aktiv = true
       if m.quellen.isEmpty { m.quellen = ["KI-Auswertung · Fragebogen"] }
     }
     return m
   }
   await vm.synchronisiereMitStrategos()
   vm.fragebogenPhase = .abgeschlossen
   vm.fragebogenAbgeschlossen = true
 } catch {
   vm.kiFehler = error.localizedDescription
 }
}

@MainActor
private static func applyFragebogenErgebnis(vm: OpportunismaViewModel, from d: [String: Any]) {
 if let s = KIJson.string(in: d, keys: "situation_kurz") { vm.situationText = s }
 if let z = KIJson.string(in: d, keys: "ziel_kurz") { vm.zielText = z }

 let summary = KIJson.string(in: d, keys: "executive_summary") ?? ""
 let methodik = KIJson.string(in: d, keys: "methodik") ?? ""
 vm.fragebogenZusammenfassung = summary
 vm.kiAnalyse = [summary, methodik.isEmpty ? nil : "Methodik: \(methodik)"].compactMap { $0 }.joined(separator: "\n\n")
 vm.kiTipp = KIJson.string(in: d, keys: "ki_tipp", "tipp")

 if let idx = KIJson.intValue(d["macht_index"]) {
   vm.machtIndex = min(100, max(0, idx))
 }

 applyBarItems(in: d, key: "hebel", to: &vm.hebel)
 applyBarItems(in: d, key: "dimensionen", to: &vm.dimensionen)
 applyBarItems(in: d, key: "ressourcen", to: &vm.ressourcen)
 applyBarItems(in: d, key: "influence", to: &vm.influence)

 let ziele = KIJson.array(in: d, keys: "ziele")
 if !ziele.isEmpty {
   vm.strategischeZiele = ziele.compactMap { row in
     guard let z = row["ziel"] as? String else { return nil }
     return PragZielZeile(
       ziel: z,
       status: row["status"] as? String ?? "Aktiv",
       fortschritt: KIJson.intValue(row["fortschritt"]) ?? 50
     )
   }
 }

 let gegner = KIJson.array(in: d, keys: "gegner")
 if !gegner.isEmpty {
   vm.gegner = gegner.map { row in
     PragGegnerZeile(
       name: row["name"] as? String ?? "--",
       einfluss: row["einfluss"] as? String ?? "Mittel",
       bedrohung: row["bedrohung"] as? String ?? "Mittel",
       kontrolle: row["kontrolle"] as? String ?? "Beobachtung"
     )
   }
 }

 let szen = KIJson.array(in: d, keys: "szenarien")
 if !szen.isEmpty {
   vm.szenarien = szen.compactMap { row in
     guard let name = row["name"] as? String else { return nil }
     return PragSzenarioZeile(
       name: name,
       wahrscheinlichkeit: KIJson.intValue(row["wahrscheinlichkeit"]) ?? 50,
       kontrolle: KIJson.intValue(row["kontrolle"]) ?? 50,
       ergebnis: row["ergebnis"] as? String ?? "OPTION"
     )
   }
 }

 let narr = KIJson.array(in: d, keys: "narrativ")
 if !narr.isEmpty {
   vm.narrativ = narr.compactMap { row in
     guard let label = row["label"] as? String,
        let v = KIJson.numberValue(row["value"]) else { return nil }
     return (label: label, value: v)
   }
 }

 let heg = KIJson.array(in: d, keys: "hegemonogramm")
 if !heg.isEmpty {
   vm.hegemonogramm = heg.compactMap { row in
     guard let label = row["label"] as? String,
        let ist = KIJson.numberValue(row["ist"]),
        let soll = KIJson.numberValue(row["soll"]) else { return nil }
     return (label: label, ist: ist, soll: soll)
   }
 }

 let knoten = KIJson.array(in: d, keys: "netzwerk_knoten")
 if !knoten.isEmpty {
   vm.netzKnoten = knoten.compactMap { row in
     guard let label = row["label"] as? String else { return nil }
     return PragNetzKnoten(
       label: label,
       typ: row["typ"] as? String ?? "neutral",
       x: CGFloat(KIJson.numberValue(row["x"]) ?? 0.5),
       y: CGFloat(KIJson.numberValue(row["y"]) ?? 0.5)
     )
   }
 }

 let kanten = KIJson.array(in: d, keys: "netzwerk_kanten")
 if !kanten.isEmpty {
   vm.netzKanten = kanten.compactMap { row in
     guard let von = row["von"] as? String, let zu = row["zu"] as? String else { return nil }
     return PragNetzKante(von: von, zu: zu)
   }
 }

 let ms = KIJson.array(in: d, keys: "meilensteine")
 if !ms.isEmpty {
   vm.meilensteine = ms.compactMap { row in
     guard let titel = row["titel"] as? String else { return nil }
     return PragMeilenstein(
       titel: titel,
       start: KIJson.intValue(row["start"]) ?? 0,
       dauer: KIJson.intValue(row["dauer"]) ?? 2
     )
   }
 }

 if let matrix = d["risiko_matrix"] as? [[Any]] {
   vm.risikoMatrix = matrix.map { row in
     row.compactMap { KIJson.intValue($0) ?? 0 }
   }
 }

 vm.kausalitaeten = KIJson.array(in: d, keys: "kausalitaeten").map { row in
   PragKausalitaet(
     ursache: row["ursache"] as? String ?? "--",
     wirkung: row["wirkung"] as? String ?? "--",
     beeinflussbar: row["beeinflussbar"] as? Bool ?? false,
     bewertung: row["bewertung"] as? String ?? "neutral",
     betroffene: row["betroffene"] as? [String] ?? [],
     empfehlung: row["empfehlung"] as? String,
     strategosBezug: row["strategos_bezug"] as? String
   )
 }

 vm.prognosen = KIJson.array(in: d, keys: "prognosen").map { row in
   PragPrognoseZeile(
     situation: row["situation"] as? String ?? "--",
     option: row["option"] as? String ?? "--",
     fuehrt_zu: row["fuehrt_zu"] as? String ?? "--",
     vorteile: row["vorteile"] as? [String] ?? [],
     risiken: row["risiken"] as? [String] ?? [],
     wahrscheinlichkeit: KIJson.intValue(row["wahrscheinlichkeit"]) ?? 50,
     kontrolle: KIJson.intValue(row["kontrolle"]) ?? 50,
     beeinflussbar: row["beeinflussbar"] as? Bool ?? false,
     mittel: row["mittel"] as? [String] ?? [],
     dimension: row["dimension"] as? String ?? "Wirtschaft"
   )
 }

 if var sz = vm.szenarienBaum[vm.szenarioKey] {
   sz.situation = vm.situationText
   sz.ziel = vm.zielText
   var root = sz.root
   root.label = "Unternehmenslage (Fragebogen)"
   root.detail = String(vm.situationText.prefix(200))
   sz.root = root
   vm.szenarienBaum[vm.szenarioKey] = sz
 }
}

private static func applyBarItems(in d: [String: Any], key: String, to target: inout [PragBarItem]) {
 let rows = KIJson.array(in: d, keys: key)
 guard !rows.isEmpty else { return }
 target = rows.compactMap { row in
   guard let name = row["name"] as? String ?? row["label"] as? String,
      let w = KIJson.intValue(row["wert"] ?? row["value"]) else { return nil }
   return PragBarItem(name: name, wert: w)
 }
}

private static func strategosKontextText() async -> String {
 guard let list = try? await Services.strategosScenarios.list(), !list.isEmpty else {
   return "Keine Strategos-Szenarien in lOS vorhanden."
 }
 return list.prefix(5).map { sz in
   var teile = ["(cid:127) \(sz.titel)"]
   if let rg = sz.rechtsgebiet, !rg.isEmpty { teile.append("Rechtsgebiet: \(rg)") }
   if let va = StrategosOpportunismaVertragsService.vertragsAnalyseDict(fuer: sz) {
     teile.append("Vertrag: \(va["dokument_typ"] as? String ?? va["gesamtrisiko"] as? String ?? "analysiert")")
     if let k = va["klauseln"] as? [[String: Any]], let first = k.first {
       teile.append("Top-Klausel: \(first["klausel_typ"] as? String ?? "--")")
     }
     if let t = va["liefertermine"] as? [[String: Any]], let lt = t.first {
       teile.append("Termin: \(lt["termin"] as? String ?? "--")")
     }
   } else if let ki = sz.ki_analyse?.dictValue {
     if let v = ki["vertrags_analyse"] as? [String: Any] {
       teile.append("Vertrag: \(v["dokument_typ"] as? String ?? v["gesamtrisiko"] as? String ?? "analysiert")")
     }
     if let p = ki["patent_analyse"] as? [String: Any] {
       teile.append("Patent/IP: \(p["fto_status"] as? String ?? p["empfehlung"] as? String ?? "analysiert")")
     }
   }
   if let sit = sz.situationsanalyse?.dictValue?["gesamt_risiko"] {
     teile.append("Situationsrisiko: \(sit)")
   }
   return teile.joined(separator: " | ")
 }.joined(separator: "\n")
}

private static func parseScores(from d: [String: Any]) -> PragScores {
 PragScores(
   efficacy: KIJson.int(in: d, keys: "efficacy", "wirkung") ?? 50,
   risk: KIJson.int(in: d, keys: "risk", "risiko") ?? 50,
   reversibility: KIJson.int(in: d, keys: "reversibility", "umkehrbarkeit") ?? 50,
   harm: KIJson.int(in: d, keys: "harm", "schaden") ?? 50
 )
}

private static func parseTreeNode(from d: [String: Any], typ: PragNodeTyp) -> PragTreeNode? {
 guard let label = d["label"] as? String ?? d["titel"] as? String, !label.isEmpty else { return nil }
 return PragTreeNode(
   id: "ki-\(UUID().uuidString.prefix(8))",
   typ: typ,
   label: label,
   detail: d["detail"] as? String ?? d["beschreibung"] as? String ?? "",
   scores: parseScores(from: d),
   children: []
 )
}
}

