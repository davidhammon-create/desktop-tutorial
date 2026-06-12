//
//  KICreditsBadge.swift
//  Kleines Badge, das den verbleibenden KI-Credit-Stand zeigt.
//

import SwiftUI

struct KICreditsBadge: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        if let credits = auth.currentUser?.kiCredits {
            HStack(spacing: 4) {
                Image(systemName: "sparkles").font(.caption2)
                Text("\(credits) KI-Credits").font(.caption2.weight(.medium))
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color.purple.opacity(0.15), in: Capsule())
            .foregroundStyle(.purple)
        }
    }
}
