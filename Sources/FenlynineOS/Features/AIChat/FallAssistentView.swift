import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit
struct ChatNachricht: Identifiable, Equatable {
    var id: UUID = UUID()
    var rolle: ChatRolle
    var inhalt: String
    var zeitstempel: Date = Date()
    var isStreaming: Bool = false
    var transparenz: String? = nil
    var caseContext: String? = nil
    var cloudKonversationId: String? = nil
    enum ChatRolle {
        case benutzer
        case ki
        case system
    }
    var istBenutzer: Bool { rolle == .benutzer }
}
struct AgentChatKonfiguration {
    let agentName: String
    let navigationTitle: String
    let headerTitle: String
    let eingabePlaceholder: String
    let begruessung: String
    let schnellAnfragen: [(label: String, prompt: String)]
    let zeigeFallPicker: Bool
    static let fallAssistent = AgentChatKonfiguration(
        agentName: "fall_assistent",
        navigationTitle: "KI-Assistent — \(AppDefaults.produktKurz)",
        headerTitle: "\(AppDefaults.produktName) KI-Assistent",
        eingabePlaceholder: "Frage an den KI-Assistenten…",
        begruessung: """
        Willkommen beim **FenlynineOS Legal Suite**-KI-Assistenten by Håmmon & Partner.
        Ich bin Ihr juristischer KI-Berater mit Zugriff auf alle Falldaten. Sie können mich zu:
        • Fallanalysen und Erfolgsprognosen befragen
        • Strategie-Optionen und Szenarien entwickeln lassen
        • Fristen, Argumente und Beweise verwalten
        • Rechtsfragen mit §§ und BGH-Urteilen klären
        **Berufspflicht:** KI-Antworten sind Vorarbeit. Fundstellen und Normen müssen geprüft werden (Berufspflicht-Desk → KI-Prüfung). Halluzinierte Zitate sind haftungsrelevant.
        **Transparenz:** Bei jeder Antwort erkläre ich explizit, wie ich zu meiner Einschätzung gelange.
        Wählen Sie einen Fall für kontextsensitive Beratung oder stellen Sie eine allgemeine Frage.
        """,
        schnellAnfragen: [
            ("Fallprognose erklären", "Erkläre mir die Methodik hinter der Erfolgsprognose für meinen aktuellen Fall."),
            ("Richter analysieren", "Analysiere das Entscheidungsverhalten des zuständigen Richters und gib Empfehlungen für die Verhandlungsführung."),
            ("Vergleichsempfehlung", "Soll ich einen Vergleich anstreben? Analysiere die Kosten-Nutzen-Situation."),
            ("Beweismittel bewerten", "Bewerte die Qualität meiner Beweismittel und zeige Schwachstellen auf."),
            ("Strategie verfeinern", "Entwickle drei alternative Prozessstrategien mit Vor- und Nachteilen."),
            ("Fundstellen prüfen", "Liste alle von dir genannten Urteile/Normen auf und markiere, welche ich zwingend in beck-online/juris gegenprüfen muss."),
            ("Rechtsprechung", "Recherchiere relevante aktuelle Urteile für diesen Fall.")
        ],
        zeigeFallPicker: true
    )
    static let plattformOptimierer = AgentChatKonfiguration(
        agentName: "plattform_optimierer",
        navigationTitle: "Plattform-Agent",
        headerTitle: "Plattform-Optimierer",
        eingabePlaceholder: "Frage zum FenlynineOS-Workflow…",
        begruessung: """
        Willkommen beim **Plattform-Optimierer**.
        Ich helfe bei der effizienten Nutzung von FenlynineOS:
        • Workflow-Optimierung und Best Practices
        • Modul-Navigation (Lexara, Strategos, Richterprofile)
        • KI-Funktionen und Transparenzpflichten
        • Produktivitäts-Tipps für Kanzlei-Teams
        Stellen Sie eine Frage zur Plattform oder beschreiben Sie Ihren Workflow.
        """,
        schnellAnfragen: [
            ("Lexara-Workflow", "Erkläre den optimalen Lexara-Workflow von Fallanlage bis Abschluss."),
            ("Strategos nutzen", "Wie nutze ich Strategos Enterprise für eine Unternehmensberatung?"),
            ("KI-Transparenz", "Welche KI-Funktionen protokollieren ihre Berechnungen und wo finde ich das Protokoll?"),
            ("Richterprofile", "Wie nutze ich Richterprofile und das Netzwerk für die Strategieplanung?"),
            ("Prognose verstehen", "Erkläre Monte-Carlo-Prognose und Bayesian-Kalibrierung in FenlynineOS.")
        ],
        zeigeFallPicker: false
    )
}
@Observable
final class FallAssistentViewModel {
    let config: AgentChatKonfiguration
    var nachrichten: [ChatNachricht] = []
    var eingabe: String = ""
    var isLoading = false
    var selectedCaseId: String? = nil
    var faelle: [LegalCase] = []
    var activeStreamId: UUID? = nil
    var konversationen: [AgentConversation] = []
    var aktiveKonversation: AgentConversation? = nil
    private var letzteNachrichtenAnzahl: Int = 0
    var cloudKonversationId: String? = nil
    init(config: AgentChatKonfiguration = .fallAssistent) {
        self.config = config
    }
    @MainActor
    func initialisieren() async {
        nachrichten = [
            ChatNachricht(rolle: .ki, inhalt: config.begruessung)
        ]
        await ChatCloudStore.shared.syncICloud()
        async let convs = AgentService.shared.listConversations(agentName: config.agentName)
        if config.zeigeFallPicker {
            async let f = Services.cases.list()
            faelle = (try? await f) ?? []
        }
        konversationen = (try? await convs) ?? []
        if konversationen.isEmpty,
           let lokal = ChatCloudStore.shared.konversationen(fuer: config.agentName).first,
           !lokal.nachrichten.isEmpty {
            cloudKonversationId = lokal.id
            nachrichten = lokal.nachrichten.map { ChatNachricht.ausCloud($0) }
        }
    }
    @MainActor
    private func persistiereCloud() {
        let cloudMsgs = nachrichten
            .filter { !$0.isStreaming && !$0.inhalt.isEmpty }
            .map { $0.alsCloud() }
        guard !cloudMsgs.isEmpty else { return }
        if let cid = cloudKonversationId {
            ChatCloudStore.shared.speichereNachrichten(
                konversationId: cid,
                nachrichten: cloudMsgs,
                remoteId: aktiveKonversation?.id
            )
        } else {
            let roh = cloudMsgs.first(where: { $0.rolle == "user" })?.inhalt
            let titel: String = {
                guard let roh else { return "Gespräch \(Date().formatted(.dateTime.day().month()))" }
                return roh.count > 40 ? String(roh.prefix(40)) + "…" : roh
            }()
            let neu = ChatCloudStore.shared.neu(
                agentName: config.agentName,
                titel: titel,
                caseId: selectedCaseId,
                remoteId: aktiveKonversation?.id
            )
            cloudKonversationId = neu.id
            ChatCloudStore.shared.speichereNachrichten(
                konversationId: neu.id,
                nachrichten: cloudMsgs,
                remoteId: aktiveKonversation?.id
            )
        }
    }
    @MainActor
    func konversationOeffnen(_ conv: AgentConversation) async {
        do {
            let voll = try await AgentService.shared.getConversation(conv.id)
            aktiveKonversation = voll
            letzteNachrichtenAnzahl = voll.messages?.count ?? 0
            nachrichten = (voll.messages ?? []).compactMap { msg -> ChatNachricht? in
                guard let content = msg.content, !content.isEmpty else { return nil }
                let rolle: ChatNachricht.ChatRolle = msg.role == "user" ? .benutzer : .ki
                return ChatNachricht(rolle: rolle, inhalt: content)
            }
        } catch {
            AppState.shared.showError("Fehler beim Laden: \(error.localizedDescription)")
        }
    }
    @MainActor
    func neueKonversation() async {
        do {
            let conv = try await AgentService.shared.createConversation(
                agentName: config.agentName,
                metadata: ["name": "Gespräch \(Date().formatted(.dateTime.day().month().year()))"]
            )
            aktiveKonversation = conv
            letzteNachrichtenAnzahl = 0
            nachrichten = []
            konversationen = [conv] + konversationen
        } catch {
            AppState.shared.showError("Fehler: \(error.localizedDescription)")
        }
    }
    @MainActor
    func nachrichtSenden() async {
        let text = eingabe.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        eingabe = ""
        isLoading = true
        nachrichten.append(ChatNachricht(rolle: .benutzer, inhalt: text))
        let streamId = UUID()
        nachrichten.append(ChatNachricht(rolle: .ki, inhalt: "", isStreaming: true))
        activeStreamId = streamId
        do {
            if aktiveKonversation == nil {
                var metaName = text
                if metaName.count > 40 { metaName = String(metaName.prefix(40)) + "…" }
                let conv = try await AgentService.shared.createConversation(
                    agentName: config.agentName,
                    metadata: ["name": metaName]
                )
                aktiveKonversation = conv
                letzteNachrichtenAnzahl = 0
                konversationen = [conv] + konversationen
            }
            guard let konvId = aktiveKonversation?.id else { throw Base44Error.invalidResponse }
            var vollText = text
            if let caseId = selectedCaseId, let fall = faelle.first(where: { $0.id == caseId }) {
                vollText = """
                [FALLKONTEXT: \(fall.fallname) | \(fall.rechtsgebiet ?? "") | \(fall.status.rawValue) | \
                Prognose: \(fall.prognose.map { "\(Int($0))%" } ?? "n/a")]
                \(text)
                """
            }
            let vorAnzahl = letzteNachrichtenAnzahl
            _ = try await AgentService.shared.addMessage(conversationId: konvId, role: "user", content: vollText)
            letzteNachrichtenAnzahl = vorAnzahl + 1
            let antwort = try await AgentService.shared.waitForAssistantReply(
                conversationId: konvId,
                afterMessageCount: letzteNachrichtenAnzahl
            )
            let antwortText = antwort?.content ?? "⚠️ Keine Antwort erhalten."
            letzteNachrichtenAnzahl += 1  // assistant message
            if let idx = nachrichten.firstIndex(where: { $0.isStreaming }) {
                nachrichten[idx].inhalt = antwortText
                nachrichten[idx].isStreaming = false
                nachrichten[idx].transparenz = "Agent: \(config.agentName) | \(KIKonfiguration.shared.modus.bezeichnung)"
            }
            persistiereCloud()
        } catch {
            if let idx = nachrichten.firstIndex(where: { $0.isStreaming }) {
                nachrichten[idx].inhalt = "⚠️ Fehler: \(error.localizedDescription)"
                nachrichten[idx].isStreaming = false
            }
            persistiereCloud()
        }
        isLoading = false
        activeStreamId = nil
    }
    var schnellAnfragen: [(label: String, prompt: String)] { config.schnellAnfragen }
}
struct AgentChatShellView: View {
    var viewModel: FallAssistentViewModel
    var body: some View {
        HSplitView {
            KonversationsSidebar(viewModel: viewModel)
                .frame(minWidth: 200, idealWidth: 220, maxWidth: 260)
            VStack(spacing: 0) {
                ChatHeaderView(viewModel: viewModel)
                Divider()
                if viewModel.nachrichten.isEmpty || viewModel.nachrichten.count <= 1 {
                    SchnellAnfragenView(viewModel: viewModel)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                }
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.nachrichten) { nachricht in
                                ChatNachrichtBubble(nachricht: nachricht)
                                    .id(nachricht.id)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: viewModel.nachrichten.count) {
                        if let last = viewModel.nachrichten.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
                Divider()
                ChatEingabeView(viewModel: viewModel)
            }
        }
        .fenlynineOSAdaptiveNavigationTitle(viewModel.config.navigationTitle)
    }
}
struct FallAssistentView: View {
    @State private var viewModel = FallAssistentViewModel()
    var body: some View {
        AgentChatShellView(viewModel: viewModel)
            .task { await viewModel.initialisieren() }
    }
}
struct PlattformAgentView: View {
    @State private var viewModel = FallAssistentViewModel(config: .plattformOptimierer)
    var body: some View {
        AgentChatShellView(viewModel: viewModel)
            .task { await viewModel.initialisieren() }
    }
}
struct KonversationsSidebar: View {
    let viewModel: FallAssistentViewModel
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Gespräche")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Premium.textSoft)
                Spacer()
                Button {
                    Task { await viewModel.neueKonversation() }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .help("Neues Gespräch")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            Divider()
            if viewModel.konversationen.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "message.badge.circle")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("Noch keine Gespräche")
                        .font(.caption)
                        .foregroundStyle(Premium.textSoft)
                    Button("Neues Gespräch") {
                        Task { await viewModel.neueKonversation() }
                    }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.konversationen, selection: .constant(viewModel.aktiveKonversation?.id)) { conv in
                    Button {
                        Task { await viewModel.konversationOeffnen(conv) }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(conv.metadata?["name"]?.stringValue ?? "Gespräch")
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                            if let datum = conv.updated_date {
                                Text(datum.formatted(.relative(presentation: .named)))
                                    .font(.caption2)
                                    .foregroundStyle(Premium.textSoft)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                    .background(
                        viewModel.aktiveKonversation?.id == conv.id
                            ? Color.accentColor.opacity(0.1)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                }
                .listStyle(.plain)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}
struct ChatHeaderView: View {
    let viewModel: FallAssistentViewModel
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.fill")
                .font(.system(size: 18))
                .foregroundStyle(.purple)
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.config.headerTitle)
                    .font(.system(size: 13, weight: .semibold))
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text(KIKonfiguration.shared.modus.bezeichnung)
                        .font(.caption2)
                        .foregroundStyle(Premium.textSoft)
                }
            }
            Spacer()
            if viewModel.config.zeigeFallPicker && !viewModel.faelle.isEmpty {
                Picker("Fall auswählen", selection: Binding(
                    get: { viewModel.selectedCaseId ?? "" },
                    set: { viewModel.selectedCaseId = $0.isEmpty ? nil : $0 }
                )) {
                    Text("Kein Fall ausgewählt").tag("")
                    ForEach(viewModel.faelle) { fall in
                        Text(fall.fallname).tag(fall.id ?? "")
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 200)
            }
            Button {
                viewModel.nachrichten = [viewModel.nachrichten[0]]
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Premium.textSoft)
            }
            .help("Chat zurücksetzen")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
