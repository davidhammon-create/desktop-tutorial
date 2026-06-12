//
//  SettingsView.swift
//  Einstellungen-Fenster (CMD+,) – Claude API-Key, Konto, KI-Credits.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth:   AuthService
    @EnvironmentObject var claude: ClaudeAPIService

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("Allgemein", systemImage: "gearshape") }
            apiTab
                .tabItem { Label("KI-API", systemImage: "key") }
            accountTab
                .tabItem { Label("Konto", systemImage: "person.crop.circle") }
        }
        .frame(width: 520, height: 360)
    }

    // MARK: - Allgemein
    private var generalTab: some View {
        Form {
            Section("Anzeige") {
                Picker("Sprache", selection: .constant("Deutsch")) {
                    Text("Deutsch").tag("Deutsch")
                    Text("English").tag("English")
                    Text("Français").tag("Français")
                }
                Picker("Rechtsordnung", selection: .constant(auth.currentUser?.jurisdiction.rawValue ?? "DACH")) {
                    Text("Deutschland").tag("DACH")
                    Text("USA").tag("US")
                }
            }
            Section("DSGVO / Datenschutz") {
                Toggle("Anonymisierte KI-Logs senden", isOn: .constant(false))
                Text("Alle Daten verbleiben in deinem iCloud-Konto. Es findet keine Übermittlung an Dritte statt – außer die KI-Calls an Anthropic Claude.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - API-Key
    @State private var apiKeyInput: String = ""
    @State private var showSavedHint = false

    private var apiTab: some View {
        Form {
            Section("Anthropic Claude API") {
                SecureField("API-Key (sk-ant-…)", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Speichern") {
                        claude.setApiKey(apiKeyInput)
                        apiKeyInput = ""
                        showSavedHint = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSavedHint = false }
                    }
                    .disabled(apiKeyInput.isEmpty)
                    if showSavedHint {
                        Label("Gespeichert", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    Link("Key holen", destination: URL(string: "https://console.anthropic.com")!)
                }
                Text("Modell: \(ClaudeAPIService.defaultModel)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let err = claude.lastError {
                Section("Letzter Fehler") {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .padding()
    }

    // MARK: - Konto
    private var accountTab: some View {
        Form {
            if let user = auth.currentUser {
                Section("Angemeldet als") {
                    LabeledContent("Email",         value: user.email)
                    LabeledContent("Rolle",         value: user.role.rawValue)
                    LabeledContent("Rechtsordnung", value: user.jurisdiction.rawValue)
                    LabeledContent("KI-Credits",    value: "\(user.kiCredits)")
                }
                Section {
                    Button("Abmelden", role: .destructive) {
                        auth.logout()
                    }
                }
            } else {
                Text("Nicht angemeldet.")
            }
        }
        .padding()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
        .environmentObject(ClaudeAPIService())
}
