//
//  FallAssistentChatView.swift
//  Chat-Interface zum KI-Fall-Assistenten – entspricht src/pages/FallAssistentChat.jsx.
//

import SwiftUI

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let role: Role
    var text: String
    let timestamp: Date = Date()
    enum Role: String { case user, assistant }
}

struct FallAssistentChatView: View {
    @EnvironmentObject var kiProvider: KIProvider
    @EnvironmentObject var cloudKit: CloudKitService

    @State private var messages: [ChatMessage] = []
    @State private var input: String = ""
    @State private var streaming: Bool = false
    @State private var cases: [Case] = []
    @State private var selectedCaseId: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            casePicker
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        if messages.isEmpty {
                            placeholder
                        } else {
                            ForEach(messages) { m in bubble(m) }
                        }
                    }
                    .padding()
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            inputBar
        }
        .navigationTitle("Fall-Assistent")
        .task { cases = (try? await cloudKit.fetch(Case.self)) ?? [] }
    }

    private var casePicker: some View {
        HStack {
            Text("Fall:").font(.caption).foregroundStyle(.secondary)
            Picker("Fall", selection: $selectedCaseId) {
                Text("(kein Bezug)").tag(String?.none)
                ForEach(cases) { c in
                    Text(c.fallname).tag(Optional(c.id))
                }
            }
            .labelsHidden()
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    private var placeholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Stelle eine Frage zu deinem Fall oder allgemein zum Recht.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    private func bubble(_ m: ChatMessage) -> some View {
        HStack {
            if m.role == .assistant {
                Text(m.text)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                Spacer()
            } else {
                Spacer()
                Text(m.text)
                    .padding()
                    .background(Color.accentColor.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .id(m.id)
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Frage formulieren…", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
            Button {
                Task { await send() }
            } label: {
                Image(systemName: "paperplane.fill")
            }
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || streaming)
        }
        .padding(8)
    }

    @MainActor
    private func send() async {
        let userMsg = ChatMessage(role: .user, text: input)
        messages.append(userMsg)
        let prompt = input
        input = ""
        streaming = true
        defer { streaming = false }
        let res = await kiProvider.invokeLLM(prompt: prompt,
                                             context: "FallAssistentChat",
                                             caseId: selectedCaseId)
        switch res {
        case .success(let v):
            let text = (v as? String) ?? "(keine Antwort)"
            messages.append(ChatMessage(role: .assistant, text: text))
        case .failure(let err):
            messages.append(ChatMessage(role: .assistant, text: "Fehler: \(err.localizedDescription)"))
        }
    }
}