struct SchnellAnfragenView: View {
    let viewModel: FallAssistentViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Schnellzugriff")
                .font(.caption)
                .foregroundStyle(Premium.textSoft)
            FlowLayout(spacing: 8) {
                ForEach(viewModel.schnellAnfragen, id: \.label) { anfrage in
                    Button(anfrage.label) {
                        viewModel.eingabe = anfrage.prompt
                        Task { await viewModel.nachrichtSenden() }
                    }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                    .font(.system(size: 12))
                }
            }
        }
    }
}
struct ChatNachrichtBubble: View {
    let nachricht: ChatNachricht
    @State private var zeigeTransparenz = false
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if nachricht.istBenutzer { Spacer(minLength: 80) }
            if !nachricht.istBenutzer {
                Image(systemName: "brain.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(.purple, in: Circle())
            }
            VStack(alignment: nachricht.istBenutzer ? .trailing : .leading, spacing: 4) {
                Text(nachricht.isStreaming ? "…" : nachricht.inhalt)
                    .font(.system(size: 13))
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        nachricht.istBenutzer ? Color.blue :
                        (nachricht.rolle == .system ? Color.orange.opacity(0.1) : Color(nsColor: .controlBackgroundColor)),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .foregroundStyle(nachricht.istBenutzer ? .white : .primary)
                    .overlay(
                        nachricht.isStreaming ?
                        AnyView(ProgressView().scaleEffect(0.5)) :
                        AnyView(EmptyView()),
                        alignment: .center
                    )
                if let transparenz = nachricht.transparenz, !nachricht.istBenutzer {
                    Button {
                        withAnimation { zeigeTransparenz.toggle() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 9))
                            Text("KI-Transparenz")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(Premium.textSoft)
                    }
                    .buttonStyle(.plain)
                    if zeigeTransparenz {
                        Text(transparenz)
                            .font(.system(size: 10))
                            .foregroundStyle(Premium.textSoft)
                            .padding(6)
                            .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                Text(nachricht.zeitstempel.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            if nachricht.istBenutzer {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue.opacity(0.6))
            } else {
                Spacer(minLength: 80)
            }
        }
    }
}
struct ChatEingabeView: View {
    let viewModel: FallAssistentViewModel
    @FocusState private var isFocused: Bool
    @State private var dateiwahl = false
    @State private var anhangFehler: String?
    @Environment(\.fenlynineOSVisionOSChrome) private var chrome
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Button { dateiwahl = true } label: {
                Image(systemName: "paperclip")
                    .font(.system(size: 16))
                    .foregroundStyle(FenlynineOSTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Dokument anhängen (PDF, Text, RTF) -- der Text wird lokal gelesen und der Frage beigefügt")
            .fileImporter(isPresented: $dateiwahl,
                          allowedContentTypes: [.pdf, .plainText, .rtf, .utf8PlainText]) { ergebnis in
                switch ergebnis {
                case let .success(url):
                    do { viewModel.eingabe = try ChatAnhang.anfuegen(url, an: viewModel.eingabe) }
                    catch { anhangFehler = error.localizedDescription }
                case let .failure(fehler):
                    anhangFehler = fehler.localizedDescription
                }
            }
            .alert("Anhang nicht lesbar", isPresented: Binding(
                get: { anhangFehler != nil }, set: { if !$0 { anhangFehler = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(anhangFehler ?? "") }
            TextField(viewModel.config.eingabePlaceholder, text: Binding(
                get: { viewModel.eingabe },
                set: { viewModel.eingabe = $0 }
            ), axis: .vertical)
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .lineLimit(1...6)
            .focused($isFocused)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                if chrome {
                    Capsule().fill(.ultraThinMaterial).overlay(Capsule().stroke(.white.opacity(0.14), lineWidth: 0.5))
                } else {
                    RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .textBackgroundColor))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                }
            }
            .onSubmit {
                if NSApp.currentEvent?.modifierFlags.contains(.shift) != true {
                    Task { await viewModel.nachrichtSenden() }
                } else {
                    viewModel.eingabe += "\n"
                }
            }
            Button {
                Task { await viewModel.nachrichtSenden() }
            } label: {
                Image(systemName: viewModel.isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: chrome ? 32 : 28))
                    .foregroundStyle(viewModel.eingabe.isEmpty ? FenlynineOSTheme.textTertiary : FenlynineOSTheme.accent)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.eingabe.isEmpty && !viewModel.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            if chrome {
                Rectangle().fill(.ultraThinMaterial).overlay(Rectangle().fill(Color.white.opacity(0.03)))
            } else {
                Color(nsColor: .windowBackgroundColor)
            }
        }
    }
}
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = min(proposal.width ?? 10_000, 10_000)
        var height: CGFloat = 0
        var row: CGFloat = 0
        var x: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                height += row + spacing
                row = 0
                x = 0
            }
            x += size.width + spacing
            row = max(row, size.height)
        }
        height += row
        return CGSize(width: maxWidth, height: height)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Anhang im Chat

