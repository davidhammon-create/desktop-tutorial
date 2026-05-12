//
//  JurisdictionToggle.swift
//  Segmented Picker für die aktive Rechtsordnung (DACH / US / EU / International).
//

import SwiftUI

struct JurisdictionToggle: View {
    @EnvironmentObject var auth: AuthService

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
        }
    }
}
