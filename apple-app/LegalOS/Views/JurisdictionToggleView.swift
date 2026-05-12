//
//  JurisdictionToggleView.swift
//  Erweitertes Pendant zu JurisdictionToggle.jsx mit DACH/US/EU/International.
//  Überschreibt die einfachere Variante aus Components/JurisdictionToggle.swift.
//

import SwiftUI

struct JurisdictionToggleView: View {
    @EnvironmentObject var auth: AuthService
    var dark: Bool = false

    var body: some View {
        if let user = auth.currentUser {
            Picker("Rechtsordnung", selection: Binding<Jurisdiction>(
                get: { user.jurisdiction },
                set: { newValue in
                    var u = user
                    u.jurisdiction = newValue
                    Task { await auth.updateProfile(u) }
                }
            )) {
                ForEach(Jurisdiction.allCases, id: \.self) { j in
                    Text(j.rawValue).tag(j)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 360)
            .opacity(dark ? 0.9 : 1)
        }
    }
}
