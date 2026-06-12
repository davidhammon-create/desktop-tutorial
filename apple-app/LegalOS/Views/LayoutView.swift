//
//  LayoutView.swift
//  Generischer Layout-Container (entspricht Layout.jsx mit <Outlet/>).
//  Stellt nur das Hintergrund-Design bereit – Navigation läuft über AppShell.
//

import SwiftUI

struct LayoutView<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            content()
        }
    }
}
