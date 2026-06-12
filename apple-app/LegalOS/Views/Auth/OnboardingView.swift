//
//  OnboardingView.swift
//  Erst-Setup: Jurisdiktion + NDA / Disclaimer.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var auth: AuthService

    @State private var jurisdiction: Jurisdiction = .dach
    @State private var ndaAccepted = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Rechtsordnung") {
                    Picker("Hauptjurisdiktion", selection: $jurisdiction) {
                        ForEach(Jurisdiction.allCases, id: \.self) { j in
                            Text(j.rawValue).tag(j)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Du kannst die Rechtsordnung später jederzeit umschalten.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Vertraulichkeit & Disclaimer") {
                    Text("""
                    LegalOS speichert sämtliche Falldaten ausschließlich in deiner iCloud (CloudKit). \
                    Es findet keine Übertragung an Dritte statt, mit Ausnahme von ausdrücklich \
                    angeforderten KI-Anfragen an Anthropic. KI-Antworten ersetzen keine Rechtsberatung.
                    """)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    Toggle("Ich habe die NDA / den Disclaimer gelesen und akzeptiere ihn.",
                           isOn: $ndaAccepted)
                }

                Section {
                    Button {
                        Task {
                            await auth.completeOnboarding(jurisdiction: jurisdiction,
                                                          disclaimerAccepted: ndaAccepted)
                        }
                    } label: {
                        Text("Setup abschließen").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!ndaAccepted || auth.isBusy)
                }
            }
            .navigationTitle("Willkommen bei LegalOS")
        }
    }
}

#Preview {
    OnboardingView().environmentObject(AuthService())
}
