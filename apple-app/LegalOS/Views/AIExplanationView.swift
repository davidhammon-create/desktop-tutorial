//
//  AIExplanationView.swift
//  Klappbares Erklärungs-Panel für KI-Ergebnisse. Pendant zu AIExplanation.jsx.
//

import SwiftUI

struct AIExplanationView<Content: View>: View {
    let title: String
    let explanation: String
    var formula: String? = nil
    var inline: Bool = false
    @ViewBuilder var content: () -> Content

    @State private var open = false

    init(title: String,
         explanation: String,
         formula: String? = nil,
         inline: Bool = false,
         @ViewBuilder content: @escaping () -> Content = { EmptyView() }) {
        self.title = title
        self.explanation = explanation
        self.formula = formula
        self.inline = inline
        self.content = content
    }

    var body: some View {
        if inline {
            HStack(alignment: .top, spacing: 8) {
                content()
                Button {
                    open.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(title)
                .popover(isPresented: $open) {
                    detailsBody
                        .padding(12)
                        .frame(width: 280)
                }
            }
        } else {
            DisclosureGroup(isExpanded: $open) {
                detailsBody
                    .padding(.top, 6)
            } label: {
                Label(title, systemImage: "info.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(12)
            .background(Color.accentColor.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder
    private var detailsBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let formula {
                Text(formula)
                    .font(.system(.caption2, design: .monospaced))
                    .padding(8)
                    .background(.thinMaterial,
                                in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}
