//
//  UserNotRegisteredErrorView.swift
//  Anzeige für nicht registrierte Nutzer. Pendant zu UserNotRegisteredError.jsx.
//

import SwiftUI

struct UserNotRegisteredErrorView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.orange)
                .padding(20)
                .background(Color.orange.opacity(0.15), in: Circle())

            Text("Access Restricted")
                .font(.largeTitle.bold())

            Text("You are not registered to use this application. Please contact the app administrator to request access.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 400)

            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Text("If you believe this is an error, you can:")
                        .font(.subheadline.weight(.medium))
                    Label("Verify you are logged in with the correct account", systemImage: "checkmark.circle")
                    Label("Contact the app administrator for access", systemImage: "envelope")
                    Label("Try logging out and back in again", systemImage: "arrow.triangle.2.circlepath")
                }
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: 420)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}
