import SwiftUI

// MARK: - Allo Wallet Main View

/// The top-level SwiftUI view for the Allo Wallet Connection feature.
public struct AlloWalletView: View {
    @StateObject private var service = AlloWalletService()
    @State private var showConnectSheet = false
    @State private var selectedWalletID: UUID?
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            Divider()
            contentView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showConnectSheet) {
            ConnectWalletSheet(service: service, isPresented: $showConnectSheet)
        }
        .alert(
            "Wallet Error",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var headerView: some View {
        HStack {
            Text("Allo Wallet Connection")
                .font(.headline)
            Spacer()
            Button(action: { showConnectSheet = true }) {
                Label("Connect Wallet", systemImage: "plus.circle")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            Button(action: reconnectAll) {
                Label("Reconnect All", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var contentView: some View {
        Group {
            if service.connectedWallets.isEmpty {
                emptyStateView
            } else {
                walletListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No wallets connected")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Connect an Algorand wallet to get started.")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Button("Connect Wallet") { showConnectSheet = true }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var walletListView: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(service.connectedWallets) { wallet in
                    WalletRowView(wallet: wallet) {
                        service.disconnect(walletID: wallet.id)
                    }
                }
                if !service.pendingSignatureRequests.isEmpty {
                    Divider().padding(.vertical, 4)
                    Text("Pending Signature Requests")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                    ForEach(service.pendingSignatureRequests) { request in
                        SignatureRequestRowView(request: request) {
                            service.resolveSignatureRequest(id: request.id)
                        }
                    }
                }
            }
            .padding(12)
        }
    }

    private func reconnectAll() {
        Task {
            await service.reconnectAll()
        }
    }
}

// MARK: - Wallet Row

private struct WalletRowView: View {
    let wallet: AlgorandWallet
    let onDisconnect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: walletIcon)
                    .foregroundStyle(wallet.isConnected ? .green : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(wallet.name).font(.subheadline).fontWeight(.medium)
                    Text(wallet.type.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Disconnect", action: onDisconnect)
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .foregroundStyle(.red)
            }
            ForEach(wallet.accounts) { account in
                AccountRowView(account: account)
                    .padding(.leading, 28)
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }

    private var walletIcon: String {
        switch wallet.type {
        case .ledger: return "lock.shield"
        case .rekeyed: return "key"
        case .watchOnly: return "eye"
        case .standard: return "wallet.pass"
        }
    }
}

// MARK: - Account Row

private struct AccountRowView: View {
    let account: WalletAccount

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(account.name).font(.caption).fontWeight(.medium)
                if account.isRekeyed {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            Text(account.address)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(String(format: "%.6f ALGO", account.balanceAlgos))
                .font(.caption)
                .foregroundStyle(.primary)
            if !account.assets.isEmpty {
                Text("\(account.assets.count) ASA(s)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Signature Request Row

private struct SignatureRequestRowView: View {
    let request: AlgorandSignatureRequest
    let onResolve: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "signature")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(request.description).font(.caption).fontWeight(.medium)
                Text(request.signerAddress)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Button("Resolve", action: onResolve)
                .buttonStyle(.bordered)
                .controlSize(.mini)
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
    }
}

// MARK: - Connect Wallet Sheet

private struct ConnectWalletSheet: View {
    @ObservedObject var service: AlloWalletService
    @Binding var isPresented: Bool

    @State private var address = ""
    @State private var name = ""
    @State private var walletType: WalletType = .standard
    @State private var qrInput = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?
    @State private var showQRInput = false
    @State private var twoFactorCode = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connect Algorand Wallet")
                .font(.headline)

            // Wallet Type Picker
            Picker("Wallet Type", selection: $walletType) {
                ForEach(WalletType.allCases, id: \.self) { type in
                    Text(type.rawValue.capitalized).tag(type)
                }
            }
            .pickerStyle(.segmented)

            // Name field
            LabeledContent("Wallet Name") {
                TextField("My Wallet", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            // Address field
            LabeledContent("Address") {
                HStack {
                    TextField("Algorand address (58 chars)", text: $address)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    Button(action: { showQRInput.toggle() }) {
                        Image(systemName: "qrcode.viewfinder")
                    }
                    .buttonStyle(.bordered)
                    .help("Paste QR code string")
                }
            }

            // QR Code input
            if showQRInput {
                LabeledContent("QR String") {
                    HStack {
                        TextField("algorand://... or raw address", text: $qrInput)
                            .textFieldStyle(.roundedBorder)
                        Button("Parse") {
                            if let parsed = service.parseQRCode(qrInput) {
                                address = parsed
                                showQRInput = false
                            } else {
                                errorMessage = "Could not parse a valid Algorand address from the QR code."
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            // 2FA field (shown when enabled)
            if service.isTwoFactorEnabled {
                LabeledContent("2FA Code") {
                    TextField("Enter 6-digit code", text: $twoFactorCode)
                        .textFieldStyle(.roundedBorder)
                }
                .help("Two-factor authentication is enabled for this wallet connection.")
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Toggle("Enable 2FA", isOn: $service.isTwoFactorEnabled)
                    .controlSize(.small)
                Spacer()
                Button("Cancel") { isPresented = false }
                    .buttonStyle(.bordered)
                Button("Connect") { connect() }
                    .buttonStyle(.borderedProminent)
                    .disabled(address.isEmpty || isConnecting)
            }
        }
        .padding(20)
        .frame(width: 440)
    }

    private func connect() {
        guard !address.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isConnecting = true
        errorMessage = nil
        let walletName = name.isEmpty ? "Unnamed Wallet" : name
        Task {
            do {
                try await service.connect(
                    address: address.trimmingCharacters(in: .whitespaces),
                    name: walletName,
                    type: walletType
                )
                await MainActor.run { isPresented = false }
            } catch let error as AlloWalletError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isConnecting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isConnecting = false
                }
            }
        }
    }
}
