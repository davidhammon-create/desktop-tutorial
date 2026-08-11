import SwiftUI

// MARK: - Opportunisma-Ergebnisse in Strategos-Stil (kein Opportunisma-Theme)

struct StrategosOpportunismaVertragsPanel: View {
let vertrag: [String: Any]
var szenario: StrategosScenario? = nil
var onOpenOpportunismaTab: ((OpportunismaTab) -> Void)? = nil

var body: some View {
  VStack(alignment: .leading, spacing: 14) {
    StrategosOpportunismaVertragsGrafikHub(
      vertrag: vertrag,
      szenario: szenario,
      onOpenOpportunismaTab: onOpenOpportunismaTab
    )

    HStack {
      Label("Opportunisma · Vertrags-Kausalität", systemImage: "arrow.triangle.branch")
        .font(.caption.bold())
        .foregroundStyle(.purple)
      Spacer()
      if let m = vertrag["methodik"] as? String, !m.isEmpty {
        Text(String(m.prefix(80)))
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }

    if let klauseln = vertrag["klauseln"] as? [[String: Any]], !klauseln.isEmpty {
      section("Klausel-Wirkung auf Unternehmen") {
        ForEach(Array(klauseln.prefix(6).enumerated()), id: \.offset) { _, k in
          klauselZeile(k)
        }
      }
    }

    if let termine = vertrag["liefertermine"] as? [[String: Any]], !termine.isEmpty {
      section("Liefertermine & Verzug") {
        ForEach(Array(termine.enumerated()), id: \.offset) { _, t in
          terminZeile(t)
        }
      }
    }

    if let ziele = vertrag["zielhypothesen"] as? [[String: Any]], !ziele.isEmpty {
      section("Was ist das Ziel?") {
        ForEach(Array(ziele.enumerated()), id: \.offset) { _, z in
          HStack(alignment: .top) {
            Text(z["typ"] as? String ?? "Ziel")
              .font(.caption2.bold())
              .foregroundStyle(.orange)
              .frame(width: 90, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
              Text(z["ziel"] as? String ?? "--").font(.caption.bold())
              Text(z["beschreibung"] as? String ?? "")
                .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if let p = KIJson.intValue(z["wahrscheinlichkeit_pct"]) {
              Text("\(p)%").font(.caption2.bold()).foregroundStyle(.blue)
            }
          }
          .padding(.vertical, 4)
        }
      }
    }

    if let baeume = vertrag["entscheidungsbaeume"] as? [[String: Any]], !baeume.isEmpty {
      section("Entscheidungspfade") {
        ForEach(Array(baeume.enumerated()), id: \.offset) { _, baum in
          Text(baum["wurzel"] as? String ?? "Ausgangslage")
            .font(.caption.bold())
          ForEach(Array((baum["optionen"] as? [[String: Any]] ?? []).prefix(4).enumerated()), id: \.offset) { _, opt in
            HStack(alignment: .top, spacing: 6) {
              Text("->").font(.caption2).foregroundStyle(.purple)
              VStack(alignment: .leading, spacing: 2) {
                Text(opt["label"] as? String ?? "--").font(.caption2.bold())
                if let z = opt["ziel"] as? String, !z.isEmpty {
                  Text("Ziel: \(z)").font(.caption2).foregroundStyle(.green)
                }
                if let w = opt["wirkung_unternehmen"] as? String {
                  Text(w).font(.caption2).foregroundStyle(.secondary)
                }
              }
            }
            .padding(.leading, 8)
          }
        }
      }
    }

    if let eig = vertrag["eigene_pflichtverletzung"] as? [String: Any] {
      section("Eigene Pflichtverletzung -- Sinn & Risiko") {
        Text(eig["szenario"] as? String ?? "--").font(.caption2)
        if let k = eig["kostenersparnis"] as? String {
          Label(k, systemImage: "eurosign.circle").font(.caption2)
        }
       ForEach(eig["risiken"] as? [String] ?? [], id: \.self) { r in
         Text("n \(r)").font(.caption2).foregroundStyle(.orange)
       }
       if let e = eig["empfehlung"] as? String {
         Text("-> \(e)").font(.caption2.bold()).foregroundStyle(.blue)
       }
     }
   }

   if let steuer = vertrag["steuer_ressourcen"] as? [[String: Any]], !steuer.isEmpty {
     section("Steuer & Ressourcen (legal)") {
       ForEach(Array(steuer.enumerated()), id: \.offset) { _, s in
         HStack {
           Text(s["option"] as? String ?? "--").font(.caption2)
           Spacer()
           if let k = KIJson.numberValue(s["kosten_eur"]) {
             Text(String(format: "%.0f€", k)).font(.caption2.monospaced())
           }
         }
       }
     }
   }

   if let prog = vertrag["opportunisma_prognosen"] as? [[String: Any]], !prog.isEmpty {
     section("Prognosen (Situation -> Option -> Folge)") {
       ForEach(Array(prog.prefix(6).enumerated()), id: \.offset) { _, p in
         VStack(alignment: .leading, spacing: 2) {
           Text(p["situation"] as? String ?? "--").font(.caption2.bold())
           Text("-> \(p["option"] as? String ?? "--") -> \(p["fuehrt_zu"] as? String ?? "--")")
             .font(.caption2).foregroundStyle(.secondary)
         }
         .padding(.vertical, 3)
       }
     }
   }

   if let lobby = vertrag["politik_lobby"] as? [[String: Any]], !lobby.isEmpty {
     section("Politik & Lobby") {
       ForEach(Array(lobby.enumerated()), id: \.offset) { _, l in
         Text("\(l["akteur"] as? String ?? "--"): \(l["massnahme"] as? String ?? "") -> \(l["folge"] as? String ?? "")")
           .font(.caption2)
       }
     }
   }

   if let vp = vertrag["verhandlungspunkte"] as? [String], !vp.isEmpty {
     section("Verhandlungspunkte") {
       ForEach(vp, id: \.self) { Text("(cid:127) \($0)").font(.caption2) }
     }
   }

   opportunismaHinweis
 }
 .padding(14)
 .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
 .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.15)))
}

