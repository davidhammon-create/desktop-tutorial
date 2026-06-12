//
//  HomeView.swift
//  Marketing-/Übersichtsseite. In der Native-App wird sie zum
//  Schnellzugriff auf Hauptfunktionen und KPIs.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var cases: [Case] = []
    @State private var deadlines: [Deadline] = []
    @State private var loading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                kpiRow
                quickActions
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Übersicht")
        .task { await reload() }
        .refreshable { await reload() }
    }

    private var greeting: String {
        if let name = auth.currentUser?.fullName, !name.isEmpty {
            return "Willkommen zurück, \(name)."
        }
        return "Willkommen zurück."
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.title.weight(.semibold))
            Text("Deine Legal-OS für Strategie, Fristen und KI-Analyse.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var kpiRow: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 12) {
            kpi(title: "Aktive Fälle", value: "\(cases.filter { $0.status == .aktiv }.count)",
                icon: "folder.fill.badge.gearshape", color: .blue)
            kpi(title: "Offene Fristen",
                value: "\(deadlines.filter { $0.status == .offen }.count)",
                icon: "clock.badge.exclamationmark", color: .orange)
            kpi(title: "KI-Credits",
                value: "\(auth.currentUser?.kiCredits ?? 0)",
                icon: "sparkles", color: .purple)
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schnellaktionen").font(.headline)
            HStack(spacing: 12) {
                NavigationLink(destination: LexaraDashboardView()) {
                    actionCard(title: "Neuer Fall", icon: "plus.rectangle.on.folder")
                }
                NavigationLink(destination: StrategosView()) {
                    actionCard(title: "Strategos", icon: "shield.lefthalf.filled")
                }
                NavigationLink(destination: FallAssistentChatView()) {
                    actionCard(title: "KI-Assistent", icon: "sparkles")
                }
            }
        }
    }

    private func kpi(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            VStack(alignment: .leading) {
                Text(value).font(.title2.weight(.semibold))
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func actionCard(title: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2)
            Text(title).font(.footnote)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @MainActor
    private func reload() async {
        loading = true
        defer { loading = false }
        cases = (try? await cloudKit.fetch(Case.self)) ?? []
        deadlines = (try? await cloudKit.fetch(Deadline.self)) ?? []
    }
}
