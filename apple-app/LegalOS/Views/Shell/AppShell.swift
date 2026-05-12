//
//  AppShell.swift
//  Haupt-Navigation für macOS: NavigationSplitView mit Sidebar.
//

import SwiftUI

enum AppRoute: String, Hashable, CaseIterable {
    case home          = "Übersicht"
    case lexara        = "LEXARA Dashboard"
    case cases         = "Fälle"
    case mandanten     = "Mandanten"
    case zeitleiste    = "Zeitleiste"
    case aufgaben      = "Aufgaben"
    case strategos     = "Strategos"
    case suntzu        = "Sun Tzu / Machiavelli"
    case fallassistent = "Fall-Assistent"
    case richter       = "Richter-Profile"
    case modules       = "Module"
    case cockpit       = "Kanzlei-Cockpit"
    case analytik      = "Kanzlei-Analytik"
    case compliance    = "KI-Compliance"
    case plattform     = "Plattform-Agent"

    var symbol: String {
        switch self {
        case .home:          return "house"
        case .lexara:        return "rectangle.3.group"
        case .cases:         return "folder"
        case .mandanten:     return "person.2"
        case .zeitleiste:    return "calendar"
        case .aufgaben:      return "checklist"
        case .strategos:     return "shield.lefthalf.filled"
        case .suntzu:        return "books.vertical"
        case .fallassistent: return "bubble.left.and.text.bubble.right"
        case .richter:       return "person.badge.shield.checkmark"
        case .modules:       return "square.grid.2x2"
        case .cockpit:       return "speedometer"
        case .analytik:      return "chart.line.uptrend.xyaxis"
        case .compliance:    return "checkmark.shield"
        case .plattform:     return "cpu"
        }
    }
}

struct AppShell: View {
    @State private var selection: AppRoute? = .home

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            detail(for: selection ?? .home)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func detail(for route: AppRoute) -> some View {
        NavigationStack {
            switch route {
            case .home:          HomeView()
            case .lexara:        LexaraDashboardView()
            case .cases:         LexaraDashboardView()
            case .mandanten:     MandantenView()
            case .zeitleiste:    ZeitleisteView()
            case .aufgaben:      AufgabenView()
            case .strategos:     StrategosView()
            case .suntzu:        SunTzuMachiavelView()
            case .fallassistent: FallAssistentChatView()
            case .richter:       RichterProfileView()
            case .modules:       ModulesView()
            case .cockpit:       KanzleiCockpitView()
            case .analytik:      KanzleiAnalytikView()
            case .compliance:    KIComplianceView()
            case .plattform:     PlattformAgentView()
            }
        }
    }
}