private var opportunismaHinweis: some View {
 VStack(alignment: .leading, spacing: 8) {
   Text("Vertiefung in Opportunisma (Strategos-Erweiterung): Fragebogen, Strategie-Baum, Politik & Wirtschaft -- optional, gleiches Szenario.")
     .font(.caption2)
     .foregroundStyle(.secondary)
   Button {
     UserDefaults.standard.set(OpportunismaTab.machtStrategie.rawValue, forKey: "opportunisma_initial_tab")
     NotificationCenter.default.post(name: .strategosOeffneOpportunisma, object: nil)
     onOpenOpportunismaTab?(.machtStrategie)
   } label: {
     Label("Opportunisma-Reiter öffnen", systemImage: "scope")
       .font(.caption.bold())
   }
   .buttonStyle(FenlynineOSGlassProminentButtonStyle())
   .tint(.red)
   .controlSize(.small)
 }
}

@ViewBuilder
private func section(_ titel: String, @ViewBuilder content: () -> some View) -> some View {
 VStack(alignment: .leading, spacing: 6) {
   Text(titel).font(.caption2.bold()).foregroundStyle(.secondary)
   content()
 }
 .padding(10)
 .frame(maxWidth: .infinity, alignment: .leading)
 .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
}

@ViewBuilder
private func klauselZeile(_ k: [String: Any]) -> some View {
 VStack(alignment: .leading, spacing: 3) {
   HStack {
     Text(k["klausel_typ"] as? String ?? "Klausel")
       .font(.caption.bold())
     Spacer()
     Text(k["risiko_level"] as? String ?? "--")
       .font(.caption2.bold())
       .foregroundStyle(risikoFarbe(k["risiko_level"] as? String))
   }
   Text(k["kurzbeschreibung"] as? String ?? "").font(.caption2)
   if let w = k["wirkung_unternehmen"] as? String {
     Text("Unternehmen: \(w)").font(.caption2).foregroundStyle(.secondary)
   }
   if let bereiche = k["betroffene_bereiche"] as? [String], !bereiche.isEmpty {
     Text("Bereiche: \(bereiche.joined(separator: ", "))").font(.caption2).foregroundStyle(.tertiary)
   }
 }
 .padding(.vertical, 4)
}

@ViewBuilder
private func terminZeile(_ t: [String: Any]) -> some View {
 VStack(alignment: .leading, spacing: 4) {
   HStack {
     Text(t["termin"] as? String ?? "Termin").font(.caption.bold())
     Spacer()
     if let p = KIJson.intValue(t["wahrscheinlichkeit_verzug_pct"]) {
       Text("Verzug \(p)%").font(.caption2.bold()).foregroundStyle(p > 50 ? .red : .orange)
     }
   }
   if let s = t["schadenersatz_anspruch"] as? String {
     Text("Schadenersatz: \(s)").font(.caption2)
   }
   HStack(spacing: 12) {
     if let sinn = t["durchsetzung_sinnvoll"] as? Bool {
       Label(sinn ? "Durchsetzung sinnvoll" : "Durchsetzung unsinnig",
          systemImage: sinn ? "checkmark.circle" : "xmark.circle")
         .font(.caption2)
         .foregroundStyle(sinn ? .green : .orange)
     }
   }
   if let v = t["vorteil_gegner_verzug"] as? String, !v.isEmpty {
     Text("Strategisch: \(v)").font(.caption2).foregroundStyle(.purple)
   }
   if let e = t["empfehlung"] as? String {
     Text("-> \(e)").font(.caption2.bold()).foregroundStyle(.blue)
   }
 }
 .padding(.vertical, 4)
}

private func risikoFarbe(_ level: String?) -> Color {
 switch level?.lowercased() {
 case "hoch", "kritisch": return .red
 case "mittel": return .orange
 default: return .green
 }
}
}

