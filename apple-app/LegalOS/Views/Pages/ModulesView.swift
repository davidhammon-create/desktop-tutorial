//
//  ModulesView.swift
//  Übersicht aller LegalOS-Module – Schalter, Settings, API-Key.
//

import SwiftUI

struct ModulesView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var claude: ClaudeAPIService

    @State private var apiKey: String = ""
    @State private var apiKeyVisible: Bool = false

    var body: some View {
        Form {
            Section("Module") {
                moduleRow(icon: "shield.lefthalf.filled", title: "Strategos", enabled: true)
                moduleRow(icon: "books.vertical", title: "Sun Tzu / Machiavelli", enabled: true)
                moduleRow(icon: "person.badge.shield.checkmark", title: "Richter-Profile", enabled: true)
                moduleRow(icon: "calendar", title: "Zeitleiste", enabled: true)
                moduleRow(icon: "cpu", title: "Plattform-Agent", enabled: true)
            }

            Section("Claude API") {
                if apiKeyVisible {
                    TextField("Anthropic API-Key", text: $apiKey)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                } else {
                    SecureField("Anthropic API-Key", text: $apiKey)
                }
                Toggle("Key sichtbar", isOn: $apiKeyVisible)
                HStack {
                    Button("Speichern") {
                        claude.setApiKey(apiKey)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.isEmpty)
                    Button(role: .destructive) {
                        claude.clearApiKey()
                        apiKey = ""
                    } label: { Text("Löschen") }
                }
                Text("Modell: \(ClaudeAPIService.defaultModel)")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if let u = auth.currentUser {
                Section("Konto") {
                    LabeledContent("E-Mail", value: u.email)
                    LabeledContent("Jurisdiktion", value: u.jurisdiction.rawValue)
                    LabeledContent("KI-Credits", value: "\(u.kiCredits)")
                    Button(role: .destructive) { auth.logout() } label: { Text("Abmelden") }
                }
            }
        }
        .navigationTitle("Module & Einstellungen")
        .onAppear { apiKey = claude.apiKey ?? "" }
    }

    private func moduleRow(icon: String, title: String, enabled: Bool) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(.tint)
            Text(title)
            Spacer()
            Image(systemName: enabled ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(enabled ? .green : .secondary)
        }
    }
}
