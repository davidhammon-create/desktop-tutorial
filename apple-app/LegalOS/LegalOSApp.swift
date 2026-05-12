//
//  LegalOSApp.swift
//  LegalOS – Legal-Tech-App für macOS
//
//  Einstiegspunkt der App. Stellt globale Services per @StateObject
//  (AuthService, CloudKitService, ClaudeAPIService) zur Verfügung und
//  wechselt je nach Login-/Onboarding-Status zwischen Login, Onboarding
//  und der Haupt-App-Shell.
//

import SwiftUI

@main
struct LegalOSApp: App {

    // Globale Services als StateObject – leben so lange wie die App.
    @StateObject private var auth        = AuthService()
    @StateObject private var cloudKit    = CloudKitService()
    @StateObject private var claude      = ClaudeAPIService()
    @StateObject private var kiProvider  = KIProvider()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(cloudKit)
                .environmentObject(claude)
                .environmentObject(kiProvider)
                .frame(minWidth: 1100, minHeight: 720)
                .task {
                    // Beim Start: Login-Status aus Keychain wiederherstellen
                    await auth.restoreSession()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        Settings {
            SettingsView()
                .environmentObject(auth)
                .environmentObject(claude)
        }
    }
}

/// Wurzel-View: entscheidet ob Login, Onboarding oder Haupt-Shell gezeigt wird.
struct RootView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        Group {
            if auth.currentUser == nil {
                LoginView()
            } else if auth.currentUser?.onboardingDone == false {
                OnboardingView()
            } else {
                AppShell()
            }
        }
        .animation(.easeInOut, value: auth.currentUser?.id)
    }
}
