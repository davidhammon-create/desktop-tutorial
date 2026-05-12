//
//  DSGVOBanner.swift
//  Hinweisbanner zur Datenverarbeitung (DSGVO-konform).
//

import SwiftUI

struct DSGVOBanner: View {
    @AppStorage("dsgvo.banner.dismissed") private var dismissed = false

    var body: some View {
        if dismissed {
            EmptyView()
        } else {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.shield")
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Datenverarbeitung gem. DSGVO").font(.subheadline.weight(.semibold))
                    Text("Falldaten werden ausschließlich in deiner iCloud (CloudKit) gespeichert. KI-Anfragen werden TLS-verschlüsselt an Anthropic übermittelt – ohne Trainingsnutzung.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Verstanden") { dismissed = true }
                    .font(.caption.weight(.semibold))
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding()
        }
    }
}

#Preview { DSGVOBanner() }
