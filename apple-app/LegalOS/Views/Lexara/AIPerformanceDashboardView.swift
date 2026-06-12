//
//  AIPerformanceDashboardView.swift
//  Konversion von src/components/lexara/AIPerformanceDashboard.jsx (570 Zeilen).
//  Zeigt KPIs und Trend zu KI-Performance für einen Fall, ermöglicht Anlegen
//  und Bearbeiten von AIPerformanceFeedback und Bewertung von KIUsageLogs.
//

import SwiftUI
import Charts

struct AIPerformanceDashboardView: View {
    let caseId: String

    @EnvironmentObject var cloudKit: CloudKitService

    @State private var feedbacks: [AIPerformanceFeedback] = []
    @State private var kiLogs: [KIUsageLog] = []
    @State private var loading = true
    @State private var saving = false

    @State private var showForm = false
    @State private var form = FormState()
    @State private var editing: AIPerformanceFeedback? = nil
    @State private var editForm = FormState()

    @State private var ratingLog: KIUsageLog? = nil
    @State private var ratingValue: Int = 0
    @State private var ratingFeedback: String = ""

    @State private var filterPeriod: Period = .all
    @State private var filterAdvisor: String = "all"
    @State private var showKiHistory = false

    enum Period: String, CaseIterable, Identifiable {
        case all, month, quarter
        var id: Self { self }
        var label: String {
            switch self { case .all: return "Alle"; case .month: return "Diesen Monat"; case .quarter: return "Dieses Quartal" }
        }
    }

    struct FormState {
        var prognoseRating: Double? = nil
        var strategieRating: Double? = nil
        var kiBeraterRating: Double? = nil
        var gesamtbewertung: Double? = nil
        var fallErfolgreich: Bool? = nil
        var kiFeedback: String = ""
    }

