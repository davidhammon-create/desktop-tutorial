import SwiftUI
import AppKit

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// ADMIN-ZENTRALE -- Konten · Abos · KI-Abrechnung · DSGVO · Audit
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct AdminZentraleView: View {
@ObservedObject private var store = KontoStore.shared
@ObservedObject private var demo = DemoKILauf.shared

@State private var auswahlId: UUID?
@State private var suchtext = ""
@State private var neuesPasswortAnzeige: String?
@State private var zeigeLoeschDialog = false
@State private var reiter: Reiter = .konten

private enum Reiter: String, CaseIterable, Identifiable {
  case konten, abrechnung, preise, demolauf, audit
  var id: String { rawValue }
  var titel: String {
    switch self {
    case .konten: return "Konten & Abos"
    case .abrechnung: return "KI-Abrechnung"
    case .preise: return "Preise"
    case .demolauf: return "Demo-KI-Lauf"
    case .audit: return "Audit & DSGVO"
    }
  }
  var symbol: String {
    switch self {
    case .konten: return "person.2.fill"
    case .abrechnung: return "eurosign.circle.fill"
    case .preise: return "slider.horizontal.3"
    case .demolauf: return "sparkles"
    case .audit: return "lock.shield.fill"
    }
  }
}

var body: some View {
  Group {
    if store.istAdmin {
      inhalt
    } else {
      VStack(spacing: 10) {
        Image(systemName: "lock.shield")
          .font(.system(size: 30))
          .foregroundStyle(Premium.textFaint)
        Text("Die Admin-Zentrale ist Administratoren vorbehalten.")
          .font(.system(size: 12))
          .foregroundStyle(Premium.textSoft)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Premium.void)
    }
  }
}

private var inhalt: some View {
  VStack(spacing: 0) {
    // Kopf mit Kennzahlen
    HStack(spacing: 12) {
      kennzahl("Konten", "\(store.konten.count)", symbol: "person.2")
      kennzahl("Bezahlte Abos", "\(store.konten.filter { $0.plan != .frei && !$0.istAdmin }.count)", symbol: "creditcard")
      kennzahl("Abo-Umsatz / Monat", String(format: "%.0f €", aboUmsatz), symbol: "chart.line.uptrend.xyaxis")
      kennzahl("KI-Kosten Monat", String(format: "%.2f €", store.monatsKostenGesamt), symbol: "brain")
      kennzahl("Offene Anfragen", "\(store.offeneAnfragen.count)", symbol: "bell",
          hervorheben: !store.offeneAnfragen.isEmpty)
      Spacer()
    }
    .padding(14)

    // Reiter
    HStack(spacing: 6) {
      ForEach(Reiter.allCases) { r in
        Button {
          reiter = r
        } label: {
          Label(r.titel, systemImage: r.symbol)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(reiter == r ? Premium.onAction : Premium.textSoft)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 8).fill(reiter == r ? Premium.action : Premium.panel))
        }
        .buttonStyle(.plain)
      }
      Spacer()
    }
    .padding(.horizontal, 14)
    .padding(.bottom, 10)

    Divider().overlay(Premium.hairline)

    switch reiter {
    case .konten: kontenReiter
    case .abrechnung: abrechnungReiter
    case .preise: preiseReiter
    case .demolauf: demoLaufReiter
   case .audit: auditReiter
   }
 }
 .background(Premium.void)
}

private var aboUmsatz: Double {
 store.konten.filter { !$0.istAdmin }.reduce(0) { $0 + $1.plan.monatsPreis }
}

// MARK: Konten & Abos

