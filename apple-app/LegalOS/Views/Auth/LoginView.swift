//
//  LoginView.swift
//  Login per Email/Passwort und Sign in with Apple.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var auth: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "scale.3d")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(.tint)
                Text("LegalOS")
                    .font(.largeTitle.weight(.semibold))
                Text("Die Legal-OS für Strategie, Akten und KI.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    TextField("E-Mail", text: $email)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled()
                    SecureField("Passwort", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 32)

                if let err = auth.lastError {
                    Text(err).font(.footnote).foregroundStyle(.red)
                }

                Button {
                    Task { await auth.login(email: email, password: password) }
                } label: {
                    Text(auth.isBusy ? "Einloggen…" : "Anmelden")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || password.isEmpty || auth.isBusy)
                .padding(.horizontal, 32)

                SignInWithAppleButton(.signIn,
                    onRequest: { req in req.requestedScopes = [.fullName, .email] },
                    onCompletion: { result in
                        Task { await auth.handleAppleSignIn(result) }
                    })
                .signInWithAppleButtonStyle(.black)
                .frame(height: 44)
                .padding(.horizontal, 32)

                Button("Noch keinen Account? Registrieren") { showRegister = true }
                    .font(.footnote)

                Spacer()
            }
            .padding()
            .sheet(isPresented: $showRegister) { RegisterView() }
        }
    }
}

#Preview {
    LoginView().environmentObject(AuthService())
}