    struct Stats {
        var totalCases: Int
        var prognosisAccuracy: Double
        var strategyEffectiveness: Double
        var beraterQuality: Double
        var overallScore: Double
        var successRate: Double
        var topImprovements: [Improvement]
    }
    struct Improvement: Identifiable {
        let id = UUID()
        let aspect: String
        let count: Int
        let problems: [String]
    }
    struct TrendPoint: Identifiable {
        let id = UUID()
        let date: String
        let gesamtbewertung: Double
        let erfolgsquote: Double
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if loading {
                    ProgressView().frame(maxWidth: .infinity).padding()
                } else {
                    if showForm { formCard }
                    Button {
                        showForm.toggle()
                    } label: {
                        Text("+ Neue Bewertung hinzufügen")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain)

                    filterCard
                    if !trendData.isEmpty { trendCard }

                    if let s = stats { statsContent(s) }
                    else { emptyState }
                }
            }
            .padding(20)
        }
        .task { await loadData() }
        .sheet(item: $editing) { fb in editSheet(fb) }
        .sheet(item: $ratingLog) { log in ratingSheet(log) }
    }

    // MARK: - Subviews

    private var formCard: some View {
        GroupBox("Neue KI-Performance Bewertung") {
            VStack(alignment: .leading, spacing: 10) {
                ratingField("Prognose-Rating (1-5)", value: $form.prognoseRating)
                ratingField("Strategie-Rating (1-5)", value: $form.strategieRating)
                ratingField("KI-Berater Rating (1-5)", value: $form.kiBeraterRating)
                ratingField("Gesamtbewertung (1-5)", value: $form.gesamtbewertung)
                Text("KI-Feedback").font(.caption).foregroundColor(.secondary)
                TextEditor(text: $form.kiFeedback).frame(minHeight: 60)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
                Text("Fall erfolgreich?").font(.caption).foregroundColor(.secondary)
                HStack {
                    Button("Ja") { form.fallErfolgreich = true }
                        .buttonStyle(.borderedProminent)
                        .tint(form.fallErfolgreich == true ? .green : .gray)
                    Button("Nein") { form.fallErfolgreich = false }
                        .buttonStyle(.borderedProminent)
                        .tint(form.fallErfolgreich == false ? .red : .gray)
                }
                HStack {
                    Button("Abbrechen") { form = FormState(); showForm = false }
                        .buttonStyle(.bordered)
                    Button(saving ? "Speichert…" : "Speichern") {
                        Task { await handleCreate() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(saving || form.gesamtbewertung == nil)
                }
            }
            .padding(8)
        }
    }

    private func ratingField(_ label: String, value: Binding<Double?>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(.secondary)
            TextField("", value: value, format: .number).textFieldStyle(.roundedBorder)
        }
    }

    private var filterCard: some View {
        GroupBox("Filter") {
            HStack {
                Picker("Zeitraum", selection: $filterPeriod) {
                    ForEach(Period.allCases) { Text($0.label).tag($0) }
                }
                Picker("KI-Berater", selection: $filterAdvisor) {
                    Text("Alle").tag("all")
                    ForEach(advisors, id: \.self) { Text($0).tag($0) }
                }
            }.padding(8)
        }
    }

    private var trendCard: some View {
        GroupBox("Performance-Trend") {
            Chart(trendData) { p in
                LineMark(x: .value("Datum", p.date), y: .value("Gesamtbewertung", p.gesamtbewertung))
                    .foregroundStyle(.blue)
                LineMark(x: .value("Datum", p.date), y: .value("Erfolgsquote", p.erfolgsquote))
                    .foregroundStyle(.green)
            }
            .frame(height: 250)
            .padding(8)
        }
    }

    private func statsContent(_ s: Stats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard("Prognose-Genauigkeit", value: "\(String(format: "%.2f", s.prognosisAccuracy))/5", subtitle: "Basierend auf \(s.totalCases) Fällen", icon: iconFor(s.prognosisAccuracy), tint: tintFor(s.prognosisAccuracy))
                statCard("Strategie-Effektivität", value: "\(String(format: "%.2f", s.strategyEffectiveness))/5", subtitle: "Qualität der Strategieempfehlungen", icon: "chart.line.uptrend.xyaxis", tint: tintFor(s.strategyEffectiveness))
                statCard("KI-Berater Qualität", value: "\(String(format: "%.2f", s.beraterQuality))/5", subtitle: "Hilfreiche & akkurate Analysen", icon: "bolt.fill", tint: tintFor(s.beraterQuality))
                statCard("Erfolgsquote", value: "\(String(format: "%.1f", s.successRate))%", subtitle: "\(Int(Double(s.totalCases) * s.successRate / 100)) von \(s.totalCases) Fällen", icon: "checkmark.circle.fill", tint: .blue)
            }
            GroupBox("Gesamtbewertung") {
                HStack {
                    Text(String(format: "%.2f", s.overallScore)).font(.system(size: 36, weight: .bold))
                    VStack(alignment: .leading) {
                        ProgressView(value: s.overallScore / 5).tint(tintFor(s.overallScore))
                        Text(s.overallScore >= 4 ? "Ausgezeichnete Performance" : s.overallScore >= 3 ? "Gute Performance" : "Verbesserung erforderlich")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }.padding(8)
            }
            GroupBox("Bewertungen") {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(filteredFeedbacks) { fb in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(fb.caseName ?? fb.caseId).font(.caption.weight(.medium))
                                    Text("Bewertung: \(String(format: "%.1f", fb.gesamtbewertung))/5").font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer()
                                Button { editing = fb; editForm = FormState(prognoseRating: fb.prognoseRating, strategieRating: fb.strategieRating, kiBeraterRating: fb.kiBeraterRating, gesamtbewertung: fb.gesamtbewertung, fallErfolgreich: fb.fallErfolgreich, kiFeedback: fb.kiBeraterFeedback ?? "") } label: {
                                    Image(systemName: "pencil")
                                }.buttonStyle(.plain)
                            }
                            .padding(8).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }.frame(maxHeight: 300)
            }
            GroupBox {
                HStack {
                    Text("KI-Nutzungs-Historie").font(.headline)
                    Spacer()
                    Button(showKiHistory ? "Ausblenden" : "Anzeigen (\(kiLogs.count))") {
                        showKiHistory.toggle()
                    }.buttonStyle(.plain).foregroundColor(.blue)
                }
                if showKiHistory {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(kiLogs) { log in kiLogRow(log) }
                        }
                    }.frame(maxHeight: 300)
                }
            }
            if !s.topImprovements.isEmpty {
                GroupBox("Häufigste Verbesserungsbedarfe") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(s.topImprovements) { imp in
                            HStack {
                                Text("\(imp.count)").font(.headline).frame(width: 32, height: 32).background(Color.blue.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 6))
                                VStack(alignment: .leading) {
                                    Text(imp.aspect.replacingOccurrences(of: "_", with: " ").capitalized).font(.subheadline.weight(.semibold))
                                    Text(imp.problems.prefix(2).joined(separator: ", ")).font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            if s.overallScore < 4 {
                GroupBox("Empfehlungen") {
                    VStack(alignment: .leading, spacing: 4) {
                        if s.prognosisAccuracy < 3 { Text("• Prognosen überprüfen – Kalibrierung empfohlen") }
                        if s.strategyEffectiveness < 3 { Text("• Strategieanalyse verstärken") }
                        if s.beraterQuality < 3 { Text("• KI-Berater Prompts optimieren") }
                        if s.successRate < 60 { Text("• Fallauswahl überprüfen") }
                    }.font(.caption).foregroundColor(.orange)
                }
            }
        }
    }

    private func kiLogRow(_ log: KIUsageLog) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading) {
                    Text(log.kiFunction).font(.caption.weight(.semibold))
                    Text(log.context ?? "").font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                if let r = log.rating {
                    HStack(spacing: 2) {
                        ForEach(0..<Int(r), id: \.self) { _ in Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption2) }
                    }
                } else {
                    Button("Bewerten") {
                        ratingLog = log; ratingValue = 0; ratingFeedback = log.feedback ?? ""
                    }.buttonStyle(.bordered).controlSize(.mini)
                }
            }
            Text(String(log.output.prefix(100)) + "…").font(.caption2).foregroundColor(.secondary).lineLimit(2)
        }
        .padding(8).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var emptyState: some View {
        VStack {
            Text("Noch keine KI-Bewertungen vorhanden").foregroundColor(.secondary).padding()
        }.frame(maxWidth: .infinity).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statCard(_ title: String, value: String, subtitle: String, icon: String, tint: Color) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title).font(.caption.weight(.semibold)).foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: icon).foregroundColor(tint)
                }
                Text(value).font(.title.weight(.bold))
                Text(subtitle).font(.caption2).foregroundColor(.secondary)
            }.padding(8)
        }
    }

    private func editSheet(_ fb: AIPerformanceFeedback) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Bewertung bearbeiten").font(.headline); Spacer()
                Button { editing = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
            }
            ratingField("Gesamtbewertung (1-5)", value: $editForm.gesamtbewertung)
            Text("KI-Feedback").font(.caption).foregroundColor(.secondary)
            TextEditor(text: $editForm.kiFeedback).frame(minHeight: 80)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
            HStack {
                Button("Abbrechen") { editing = nil }.buttonStyle(.bordered)
                Button(saving ? "Speichert…" : "Speichern") { Task { await handleEditSave() } }
                    .buttonStyle(.borderedProminent).disabled(saving)
            }
        }.padding(20).frame(width: 460)
    }

    private func ratingSheet(_ log: KIUsageLog) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("KI-Nutzung bewerten").font(.headline); Spacer()
                Button { ratingLog = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
            }
            ScrollView { Text(log.output).font(.system(.caption, design: .monospaced)) }.frame(height: 120).padding(6).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 6))
            Text("Bewertung (1-5)").font(.caption).foregroundColor(.secondary)
            HStack {
                ForEach(1...5, id: \.self) { i in
                    Button { ratingValue = i } label: {
                        Image(systemName: i <= ratingValue ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }.buttonStyle(.plain)
                }
            }
            Text("Feedback").font(.caption).foregroundColor(.secondary)
            TextEditor(text: $ratingFeedback).frame(minHeight: 60).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
            HStack {
                Button("Abbrechen") { ratingLog = nil }.buttonStyle(.bordered)
                Button(saving ? "Speichert…" : "Bewertung speichern") { Task { await handleRateKiLog() } }
                    .buttonStyle(.borderedProminent).tint(.yellow).disabled(saving || ratingValue == 0)
            }
        }.padding(20).frame(width: 460)
    }

    // MARK: - Computed

    private var advisors: [String] { [] }

    private var trendData: [TrendPoint] {
        let sorted = feedbacks
        let groups = Dictionary(grouping: sorted) { _ in "" } // dates not in model
        return groups.map { _, items in
            TrendPoint(date: "", gesamtbewertung: items.map(\.gesamtbewertung).reduce(0,+) / Double(max(items.count,1)), erfolgsquote: Double(items.filter(\.fallErfolgreich).count))
        }
    }

    private var filteredFeedbacks: [AIPerformanceFeedback] { feedbacks }

    private var stats: Stats? {
        guard !feedbacks.isEmpty else { return nil }
        let prog = feedbacks.compactMap(\.prognoseRating)
        let strat = feedbacks.compactMap(\.strategieRating)
        let berater = feedbacks.compactMap(\.kiBeraterRating)
        let overall = feedbacks.map(\.gesamtbewertung)
        let success = Double(feedbacks.filter(\.fallErfolgreich).count) / Double(feedbacks.count) * 100
        return Stats(
            totalCases: feedbacks.count,
            prognosisAccuracy: avg(prog),
            strategyEffectiveness: avg(strat),
            beraterQuality: avg(berater),
            overallScore: avg(overall),
            successRate: success,
            topImprovements: []
        )
    }
    private func avg(_ a: [Double]) -> Double { a.isEmpty ? 0 : a.reduce(0,+) / Double(a.count) }

    private func iconFor(_ s: Double) -> String { s >= 4 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill" }
    private func tintFor(_ s: Double) -> Color { s >= 4 ? .green : s >= 3 ? .yellow : .red }

    // MARK: - Actions

    private func loadData() async {
        loading = true
        defer { loading = false }
        do {
            feedbacks = try await cloudKit.fetch(AIPerformanceFeedback.self)
            kiLogs = try await cloudKit.fetchForCase(KIUsageLog.self, caseId: caseId)
        } catch { cloudKit.lastError = error.localizedDescription }
    }

    private func handleCreate() async {
        guard let g = form.gesamtbewertung else { return }
        saving = true; defer { saving = false }
        var fb = AIPerformanceFeedback(caseId: caseId, gesamtbewertung: g)
        fb.prognoseRating = form.prognoseRating
        fb.strategieRating = form.strategieRating
        fb.kiBeraterRating = form.kiBeraterRating
        fb.kiBeraterFeedback = form.kiFeedback
        fb.fallErfolgreich = form.fallErfolgreich ?? false
        do {
            _ = try await cloudKit.save(fb)
            form = FormState(); showForm = false
            await loadData()
        } catch { cloudKit.lastError = error.localizedDescription }
    }

    private func handleEditSave() async {
        guard var fb = editing else { return }
        saving = true; defer { saving = false }
        if let g = editForm.gesamtbewertung { fb.gesamtbewertung = g }
        fb.kiBeraterFeedback = editForm.kiFeedback
        do {
            _ = try await cloudKit.save(fb)
            editing = nil
            await loadData()
        } catch { cloudKit.lastError = error.localizedDescription }
    }

    private func handleRateKiLog() async {
        guard var log = ratingLog else { return }
        saving = true; defer { saving = false }
        log.rating = Double(ratingValue)
        log.feedback = ratingFeedback
        do {
            _ = try await cloudKit.save(log)
            ratingLog = nil
            await loadData()
        } catch { cloudKit.lastError = error.localizedDescription }
    }
}