private var kontenReiter: some View {
 HStack(spacing: 0) {
   // Liste
   VStack(spacing: 0) {
     HStack(spacing: 6) {
       Image(systemName: "magnifyingglass")
         .font(.system(size: 10))
         .foregroundStyle(Premium.textFaint)
       TextField("Konten suchen…", text: $suchtext)
         .textFieldStyle(.plain)
         .font(.system(size: 11))
     }
     .padding(.horizontal, 10).padding(.vertical, 7)
     .background(RoundedRectangle(cornerRadius: 7).fill(Premium.well))
     .padding(10)

     if !store.offeneAnfragen.isEmpty {
       anfragenBanner
         .padding(.horizontal, 10)
         .padding(.bottom, 6)
     }

     ScrollView {
       LazyVStack(spacing: 2) {
         ForEach(gefilterteKonten) { konto in
           kontoZeile(konto)
         }
       }
       .padding(.horizontal, 8)
       .padding(.bottom, 20)
     }
   }
   .frame(width: 300)
   .background(Premium.ink)
   .overlay(alignment: .trailing) {
     Rectangle().fill(Premium.hairline).frame(width: 1)
   }

   // Detail
   if let konto = store.konten.first(where: { $0.id == auswahlId }) {
     kontoDetail(konto)
   } else {
     VStack(spacing: 8) {
       Image(systemName: "person.crop.rectangle")
         .font(.system(size: 26))
         .foregroundStyle(Premium.textFaint)
       Text("Konto auswählen")
         .font(.system(size: 12))
         .foregroundStyle(Premium.textSoft)
     }
     .frame(maxWidth: .infinity, maxHeight: .infinity)
   }
 }
}

private var gefilterteKonten: [Konto] {
 let q = suchtext.trimmingCharacters(in: .whitespaces).lowercased()
 let alle = store.konten.sorted { $0.erstellt < $1.erstellt }
 guard !q.isEmpty else { return alle }
 return alle.filter { $0.name.lowercased().contains(q) || $0.email.lowercased().contains(q) }
}

private var anfragenBanner: some View {
 VStack(alignment: .leading, spacing: 6) {
   Text("OFFENE UPGRADE-ANFRAGEN")
     .font(.system(size: 8.5, weight: .black))
     .kerning(0.5)
     .foregroundStyle(Premium.proposed)
   ForEach(store.offeneAnfragen) { anfrage in
     if let konto = store.konten.first(where: { $0.id == anfrage.kontoId }) {
       HStack(spacing: 6) {
         Text("\(konto.name) -> \(anfrage.gewuenschterPlan.titel)")
           .font(.system(size: 10.5, weight: .medium))
           .foregroundStyle(Premium.text)
           .lineLimit(1)
         Spacer()
         Button("OK") {
           store.adminSetzePlan(kontoId: konto.id, plan: anfrage.gewuenschterPlan)
         }
         .font(.system(size: 10, weight: .bold))
         .buttonStyle(.borderedProminent)
         .controlSize(.mini)
         Button("Nein") {
           store.adminAnfrageAblehnen(anfrage.id)
         }
         .font(.system(size: 10))
         .buttonStyle(.bordered)
         .controlSize(.mini)
       }
     }
   }
 }
 .padding(10)
 .background(RoundedRectangle(cornerRadius: 9).fill(Premium.proposed.opacity(0.08)))
 .overlay(RoundedRectangle(cornerRadius: 9).stroke(Premium.proposed.opacity(0.3), lineWidth: 1))
}

private func kontoZeile(_ konto: Konto) -> some View {
 Button {
   auswahlId = konto.id
   neuesPasswortAnzeige = nil
 } label: {
   HStack(spacing: 10) {
     Circle()
       .fill(konto.gesperrt ? Premium.critical : (konto.aktiv ? Premium.computed : Premium.textFaint))
       .frame(width: 7, height: 7)
     VStack(alignment: .leading, spacing: 2) {
       HStack(spacing: 5) {
         Text(konto.name)
           .font(.system(size: 12, weight: .semibold))
           .foregroundStyle(Premium.text)
           .lineLimit(1)
         if konto.istAdmin {
           Image(systemName: "crown.fill")
             .font(.system(size: 8))
             .foregroundStyle(Premium.action)
         }
       }
       Text(konto.email)
         .font(.system(size: 10))
         .foregroundStyle(Premium.textFaint)
         .lineLimit(1)
     }
     Spacer()
     Text(konto.plan.titel)
       .font(.system(size: 9, weight: .bold))
       .foregroundStyle(konto.plan == .frei ? Premium.textFaint : Premium.action)
       .padding(.horizontal, 6).padding(.vertical, 3)
       .background(Capsule().fill((konto.plan == .frei ? Premium.textFaint : Premium.action).opacity(0.12)))
   }
   .padding(.horizontal, 10).padding(.vertical, 8)
   .background(
     RoundedRectangle(cornerRadius: 8)
       .fill(auswahlId == konto.id ? Premium.action.opacity(0.12) : Color.clear)
   )
   .contentShape(Rectangle())
 }
 .buttonStyle(.plain)
}

