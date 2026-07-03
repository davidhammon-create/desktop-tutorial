import SwiftUI

struct SubscriptionsView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""

    var filtered: [Subscription] {
        let base = store.subscriptions.sorted { $0.amount > $1.amount }
        guard !search.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                if store.subscriptions.isEmpty {
                    Text("Noch keine Abos erkannt. Verbinde ein Konto und starte den Scan in der Übersicht.")
                        .foregroundStyle(.secondary)
                }
                ForEach(filtered) { sub in
                    NavigationLink(value: sub.id) {
                        SubscriptionRow(sub: sub)
                    }
                }
            }
            .searchable(text: $search, prompt: "Abo suchen")
            .navigationTitle("Abos & Zahlungen")
            .navigationDestination(for: UUID.self) { id in
                if let sub = store.subscriptions.first(where: { $0.id == id }) {
                    SubscriptionDetailView(subId: sub.id)
                }
            }
        }
    }
}

struct SubscriptionRow: View {
    let sub: Subscription

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: sub.status.icon)
                .foregroundStyle(sub.status.color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(sub.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                    if sub.conversion.confirmed {
                        Text("✓ Sparplan aktiv").font(.caption2.weight(.bold)).foregroundStyle(.green)
                    }
                    if sub.paused {
                        Text("⏸").font(.caption)
                    }
                }
                Text("\(sub.category) · \(sub.cycle) · \(sub.occurrences)× erkannt")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(sub.amount.euro).font(.subheadline.weight(.bold))
        }
        .opacity(sub.paused ? 0.5 : 1)
    }
}

struct SubscriptionDetailView: View {
    @EnvironmentObject var store: AppStore
    let subId: UUID
    @State private var aiText: String?
    @State private var aiRunning = false

    var sub: Subscription? { store.subscriptions.first { $0.id == subId } }

    var body: some View {
        if let sub {
            Form {
                Section {
                    LabeledContent("Betrag", value: "\(sub.amount.euro) \(sub.cycle)")
                    LabeledContent("Kategorie", value: sub.category)
                    LabeledContent("Seit", value: sub.sinceMonth)
                    if let iban = sub.iban { LabeledContent("IBAN", value: iban) }
                    if !sub.note.isEmpty {
                        Text(sub.note).font(.callout).foregroundStyle(sub.status == .warning ? .red : .orange)
                    }
                }

                Section("Status") {
                    Picker("Status", selection: statusBinding(sub)) {
                        ForEach(SubStatus.allCases, id: \.self) { s in
                            Label(s.label, systemImage: s.icon).tag(s)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    Toggle("Pausiert", isOn: pausedBinding(sub))
                }

                if let link = CancelLink.find(for: sub.name), let url = URL(string: link.url) {
                    Section("Kündigen (Kündigungsbutton-Gesetz)") {
                        Link(destination: url) {
                            Label(link.label, systemImage: "xmark.circle")
                        }
                    }
                }

                Section("Umwandeln: Abo → Sparplan") {
                    let isin = sub.conversion.etfIsin ?? "IE00B4L5Y983"
                    let wealth = FinMath.futureValue(monthly: sub.monthlyAmount, annualPct: 7.1, years: 25)
                    Text("Derselbe Betrag (\(sub.monthlyAmount.euro)/Monat) im MSCI World über 25 Jahre: ≈ \(wealth.euro)*")
                        .font(.callout)
                    ForEach(Broker.all) { broker in
                        if let url = broker.etfUrl(isin: isin) {
                            Link(destination: url) {
                                HStack(spacing: 10) {
                                    Text(broker.letter)
                                        .font(.caption.weight(.bold)).foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color(hex: broker.colorHex), in: RoundedRectangle(cornerRadius: 7))
                                    Text("\(broker.name) öffnen")
                                }
                            }
                        }
                    }
                    ChecklistRow(title: "Abo gekündigt", done: sub.conversion.cancelled) { toggle(\.cancelled, sub) }
                    ChecklistRow(title: "Sparplan angelegt", done: sub.conversion.planCreated) { toggle(\.planCreated, sub) }
                    ChecklistRow(title: "Betrag bestätigt — zählt als umgewandelt", done: sub.conversion.confirmed) { toggle(\.confirmed, sub) }
                }

                if store.aiEnabled {
                    Section("Apple Intelligence (on-device)") {
                        Button(aiRunning ? "Analysiert…" : "Seriosität einschätzen") {
                            runAI { try await AppleAI.companyAssessment(for: sub) }
                        }
                        Button("Kündigungsschreiben erstellen") {
                            runAI { try await AppleAI.cancellationLetter(for: sub) }
                        }
                        if let aiText {
                            Text(aiText).font(.callout).textSelection(.enabled)
                        }
                        if !AppleAI.isAvailable {
                            Text(AppleAI.availabilityText).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button("Abo entfernen", role: .destructive) { store.removeSubscription(sub) }
                }
            }
            .navigationTitle(sub.name)
        } else {
            Text("Abo nicht gefunden.")
        }
    }

    private func statusBinding(_ sub: Subscription) -> Binding<SubStatus> {
        Binding(
            get: { sub.status },
            set: { newValue in
                var s = sub
                s.status = newValue
                store.update(s)
            }
        )
    }

    private func pausedBinding(_ sub: Subscription) -> Binding<Bool> {
        Binding(
            get: { sub.paused },
            set: { newValue in
                var s = sub
                s.paused = newValue
                store.update(s)
            }
        )
    }

    private func toggle(_ keyPath: WritableKeyPath<Conversion, Bool>, _ sub: Subscription) {
        var s = sub
        s.conversion[keyPath: keyPath].toggle()
        store.update(s)
    }

    private func runAI(_ work: @escaping () async throws -> String) {
        aiRunning = true
        Task {
            do { aiText = try await work() }
            catch { aiText = error.localizedDescription }
            aiRunning = false
        }
    }
}

struct ChecklistRow: View {
    let title: String
    let done: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(done ? .green : .secondary)
                Text(title)
                    .strikethrough(done)
                    .foregroundStyle(.primary)
            }
        }
    }
}
