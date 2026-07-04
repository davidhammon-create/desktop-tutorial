import SwiftUI

@main
struct AboWandlerApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if store.currentProfileId == nil {
                    ProfilePickerView()
                } else {
                    TabView {
                        DashboardView()
                            .tabItem { Label("Übersicht", systemImage: "circle.grid.2x2") }
                        AccountsView()
                            .tabItem { Label("Konten", systemImage: "building.columns") }
                        SubscriptionsView()
                            .tabItem { Label("Abos", systemImage: "list.bullet.rectangle") }
                        InvestView()
                            .tabItem { Label("Investieren", systemImage: "chart.line.uptrend.xyaxis") }
                        RadarView()
                            .tabItem { Label("Radar", systemImage: "safari") }
                        SettingsView()
                            .tabItem { Label("Einstellungen", systemImage: "gearshape") }
                    }
                }
            }
            .environmentObject(store)
        }
    }
}