private func kontoDetail(_ konto: Konto) -> some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 20) {
     // Kopf
     HStack(spacing: 12) {
       Text(String(konto.name.prefix(1)).uppercased())
         .font(.system(size: 18, weight: .bold, design: .rounded))
         .foregroundStyle(Premium.onAction)
         .frame(width: 46, height: 46)
         .background(Circle().fill(Premium.action))
       VStack(alignment: .leading, spacing: 2) {
         Text(konto.name)
           .font(.system(size: 16, weight: .semibold))
           .foregroundStyle(Premium.text)
         Text(konto.email)
           .font(.system(size: 11))
           .foregroundStyle(Premium.textSoft)
         Text("Erstellt \(konto.erstellt.formatted(date: .abbreviated, time: .omitted)) · Letzte Anmeldung \(konto.letzteAnmeldung?.formatted(date: .abbreviated, time: .shortened) ?? "--")")
           .font(.system(size: 9.5))
           .foregroundStyle(Premium.textFaint)
       }
       Spacer()
     }

     // Abo & Rolle
     gruppe("Abonnement & Berechtigung") {
       HStack(spacing: 14) {
         Picker("Abo", selection: Binding(
           get: { konto.plan },
           set: { store.adminSetzePlan(kontoId: konto.id, plan: $0) }
         )) {
           ForEach(AboPlan.allCases) { p in
             Text("\(p.titel) -- \(p.preisText)").tag(p)
           }
         }
         .frame(width: 260)

         Picker("Rolle", selection: Binding(
           get: { konto.rolle },
           set: { store.adminSetzeRolle(kontoId: konto.id, rolle: $0) }
         )) {
           ForEach(KontoRolle.allCases) { r in
             Text(r.titel).tag(r)
           }
         }
         .frame(width: 200)
       }

       HStack(spacing: 18) {
         Toggle("Konto aktiv", isOn: Binding(
           get: { konto.aktiv },
           set: { store.adminSetzeAktiv(kontoId: konto.id, aktiv: $0) }
         ))
         Toggle("Gesperrt", isOn: Binding(
           get: { konto.gesperrt },
           set: { store.adminSetzeGesperrt(kontoId: konto.id, gesperrt: $0) }
         ))
       }
       .toggleStyle(.switch)
       .font(.system(size: 12))

       if let fehler = store.fehler {
         Text(fehler)
           .font(.system(size: 11))
           .foregroundStyle(Premium.critical)
       }
     }

     // KI-Abrechnung dieses Kontos
     gruppe("KI-Nutzung & Budget") {
       HStack(spacing: 12) {
         kennzahl("Aufrufe / Monat", "\(store.monatsAufrufe(kontoId: konto.id))", symbol: "number")
         kennzahl("Kosten / Monat", String(format: "%.2f €", store.monatsKosten(kontoId: konto.id)), symbol: "eurosign")
       }

       HStack(spacing: 8) {
         Text("Monatsbudget:")
           .font(.system(size: 12))
           .foregroundStyle(Premium.textSoft)
         TextField("unbegrenzt", text: Binding(
           get: { konto.kiBudgetMonat.map { String(format: "%.0f", $0) } ?? "" },
           set: { neu in
             let wert = Double(neu.replacingOccurrences(of: ",", with: "."))
             store.adminSetzeBudget(kontoId: konto.id, budget: neu.isEmpty ? nil : wert)
           }
         ))
         .textFieldStyle(.roundedBorder)
         .frame(width: 100)
         Text("€ / Monat (leer = unbegrenzt)")
           .font(.system(size: 10.5))
           .foregroundStyle(Premium.textFaint)
       }

       let eintraege = Array(store.verbrauch(kontoId: konto.id).prefix(10))
       if eintraege.isEmpty {
         Text("Keine KI-Nutzung dokumentiert.")
           .font(.system(size: 11))
           .foregroundStyle(Premium.textFaint)
       } else {
         VStack(spacing: 1) {
           ForEach(eintraege) { e in
             HStack {
               Text(e.datum.formatted(date: .numeric, time: .shortened))
                 .font(.system(size: 9.5, design: .monospaced))
                 .foregroundStyle(Premium.textFaint)
                 .frame(width: 110, alignment: .leading)
               Text("\(e.modul) · \(e.aktion) · \(e.modell)")
                 .font(.system(size: 10))
                 .foregroundStyle(Premium.textSoft)
                 .lineLimit(1)
               Spacer()
               Text("\(e.tokensEin)/\(e.tokensAus) tok")
                 .font(.system(size: 9, design: .monospaced))
                 .foregroundStyle(Premium.textFaint)
               Text(String(format: "%.2f €", e.kosten))
                 .font(.system(size: 10, weight: .semibold, design: .monospaced))
                 .foregroundStyle(Premium.text)
                 .frame(width: 54, alignment: .trailing)
             }
             .padding(.horizontal, 8).padding(.vertical, 5)
             .background(RoundedRectangle(cornerRadius: 5).fill(Premium.panel.opacity(0.5)))
           }
         }
       }
     }

     // Sicherheit & DSGVO
     gruppe("Sicherheit & DSGVO") {
       HStack(spacing: 10) {
         Button("Passwort zurücksetzen") {
           neuesPasswortAnzeige = store.adminPasswortZuruecksetzen(kontoId: konto.id)
         }
         .buttonStyle(.bordered)

         Button("Daten exportieren (Art. 15/20)") {
           exportiereDaten(konto: konto)
         }
         .buttonStyle(.bordered)

         Button("Konto löschen (Art. 17)", role: .destructive) {
           zeigeLoeschDialog = true
         }
         .buttonStyle(.bordered)
       }

       if let pw = neuesPasswortAnzeige {
         HStack(spacing: 8) {
           Text("Neues Einmal-Passwort:")
             .font(.system(size: 11))
             .foregroundStyle(Premium.textSoft)
           Text(pw)
             .font(.system(size: 12, weight: .bold, design: .monospaced))
             .foregroundStyle(Premium.action)
             .textSelection(.enabled)
           Button {
             NSPasteboard.general.clearContents()
             NSPasteboard.general.setString(pw, forType: .string)
           } label: {
             Image(systemName: "doc.on.doc")
               .font(.system(size: 10))
           }
           .buttonStyle(.plain)
         }
         .padding(8)
         .background(RoundedRectangle(cornerRadius: 7).fill(Premium.action.opacity(0.08)))
         Text("Nur einmal sichtbar -- sicher an die Person übermitteln.")
           .font(.system(size: 9.5))
           .foregroundStyle(Premium.textFaint)
       }
     }

     // Notizen
     gruppe("Interne Notizen") {
       TextField("Notizen zu diesem Konto…", text: Binding(
         get: { konto.notizen },
         set: { store.adminSetzeNotizen(kontoId: konto.id, notizen: $0) }
       ), axis: .vertical)
       .textFieldStyle(.roundedBorder)
       .lineLimit(2...5)
     }
   }
   .padding(20)
 }
 .confirmationDialog(
   "Konto „\(konto.email)" und alle zugehörigen Daten unwiderruflich löschen?",
   isPresented: $zeigeLoeschDialog
 ) {
   Button("Unwiderruflich löschen", role: .destructive) {
     store.kontoLoeschen(kontoId: konto.id)
     auswahlId = nil
   }
   Button("Abbrechen", role: .cancel) {}
 }
}

