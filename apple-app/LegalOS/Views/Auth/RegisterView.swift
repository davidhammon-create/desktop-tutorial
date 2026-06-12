//
//  RegisterView.swift
//  Registrierung neuer Nutzer.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var fullName = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var agbAccepted = false

    private var canSubmit: Bool {
        !email.isEmpty &&
        password.count >= 8 &&
        password == passwordConfirm &&
        agbAccepted &&
        !auth.isBusy
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Konto") {
                    TextField("Vor- und Nachname", text: $fullName)
                    TextField("E-Mail", text: $email)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled()
                    SecureField("Passwort (min. 8 Zeichen)", text: $password)
                    SecureField("Passwort bestätigen", text: $passwordConfirm)
                    if !password.isEmpty && password != passwordConfirm {
                        Text("Passwörter stimmen nicht überein.")
                            .font(.footnote).foregroundStyle(.red)
                    }
                }

                Section {
                    Toggle("Ich akzeptiere AGB & Datenschutzerklärung.", isOn: $agbAccepted)
                }

                if let err = auth.lastError {
                    Section { Text(err).foregroundStyle(.red) }
                }

                Section {
                    Button {
                        Task {
                            await auth.register(email: email,
                                                password: password,
                                                fullName: fullName.isEmpty ? nil : fullName)
                            if auth.currentUser != nil { dismiss() }
                        }
                    } label: {
                        Text(auth.isBusy ? "Wird angelegt…" : "Konto erstellen")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!canSubmit)
                }
            }
            .navigationTitle("Registrieren")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    RegisterView().environmentObject(AuthService())
}
