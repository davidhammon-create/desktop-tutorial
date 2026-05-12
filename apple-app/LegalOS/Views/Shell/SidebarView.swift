//
//  SidebarView.swift
//  Sidebar (Master) der NavigationSplitView.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: AppRoute?
    @EnvironmentObject var auth: AuthService

    var body: some View {
        List(selection: $selection) {
            Section("Haupt") {
                ForEach([AppRoute.home, .lexara, .cases, .mandanten, .zeitleiste, .aufgaben], id: \.self) { r in
                    Label(r.rawValue, systemImage: r.symbol).tag(r)
                }
            }
            Section("Strategie") {
                ForEach([AppRoute.strategos, .suntzu, .fallassistent, .richter], id: \.self) { r in
                    Label(r.rawValue, systemImage: r.symbol).tag(r)
                }
            }
            Section("Kanzlei") {
                ForEach([AppRoute.modules, .cockpit, .analytik, .compliance, .plattform], id: \.self) { r in
                    Label(r.rawValue, systemImage: r.symbol).tag(r)
                }
            }
            if let u = auth.currentUser {
                Section("Account") {
                    VStack(alignment: .leading) {
                        Text(u.fullName ?? u.email).font(.subheadline.weight(.medium))
                        Text(u.jurisdiction.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                    Button(role: .destructive) { auth.logout() } label: {
                        Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
        }
        .navigationTitle("LegalOS")
        #if os(macOS)
        .listStyle(.sidebar)
        #endif
    }
}