// MARK: KI-Abrechnung (gesamt)

private var abrechnungReiter: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 18) {
     HStack {
       Text("KI-Nutzung aller Konten -- laufender Monat")
         .font(.headline)
         .foregroundStyle(Premium.text)
       Spacer()
       Button {
         exportiereCSV()
       } label: {
         Label("CSV-Export", systemImage: "square.and.arrow.up")
           .font(.system(size: 11, weight: .semibold))
       }
       .buttonStyle(.bordered)
     }

     // Je Konto
     VStack(spacing: 2) {
       HStack {
         Text("KONTO").frame(maxWidth: .infinity, alignment: .leading)
         Text("ABO").frame(width: 90, alignment: .leading)
         Text("AUFRUFE").frame(width: 70, alignment: .trailing)
         Text("KOSTEN").frame(width: 80, alignment: .trailing)
       }
       .font(.system(size: 8.5, weight: .black))
       .kerning(0.5)
       .foregroundStyle(Premium.textFaint)
       .padding(.horizontal, 10).padding(.vertical, 5)

       ForEach(store.konten.sorted { store.monatsKosten(kontoId: $0.id) > store.monatsKosten(kontoId: $1.id) }) { konto in
         HStack {
           HStack(spacing: 5) {
             Text(konto.name)
               .font(.system(size: 11.5, weight: .medium))
               .foregroundStyle(Premium.text)
             if konto.istAdmin {
               Text("Admin · kostenfrei")
                 .font(.system(size: 8.5, weight: .bold))
                 .foregroundStyle(Premium.computed)
             }
           }
           .frame(maxWidth: .infinity, alignment: .leading)
           Text(konto.plan.titel)
             .font(.system(size: 10.5))
             .foregroundStyle(Premium.textSoft)
             .frame(width: 90, alignment: .leading)
           Text("\(store.monatsAufrufe(kontoId: konto.id))")
             .font(.system(size: 11, design: .monospaced))
             .foregroundStyle(Premium.textSoft)
             .frame(width: 70, alignment: .trailing)
           Text(String(format: "%.2f €", store.monatsKosten(kontoId: konto.id)))
             .font(.system(size: 11, weight: .semibold, design: .monospaced))
             .foregroundStyle(Premium.text)
             .frame(width: 80, alignment: .trailing)
         }
         .padding(.horizontal, 10).padding(.vertical, 8)
         .background(RoundedRectangle(cornerRadius: 7).fill(Premium.panel.opacity(0.5)))
       }
     }

     Text("Jeder KI-Aufruf wird mit Zeitpunkt, Modul, Modell, Token-Zahl und Kosten je Konto dokumentiert. Administrator-Aufrufe sind kostenfrei, erscheinen aber im Protokoll.")
       .font(.system(size: 10))
       .foregroundStyle(Premium.textFaint)
   }
   .padding(20)
   .frame(maxWidth: 760, alignment: .leading)
 }
 .frame(maxWidth: .infinity)
}