/// Liest ein Dokument auf dem Gerät und fügt seinen Text der Frage bei. Es wird
/// nichts hochgeladen; geht die Frage an eine Cloud-KI, durchläuft der Text
/// dieselbe Pseudonymisierung wie jede andere Eingabe.
enum ChatAnhang {
    /// Obergrenze, damit ein langes Dokument das Kontextfenster nicht sprengt.
    static let hoechstzeichen = 24_000

    struct Fehler: LocalizedError {
        let errorDescription: String?
    }

    static func anfuegen(_ url: URL, an eingabe: String) throws -> String {
        let zugriff = url.startAccessingSecurityScopedResource()
        defer { if zugriff { url.stopAccessingSecurityScopedResource() } }
        let text: String
        switch url.pathExtension.lowercased() {
        case "pdf":
            guard let dok = PDFDocument(url: url), let t = dok.string,
                  !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw Fehler(errorDescription: "Die PDF enthält keinen auslesbaren Text (vermutlich ein Scan ohne Texterkennung).")
            }
            text = t
        case "rtf":
            let attr = try NSAttributedString(url: url, options: [.documentType: NSAttributedString.DocumentType.rtf],
                                              documentAttributes: nil)
            text = attr.string
        default:
            text = try String(contentsOf: url, encoding: .utf8)
        }
        let gekuerzt = text.count > hoechstzeichen
        let auszug = gekuerzt ? String(text.prefix(hoechstzeichen)) : text
        let kopf = "[Anhang: \(url.lastPathComponent)\(gekuerzt ? " · gekürzt auf \(hoechstzeichen) Zeichen" : "")]"
        let bisher = eingabe.trimmingCharacters(in: .whitespacesAndNewlines)
        return (bisher.isEmpty ? "" : bisher + "\n\n") + kopf + "\n" + auszug
    }
}
