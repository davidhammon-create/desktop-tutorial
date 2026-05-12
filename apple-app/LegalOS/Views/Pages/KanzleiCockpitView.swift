//
//  KanzleiCockpitView.swift
//  Operatives Cockpit der Kanzlei – KPIs, Auslastung, Risiko.
//

import SwiftUI

struct KanzleiCockpitView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var cases: [Case] = []
    @State private var deadlines: [Deadline] = []
    @State private var tasks: [LegalTask] = []
    @State private var warnings: [CaseWarning] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Kanzlei-Cockpit").font(.title.weight(.semibold))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 12) {
                    kpi("Aktive Fälle", value: "\(cases.filter { $0.status == .aktiv }.count)", icon: "folder.fill", color: .blue)
                    kpi("Fristen offen", value: "\(deadlines.filter { $0.status == .offen }.count)", icon: "clock", color: .orange)
                    kpi("Aufgaben offen", value: "\(tasks.filter { $0.status != .erledigt }.count)", icon: "checklist", color: .green)
                    kpi("Warnungen", value: "\(warnings.filter { !$0.resolved }.count)", icon: "exclamationmark.triangle.fill", color: .red)
                }

                Text("Kritische Warnungen").font(.headline)
                ForEach(warnings.filter { $0.severity == .kritisch && !$0.resolved }) { w in
                    VStack(alignment: .leading) {
                        Text(w.title).font(.subheadline.weight(.medium))
                        if let d = w.warningDescription {
                            Text(d).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Kanzlei-Cockpit")
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func kpi(_ label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            VStack(alignment: .leading) {
                Text(value).font(.title3.weight(.semibold))
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @MainActor
    private func reload() async {
        cases     = (try? await cloudKit.fetch(Case.self)) ?? []
        deadlines = (try? await cloudKit.fetch(Deadline.self)) ?? []
        tasks     = (try? await cloudKit.fetch(LegalTask.self)) ?? []
        warnings  = (try? await cloudKit.fetch(CaseWarning.self)) ?? []
    }
}