// MARK: Preise

private var preiseReiter: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 18) {
     Text("KI-Preise (verbrauchsbasiert)")
       .font(.headline)
       .foregroundStyle(Premium.text)
     Text("Diese Sätze gelten für alle Konten außer Administratoren. Änderungen wirken auf künftige Aufrufe.")
       .font(.system(size: 11))
       .foregroundStyle(Premium.textSoft)

     preisFeld("Eingabe je 1.000 Token", wert: store.preise.eingabeJe1000) { store.preise.eingabeJe1000 = $0 }
     preisFeld("Ausgabe je 1.000 Token", wert: store.preise.ausgabeJe1000) { store.preise.ausgabeJe1000 = $0 }
     preisFeld("Mindestpreis je Aufruf", wert: store.preise.mindestJeAufruf) { store.preise.mindestJeAufruf = $0 }
     preisFeld("Pauschale Dokument-Analyse", wert: store.preise.dokumentAnalyse) { store.preise.dokumentAnalyse = $0 }

     Divider().opacity(0.3)

     Text("Abo-Stufen")
       .font(.headline)
       .foregroundStyle(Premium.text)
     ForEach(AboPlan.allCases) { plan in
       HStack {
         Text(plan.titel)
           .font(.system(size: 12, weight: .semibold))
           .foregroundStyle(Premium.text)
           .frame(width: 110, alignment: .leading)
         Text(plan.preisText)
           .font(.system(size: 12, design: .monospaced))
           .foregroundStyle(Premium.action)
           .frame(width: 110, alignment: .leading)
         Text(plan.untertitel)
           .font(.system(size: 10.5))
           .foregroundStyle(Premium.textSoft)
           .lineLimit(1)
       }
       .padding(.horizontal, 10).padding(.vertical, 7)
       .background(RoundedRectangle(cornerRadius: 7).fill(Premium.panel.opacity(0.5)))
     }
   }
   .padding(20)
   .frame(maxWidth: 640, alignment: .leading)
 }
 .frame(maxWidth: .infinity)
}

