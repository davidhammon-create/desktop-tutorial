import SwiftUI
/// Holt das Hauptfenster nach vorn -- oder öffnet es neu, wenn es geschlossen wurde.
enum Hauptfenster {
    @MainActor
    static func zeigen(_ openWindow: OpenWindowAction) {
        NSApp.activate(ignoringOtherApps: true)
        if let w = NSApp.windows.first(where: { FenlynineOSFensterKennung.istHauptfenster($0) && $0.isVisible }) {
            w.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: FenlynineOSFensterKennung.hauptGruppe)
        }
    }
}
struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var authManager: AuthManager
    @State private var fristen: [Deadline] = []
    @State private var isLoading = true
    var kritischeFristen: [Deadline] {
        fristen.filter { $0.istKritisch && !$0.istVersaeumt }.sorted { $0.due_date < $1.due_date }
    }
    var versaeumteFristen: [Deadline] {
        fristen.filter { $0.istVersaeumt }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "scale.3d")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.blue)
                Text(AppDefaults.produktNameVoll)
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                if isLoading {
                    ProgressView().scaleEffect(0.6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if !versaeumteFristen.isEmpty {
                        MenuBarSektion(titel: "⚠️ Versäumt (\(versaeumteFristen.count))", farbe: .red) {
                            ForEach(versaeumteFristen.prefix(3)) { frist in
                                MenuBarFristZeile(frist: frist, istVersaeumt: true)
                            }
                        }
                    }
                    if !kritischeFristen.isEmpty {
                        MenuBarSektion(titel: "Bald fällig (\(kritischeFristen.count))", farbe: .orange) {
                            ForEach(kritischeFristen.prefix(5)) { frist in
                                MenuBarFristZeile(frist: frist, istVersaeumt: false)
                            }
                        }
                    }
                    if kritischeFristen.isEmpty && versaeumteFristen.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Keine kritischen Fristen")
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                }
            }
            .frame(maxHeight: 300)
            Divider()
            HStack(spacing: 0) {
                MenuBarButton(titel: "Öffnen", symbol: "arrow.up.left.and.arrow.down.right") {
                    Hauptfenster.zeigen(openWindow)
                }
                MenuBarButton(titel: "Aktualisieren", symbol: "arrow.clockwise") {
                    Task { await laden() }
                }
                MenuBarButton(titel: "Beenden", symbol: "xmark.circle") {
                    NSApp.terminate(nil)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: 300)
        .task { await laden() }
    }
    private func laden() async {
        isLoading = true
        fristen = (try? await Services.deadlines.list()) ?? []
        isLoading = false
        let kritisch = fristen.filter { $0.istKritisch }.count
        NotificationService.shared.badgeAktualisieren(kritischeFristen: kritisch)
    }
}
struct MenuBarSektion<Content: View>: View {
    let titel: String
    let farbe: Color
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titel)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(farbe)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 2)
            content
        }
    }
}
struct MenuBarFristZeile: View {
    let frist: Deadline
    @Environment(\.openWindow) private var openWindow
    let istVersaeumt: Bool
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(istVersaeumt ? Color.red : Color.orange)
                .frame(width: 6, height: 6)
            Text(frist.title)
                .font(.system(size: 11))
                .lineLimit(1)
            Spacer()
            Text(istVersaeumt ? "Versäumt" : "\(frist.tageVerbleibend)d")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(istVersaeumt ? .red : .orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onTapGesture {
            Hauptfenster.zeigen(openWindow)
            NotificationCenter.default.post(name: .navigateToCase, object: frist.case_id)
        }
    }
}
struct MenuBarButton: View {
    let titel: String
    let symbol: String
    let aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 12))
                Text(titel)
                    .font(.system(size: 9))
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
