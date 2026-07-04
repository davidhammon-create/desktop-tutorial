import SwiftUI
import Charts

struct InvestView: View {
    @EnvironmentObject var store: AppStore
    @State private var monthly: Double = 59.99
    @State private var years: Double = 15
    @State private var assetClass = "alle"
    @State private var selected: InvestAsset = InvestAsset.universe[0]
    @State private var aiNote: String?
    @State private var aiRunning = false

    let classes: [(String, String)] = [
        ("alle", "Alle"), ("etf", "ETFs"), ("aktie", "Aktien"),
        ("anleihe", "Anleihen"), ("rohstoff", "Rohstoffe"), ("portfolio", "Mixe"),
    ]

    var filteredAssets: [InvestAsset] {
        assetClass == "alle" ? InvestAsset.universe : InvestAsset.universe.filter { $0.assetClass == assetClass }
    }

    var projection: Double { FinMath.futureValue(monthly: monthly, annualPct: selected.ret, years: years) }
    var invested: Double { monthly * 12 * years }

    var body: some View {
        NavigationStack {
            Form {
                Section("Monatlicher Betrag (z.B. dein gekündigtes Abo)") {
                    HStack {
                        Slider(value: $monthly, in: 5...300, step: 1)
                        Text(monthly.euro).font(.headline).frame(width: 90, alignment: .trailing)
                    }
                    let convertible = store.subscriptions.filter { $0.status == .convert }
                    if !convertible.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(convertible) { sub in
                                    Button("\(sub.name) (\(sub.monthlyAmount.euro))") { monthly = sub.monthlyAmount }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                }
                            }
                        }
                    }
                    HStack {
                        Slider(value: $years, in: 1...50, step: 1)
                        Text("\(Int(years)) J.").font(.headline).frame(width: 90, alignment: .trailing)
                    }
                }

                Section("Anlage wählen") {
                    Picker("Klasse", selection: $assetClass) {
                        ForEach(classes, id: \.0) { value, label in Text(label).tag(value) }
                    }
                    .pickerStyle(.menu)
                    ForEach(filteredAssets) { asset in
                        Button {
                            selected = asset
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(asset.name).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                                    Text("\(asset.desc) · Risiko: \(asset.risk)")
                                        .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                    if let mix = asset.mix {
                                        Text("Mix: \(mix)").font(.caption2).foregroundStyle(.tertiary)
                                    }
                                }
                                Spacer()
                                Text("\(asset.ret, specifier: "%.1f")% p.a.*")
                                    .font(.subheadline.weight(.bold)).foregroundStyle(.green)
                                if selected.id == asset.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section("Prognose: \(selected.name)") {
                    LabeledContent("Eingezahlt", value: invested.euro)
                    LabeledContent("Mögliches Vermögen*") {
                        Text(projection.euro).fontWeight(.bold).foregroundStyle(.green)
                    }
                    LabeledContent("Davon Zinseszins", value: (projection - invested).euro)
                    LabeledContent("Renten-Boost (4%-Regel)*", value: (projection * 0.04 / 12).euro + "/Mon.")

                    Chart {
                        ForEach(0...Int(years), id: \.self) { year in
                            LineMark(
                                x: .value("Jahr", year),
                                y: .value("Vermögen", FinMath.futureValue(monthly: monthly, annualPct: selected.ret, years: Double(year)))
                            )
                            .foregroundStyle(.green)
                            AreaMark(
                                x: .value("Jahr", year),
                                y: .value("Vermögen", FinMath.futureValue(monthly: monthly, annualPct: selected.ret, years: Double(year)))
                            )
                            .foregroundStyle(.green.opacity(0.12))
                        }
                    }
                    .frame(height: 160)
                }

                if store.aiEnabled {
                    Section {
                        Button(aiRunning ? "Analysiert on-device…" : "Vergangenheit, Trends & Kausalketten einordnen (\(Pricing.kiInvest.euro))") {
                            guard AppleAI.isAvailable else {
                                aiNote = AppleAI.availabilityText
                                return
                            }
                            guard store.charge(action: "KI-Anlage-Einordnung: \(selected.name)", cost: Pricing.kiInvest) else {
                                aiNote = store.paidServicesHint
                                return
                            }
                            aiRunning = true
                            Task {
                                do { aiNote = try await AppleAI.investNote(for: selected, monthly: monthly, years: Int(years)) }
                                catch { aiNote = error.localizedDescription }
                                aiRunning = false
                            }
                        }
                        .disabled(aiRunning)
                        if let aiNote {
                            Text(aiNote).font(.callout).textSelection(.enabled)
                        }
                    } header: {
                        Text("Apple Intelligence: Einordnung")
                    } footer: {
                        Text("Kostenpflichtig — wird deinem Profil zugewiesen.")
                    }
                }

                Section {
                    Text("*Modellrechnung mit historischen Durchschnittsrenditen. Keine Anlageberatung, keine Garantie — Verluste sind möglich.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Investieren")
        }
    }
}