private func preisFeld(_ titel: String, wert: Double, setzen: @escaping (Double) -> Void) -> some View {
 HStack(spacing: 8) {
   Text(titel)
     .font(.system(size: 12))
     .foregroundStyle(Premium.textSoft)
     .frame(width: 220, alignment: .leading)
   TextField("", text: Binding(
     get: { String(format: "%.3f", wert) },
     set: { if let v = Double($0.replacingOccurrences(of: ",", with: ".")) { setzen(v) } }
   ))
   .textFieldStyle(.roundedBorder)
   .frame(width: 90)
   Text("€")
     .font(.system(size: 12))
     .foregroundStyle(Premium.textFaint)
 }
}

// MARK: Audit & DSGVO

private var auditReiter: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 18) {
     Text("Datenschutz-Grundsätze dieser Installation")
       .font(.headline)
       .foregroundStyle(Premium.text)

     VStack(alignment: .leading, spacing: 6) {
       dsgvoPunkt("Lokale Speicherung", "Konten, Abos und KI-Protokolle liegen ausschließlich in Application Support auf diesem Gerät -- keine Übertragung an Dritte.")
       dsgvoPunkt("Passwort-Sicherheit", "Passwörter werden nie im Klartext gespeichert, nur als Salted-SHA256-Hash.")
       dsgvoPunkt("Datensparsamkeit", "Es werden nur Name, E-Mail und Nutzungsdaten erhoben, die für Abrechnung und Betrieb nötig sind (Art. 5 DSGVO).")
       dsgvoPunkt("Auskunft & Übertragbarkeit", "Vollständiger JSON-Export je Konto (Art. 15/20) -- im Konto-Detail.")
       dsgvoPunkt("Löschung", "Konto samt KI-Protokoll unwiderruflich löschbar (Art. 17) -- im Konto-Detail.")
       dsgvoPunkt("Nachvollziehbarkeit", "Alle Admin-Eingriffe werden im Audit-Log unten protokolliert.")
     }

     Divider().opacity(0.3)

     Text("Admin-Audit-Log")
       .font(.headline)
       .foregroundStyle(Premium.text)

     let eintraege = store.audit.sorted { $0.datum > $1.datum }.prefix(50)
     if eintraege.isEmpty {
       Text("Noch keine Admin-Aktionen protokolliert.")
         .font(.system(size: 11))
         .foregroundStyle(Premium.textFaint)
     } else {
       VStack(spacing: 1) {
         ForEach(Array(eintraege)) { e in
           HStack {
             Text(e.datum.formatted(date: .numeric, time: .shortened))
               .font(.system(size: 9.5, design: .monospaced))
               .foregroundStyle(Premium.textFaint)
               .frame(width: 110, alignment: .leading)
             Text(e.aktion)
               .font(.system(size: 10.5))
               .foregroundStyle(Premium.text)
             Spacer()
             Text(e.betroffen)
               .font(.system(size: 10))
               .foregroundStyle(Premium.textSoft)
             Text("durch \(e.admin)")
               .font(.system(size: 9.5))
               .foregroundStyle(Premium.textFaint)
           }
           .padding(.horizontal, 10).padding(.vertical, 6)
           .background(RoundedRectangle(cornerRadius: 6).fill(Premium.panel.opacity(0.5)))
         }
       }
     }
   }
   .padding(20)
   .frame(maxWidth: 760, alignment: .leading)
 }
 .frame(maxWidth: .infinity)
}

