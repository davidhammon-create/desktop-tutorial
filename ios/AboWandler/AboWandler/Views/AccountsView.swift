import SwiftUI
import UniformTypeIdentifiers

struct AccountsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showCatalog = false
    @State private var importAccount: Account?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.accounts) { account in
                        let prov = Provider.byId(account.providerId)
                        HStack(spacing: 12) {
                            ProviderBadge(provider: prov)
                            VStack(alignment: .leading) {
                                Text(account.label).font(.body.weight(.semibold))
                                Text(account.iban ?? prov.type).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Import") { importAccount = account }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                        .swipeActions {
                            Button("Trennen", role: .destructive) { store.removeAccount(account) }
                        }
                    }
                    Button {
                        showCatalog = true
                    } label: {
                        Label("Konto verbinden (Sparkasse, PayPal, Klarna, Amex …)", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Verbundene Konten")
                } footer: {
                    Text("Umsätze kommen per CSV-Export deiner Bank — Banking-Passwörter werden niemals abgefragt oder gespeichert.")
                }

                Section("Umsätze (\(store.transactions.count))") {
                    ForEach(store.transactions.sorted(by: { $0.date > $1.date }).prefix(60)) { txn in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(txn.name).font(.subheadline.weight(.medium))
                                Text(txn.subject).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(txn.amount.euro)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(txn.amount < 0 ? Color.primary : .green)
                                Text(txn.date, style: .date).font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Konten & Umsätze")
            .sheet(isPresented: $showCatalog) { ProviderCatalogSheet() }
            .sheet(item: $importAccount) { account in ImportSheet(account: account) }
        }
    }
}

struct ProviderBadge: View {
    let provider: Provider
    var size: CGFloat = 36

    var body: some View {
        Text(provider.letter)
            .font(.system(size: size * 0.45, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color(hex: provider.colorHex), in: RoundedRectangle(cornerRadius: size * 0.3))
    }
}

struct ProviderCatalogSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(["Bank", "Wallet", "Karte", "Broker"], id: \.self) { type in
                    let items = Provider.all.filter { $0.type == type }
                    if !items.isEmpty {
                        Section(type == "Bank" ? "Banken" : type == "Wallet" ? "Wallets & Zahlungsdienste" : type == "Karte" ? "Kreditkarten" : "Broker") {
                            ForEach(items) { prov in
                                Button {
                                    store.connect(provider: prov)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        ProviderBadge(provider: prov, size: 30)
                                        Text(prov.name).foregroundStyle(.primary)
                                    }
                                }
                            }
                        }
                    }
                }
                Section {
                    Text("… und jede weitere Bank über den CSV-Import.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Anbieter wählen")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

struct ImportSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let account: Account

    @State private var pastedText = ""
    @State private var message: String?
    @State private var showFilePicker = false

    var body: some View {
        NavigationStack {
            Form {
                let prov = Provider.byId(account.providerId)
                Section("So exportierst du deine Umsätze bei \(prov.name) in 30 Sekunden") {
                    ForEach(Array(prov.exportGuide.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).").foregroundStyle(.blue).fontWeight(.bold)
                            Text(step)
                        }
                        .font(.subheadline)
                    }
                }
                Section("CSV-Datei") {
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("CSV/TXT-Datei importieren", systemImage: "doc.badge.arrow.up")
                    }
                }
                Section("Oder Text direkt einfügen") {
                    TextEditor(text: $pastedText)
                        .frame(minHeight: 120)
                        .font(.system(.caption, design: .monospaced))
                    Button("Eingefügten Text importieren") {
                        importText(pastedText)
                    }
                    .disabled(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if let message {
                    Section { Text(message).foregroundStyle(message.hasPrefix("✓") ? .green : .red) }
                }
                Section {
                    Text("Rein algorithmische Auswertung auf diesem Gerät — keine KI, keine Datenübertragung.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Import — \(account.label)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } }
            }
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.commaSeparatedText, .plainText, .data]) { result in
                if case .success(let url) = result {
                    let secured = url.startAccessingSecurityScopedResource()
                    defer { if secured { url.stopAccessingSecurityScopedResource() } }
                    if let text = try? String(contentsOf: url, encoding: .utf8) {
                        importText(text)
                    } else if let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .isoLatin1) {
                        importText(text)
                    } else {
                        message = "Datei konnte nicht gelesen werden."
                    }
                }
            }
        }
    }

    private func importText(_ text: String) {
        let count = store.importStatement(text: text, accountId: account.id)
        message = count > 0
            ? "✓ \(count) Umsätze importiert. Jetzt in der Übersicht scannen."
            : "Keine Umsätze erkannt. Erwartet pro Zeile: Datum, Name und Betrag (z.B. „15.06.2026  NETFLIX  -17,99“)."
    }
}
