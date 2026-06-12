//
//  FeedbackWidgetView.swift
//  Bewertung von KI-Analysen (positiv/negativ + Kommentar).
//  Pendant zu FeedbackWidget.jsx, speichert in CloudKit als JurisdictionInsight.
//

import SwiftUI

struct FeedbackWidgetView: View {
    @EnvironmentObject var cloudKit: CloudKitService

    let jurisdiction: String
    var topic: String? = nil
    var context: String? = nil
    var language: String = "DE"

    @State private var vote: Vote? = nil
    @State private var comment: String = ""
    @State private var submitted: Bool = false
    @State private var submitting: Bool = false

    enum Vote: String { case up, down }

    private var labels: (title: String, placeholder: String, send: String, thanks: String) {
        switch language {
        case "EN": return ("Was this analysis helpful?",
                           "Optional comment (max. 300 chars)…",
                           "Submit",
                           "Thank you for your feedback!")
        case "FR": return ("Cette analyse était-elle utile?",
                           "Commentaire optionnel (max. 300 caractères)…",
                           "Envoyer",
                           "Merci pour votre retour!")
        default:   return ("War diese Analyse hilfreich?",
                           "Optionaler Kommentar (max. 300 Zeichen)…",
                           "Senden",
                           "Danke für Ihr Feedback!")
        }
    }

    var body: some View {
        if submitted {
            Label(labels.thanks, systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
                .font(.caption.weight(.medium))
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Divider()
                Text(labels.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Button {
                        vote = .up
                    } label: {
                        Label("Ja", systemImage: "hand.thumbsup")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(vote == .up ? .green : .secondary)

                    Button {
                        vote = .down
                    } label: {
                        Label("Nein", systemImage: "hand.thumbsdown")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(vote == .down ? .red : .secondary)
                }

                if vote != nil {
                    HStack {
                        TextField(labels.placeholder, text: $comment)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: comment) { _, newValue in
                                if newValue.count > 300 {
                                    comment = String(newValue.prefix(300))
                                }
                            }
                        Button {
                            Task { await submit() }
                        } label: {
                            Label(labels.send, systemImage: "paperplane.fill")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(submitting)
                    }
                }
            }
        }
    }

    @MainActor
    private func submit() async {
        guard let vote else { return }
        submitting = true
        defer { submitting = false }

        var parts: [String] = ["Vote: \(vote == .up ? "positive" : "negative")"]
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedComment.isEmpty {
            parts.append("Comment: \(String(trimmedComment.prefix(300)))")
        }
        if let ctx = context, !ctx.isEmpty {
            parts.append("Context: \(String(ctx.prefix(500)))")
        }

        var insight = JurisdictionInsight(
            jurisdiction: jurisdiction,
            topic: topic ?? "ai_analysis_feedback",
            insightText: parts.joined(separator: " | ")
        )
        insight.sourceType = "argumentation_pattern"
        insight.usageCount = 1
        insight.effectivenessScore = vote == .up ? 8 : 3
        insight.tags = ["feedback", vote == .up ? "positive" : "negative", jurisdiction]
        _ = try? await cloudKit.save(insight)
        submitted = true
    }
}