private func dsgvoPunkt(_ titel: String, _ text: String) -> some View {
 HStack(alignment: .top, spacing: 8) {
   Image(systemName: "checkmark.shield.fill")
     .font(.system(size: 11))
     .foregroundStyle(Premium.computed)
     .padding(.top, 1)
   VStack(alignment: .leading, spacing: 2) {
     Text(titel)
       .font(.system(size: 11.5, weight: .semibold))
       .foregroundStyle(Premium.text)
     Text(text)
       .font(.system(size: 10.5))
       .foregroundStyle(Premium.textSoft)
       .fixedSize(horizontal: false, vertical: true)
   }
 }
}

// MARK: Demo-KI-Lauf

private var demoLaufReiter: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 16) {
     VStack(alignment: .leading, spacing: 6) {
       Text("Demo-KI-Lauf")
         .font(.headline)
         .foregroundStyle(Premium.text)
       Text("Lässt die KIs echt über alle Demofälle laufen -- Vorgang-Rechenwerk, Fenylaw Strategies, Lexara, Strategos und Opportunisma. Jede Modulfunktion wird angestoßen und in KI-Protokoll und KI-Abrechnung verbucht. Ist keine KI erreichbar, greift automatisch die deterministische Heuristik.")
         .font(.system(size: 11))
         .foregroundStyle(Premium.textSoft)
         .fixedSize(horizontal: false, vertical: true)
     }

     HStack(spacing: 12) {
       Button {
         Task { await demo.starte() }
       } label: {
         Label(demo.laeuft ? "Lauf läuft …" : "Demo-KI-Lauf starten",
            systemImage: demo.laeuft ? "hourglass" : "sparkles")
           .font(.system(size: 12, weight: .semibold))
           .padding(.horizontal, 14).padding(.vertical, 9)
           .background(RoundedRectangle(cornerRadius: 9).fill(Premium.action))
           .foregroundStyle(Premium.onAction)
       }
       .buttonStyle(.plain)
       .disabled(demo.laeuft)

       Label("KI-Modus: \(demo.kiModusLabel)", systemImage: "cpu")
         .font(.system(size: 10.5))
         .foregroundStyle(Premium.textFaint)
       Spacer()
       if !demo.protokoll.isEmpty {
         Text("\(demo.erfolgreiche) KI · \(demo.fallbacks) Fallback")
           .font(.system(size: 10.5, weight: .semibold))
           .foregroundStyle(Premium.textSoft)
       }
     }

     if demo.laeuft || demo.fertig {
       VStack(alignment: .leading, spacing: 4) {
         ProgressView(value: demo.fortschritt)
           .tint(Premium.action)
         Text(demo.aktuellerSchritt)
           .font(.system(size: 10))
           .foregroundStyle(Premium.textFaint)
       }
     }

     if !demo.protokoll.isEmpty {
       VStack(spacing: 6) {
         ForEach(demo.protokoll) { e in
           demoLaufZeile(e)
         }
       }
     }
   }
   .padding(20)
   .frame(maxWidth: 820, alignment: .leading)
 }
 .frame(maxWidth: .infinity)
}

