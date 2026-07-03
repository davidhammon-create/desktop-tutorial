import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    @State private var aiResult: String?
    @State private var aiRunning = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Button {
                        store.scan()
                    } label: {
                        Label("Konten scannen — ohne KI", systemImage: "wand.and.rays")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if let summary = store.lastScanSummary {
                        InfoCard(icon: "checkmark.circle.fill", tint: .green, title: "Algorithmus-Scan abgeschlossen", text: summary)
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                        StatCard(title: "Monatliche Abo-Kosten", value: store.monthlyTotal.euro, tint: .primary)
                        StatCard(title: "Aktiv umgewandelt", value: store.convertedSum.euro + "/Mon.", tint: .green)
                        StatCard(title: "Umwandlungs-Potenzial", value: store.conversionPotential.euro + "/Mon.", tint: .blue)
                        StatCard(title: "Warnungen", value: "\(store.warningsCount)", tint: store.warningsCount > 0 ? .red : .secondary)
                    }

                    if !store.pendingConversions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Umwandlungen abschließen", systemImage: "checklist")
                                .font(.headline)
                                .foregroundStyle(.blue)
                            ForEach(store.pendingConversions.prefix(4)) { sub in
                                let missing = !sub.conversion.cancelled ? "Kündigung fehlt noch"
                                    : !sub.conversion.planCreated ? "Sparplan fehlt noch" : "Bestätigung fehlt noch"
                                let wealth = FinMath.futureValue(monthly: sub.monthlyAmount, annualPct: 7.1, years: 25)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(sub.name) · \(sub.monthlyAmount.euro)/Monat").font(.subheadline.weight(.semibold))
                                    Text("\(missing) — ≈ \(wealth.euro) in 25 J. warten.*")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                    }

                    let warningSubs = store.subscriptions.filter { $0.status == .warning }
                    if !warningSubs.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Verdächtige Abbuchungen", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundStyle(.red)
                            ForEach(warningSubs) { sub in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(sub.name) · \(sub.amount.euro)").font(.subheadline.weight(.semibold))
                                    if !sub.note.isEmpty {
                                        Text(sub.note).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                    }

                    if store.aiEnabled {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Apple Intelligence", systemImage: "sparkles")
                                .font(.headline)
                            Text(AppleAI.availabilityText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if AppleAI.isAvailable, let worst = store.subscriptions.first(where: { $0.status == .warning }) {
                                Button(aiRunning ? "Analysiert on-device…" : "Verdächtigstes Abo per Apple Intelligence prüfen") {
                                    aiRunning = true
                                    Task {
                                        aiResult = (try? await AppleAI.companyAssessment(for: worst)) ?? "Analyse fehlgeschlagen."
                                        aiRunning = false
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(aiRunning)
                            }
                            if let aiResult {
                                Text(aiResult).font(.callout)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.purple.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                    }

                    Text("*Modellrechnung mit historischen Durchschnittsrenditen — keine Garantie, keine Anlageberatung.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding()
            }
            .navigationTitle("Übersicht")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.bold)).foregroundStyle(tint)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct InfoCard: View {
    let icon: String
    let tint: Color
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon).font(.headline).foregroundStyle(tint)
            Text(text).font(.callout).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}