private func demoLaufZeile(_ e: DemoKILauf.Eintrag) -> some View {
 HStack(alignment: .top, spacing: 10) {
   Image(systemName: e.erfolg ? "checkmark.seal.fill" : "arrow.triangle.2.circlepath")
     .font(.system(size: 12))
     .foregroundStyle(e.erfolg ? Premium.computed : Premium.proposed)
     .padding(.top, 1)
   VStack(alignment: .leading, spacing: 3) {
     HStack(spacing: 6) {
       Text(e.modul.uppercased())
         .font(.system(size: 8.5, weight: .black))
         .kerning(0.5)
         .foregroundStyle(Premium.action)
       Text(e.aktion)
         .font(.system(size: 11.5, weight: .semibold))
         .foregroundStyle(Premium.text)
       Spacer()
       Text(e.quelle)
         .font(.system(size: 9))
         .foregroundStyle(Premium.textFaint)
     }
     Text(e.ergebnis)
       .font(.system(size: 10.5))
       .foregroundStyle(Premium.textSoft)
       .fixedSize(horizontal: false, vertical: true)
   }
 }
 .padding(.horizontal, 12).padding(.vertical, 9)
 .frame(maxWidth: .infinity, alignment: .leading)
 .background(RoundedRectangle(cornerRadius: 8).fill(Premium.panel.opacity(0.5)))
 .overlay(RoundedRectangle(cornerRadius: 8).stroke(Premium.hairline, lineWidth: 1))
}

// MARK: Export-Helfer

private func exportiereDaten(konto: Konto) {
 guard let json = store.datenExport(kontoId: konto.id) else { return }
 let panel = NSSavePanel()
 panel.nameFieldStringValue = "Datenauskunft-\(konto.email).json"
 panel.begin { result in
   guard result == .OK, let url = panel.url else { return }
   try? json.data(using: .utf8)?.write(to: url)
 }
}

private func exportiereCSV() {
 let csv = store.verbrauchAlsCSV()
 let panel = NSSavePanel()
 panel.nameFieldStringValue = "KI-Abrechnung-\(Date().formatted(.iso8601.year().month().day())).csv"
 panel.begin { result in
   guard result == .OK, let url = panel.url else { return }
   try? csv.data(using: .utf8)?.write(to: url)
 }
}

// MARK: Bausteine

private func gruppe<Inhalt: View>(_ titel: String, @ViewBuilder inhalt: () -> Inhalt) -> some View {
 VStack(alignment: .leading, spacing: 10) {
   Text(titel.uppercased())
     .font(.system(size: 9, weight: .black))
     .kerning(0.7)
     .foregroundStyle(Premium.textFaint)
   inhalt()
 }
 .padding(14)
 .frame(maxWidth: .infinity, alignment: .leading)
 .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Premium.panel.opacity(0.5)))
 .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Premium.hairline, lineWidth: 1))
}

private func kennzahl(_ titel: String, _ wert: String, symbol: String, hervorheben: Bool = false) -> some View {
 HStack(spacing: 8) {
   Image(systemName: symbol)
     .font(.system(size: 11))
     .foregroundStyle(hervorheben ? Premium.proposed : Premium.action)
   VStack(alignment: .leading, spacing: 1) {
     Text(titel.uppercased())
       .font(.system(size: 8, weight: .black))
       .kerning(0.4)
       .foregroundStyle(Premium.textFaint)
     Text(wert)
       .font(.system(size: 14, weight: .semibold, design: .rounded))
       .foregroundStyle(hervorheben ? Premium.proposed : Premium.text)
   }
 }
 .padding(.horizontal, 12).padding(.vertical, 8)
 .background(RoundedRectangle(cornerRadius: 9).fill(Premium.panel.opacity(0.6)))
 .overlay(RoundedRectangle(cornerRadius: 9).stroke(hervorheben ? Premium.proposed.opacity(0.4) : Premium.hairline, lineWidth: 1))
}
}

