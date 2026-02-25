import Foundation

// MARK: - Wallet Connection Errors

public enum AlloWalletError: LocalizedError, Equatable {
    case invalidAddress
    case networkUnavailable
    case accountNotFound(address: String)
    case sessionExpired
    case twoFactorRequired
    case unsupportedWalletType

    public var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return "The provided Algorand address is invalid."
        case .networkUnavailable:
            return "Network is unavailable. Please check your internet connection."
        case .accountNotFound(let address):
            return "No account found for address: \(address)."
        case .sessionExpired:
            return "Your wallet session has expired. Please reconnect."
        case .twoFactorRequired:
            return "Two-factor authentication is required to connect this wallet."
        case .unsupportedWalletType:
            return "This wallet type is not supported."
        }
    }
}

// MARK: - AlgoExplorer API Response Models

private struct AlgoExplorerAccountResponse: Decodable {
    let amount: UInt64
    let address: String
    let authAddr: String?
    let assets: [AlgoExplorerAssetHolding]?

    enum CodingKeys: String, CodingKey {
        case amount
        case address
        case authAddr = "auth-addr"
        case assets
    }
}

private struct AlgoExplorerAssetHolding: Decodable {
    let assetId: UInt64
    let amount: UInt64

    enum CodingKeys: String, CodingKey {
        case assetId = "asset-id"
        case amount
    }
}

// MARK: - AlloWalletService

/// Provides wallet connection, account lookup, and session management for Algorand wallets.
public final class AlloWalletService: ObservableObject {
    /// The base URL of the AlgoExplorer indexer API (v2).
    public static let algoExplorerBaseURL = URL(string: "https://algoexplorer.io/api/v2")!

    @Published public var connectedWallets: [AlgorandWallet] = []
    @Published public var pendingSignatureRequests: [AlgorandSignatureRequest] = []
    @Published public var isTwoFactorEnabled: Bool = false

    private let session: URLSession
    private let persistenceKey = "alloWallet.connectedWallets"

    public init(session: URLSession = .shared) {
        self.session = session
        loadPersistedWallets()
    }

    // MARK: - Connection

    /// Connects a new wallet by address, fetching account info from AlgoExplorer.
    @discardableResult
    public func connect(
        address: String,
        name: String,
        type: WalletType
    ) async throws -> AlgorandWallet {
        guard isValidAlgorandAddress(address) else {
            throw AlloWalletError.invalidAddress
        }

        let account = try await fetchAccount(address: address)
        var wallet = AlgorandWallet(
            name: name,
            type: type,
            accounts: [account],
            isConnected: true
        )

        await MainActor.run {
            connectedWallets.append(wallet)
            persistWallets()
        }

        return wallet
    }

    /// Disconnects a wallet and removes it from the session.
    public func disconnect(walletID: UUID) {
        connectedWallets.removeAll { $0.id == walletID }
        persistWallets()
    }

    /// Reconnects all previously persisted wallets, refreshing their account data.
    public func reconnectAll() async {
        var refreshed: [AlgorandWallet] = []
        for wallet in connectedWallets {
            var updated = wallet
            updated.accounts = await withTaskGroup(of: WalletAccount?.self) { group in
                for account in wallet.accounts {
                    group.addTask { try? await self.fetchAccount(address: account.address) }
                }
                var accounts: [WalletAccount] = []
                for await result in group {
                    if let a = result { accounts.append(a) }
                }
                return accounts
            }
            updated.isConnected = !updated.accounts.isEmpty
            refreshed.append(updated)
        }
        await MainActor.run {
            connectedWallets = refreshed
            persistWallets()
        }
    }

    // MARK: - Signature Requests

    /// Submits a new signature request for an Algorand transaction.
    public func requestSignature(
        unsignedTxnBase64: String,
        description: String,
        signerAddress: String
    ) {
        let request = AlgorandSignatureRequest(
            unsignedTxnBase64: unsignedTxnBase64,
            description: description,
            signerAddress: signerAddress
        )
        pendingSignatureRequests.append(request)
    }

    /// Resolves (removes) a signature request after it has been processed.
    public func resolveSignatureRequest(id: UUID) {
        pendingSignatureRequests.removeAll { $0.id == id }
    }

    // MARK: - QR Code Parsing

    /// Parses an Algorand address from a QR code string.
    /// Supported formats: plain address or `algorand://<address>` URI scheme.
    public func parseQRCode(_ qrString: String) -> String? {
        if isValidAlgorandAddress(qrString) { return qrString }
        if let url = URL(string: qrString),
           url.scheme?.lowercased() == "algorand",
           let host = url.host,
           isValidAlgorandAddress(host)
        {
            return host
        }
        return nil
    }

    // MARK: - Validation

    /// Validates a base32-encoded Algorand address (58 characters).
    public func isValidAlgorandAddress(_ address: String) -> Bool {
        address.count == 58 && address.allSatisfy { $0.isLetter || $0.isNumber }
    }

    // MARK: - Private Helpers

    private func fetchAccount(address: String) async throws -> WalletAccount {
        let url = Self.algoExplorerBaseURL
            .appendingPathComponent("accounts")
            .appendingPathComponent(address)

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AlloWalletError.accountNotFound(address: address)
        }

        let decoded = try JSONDecoder().decode(AlgoExplorerAccountResponse.self, from: data)
        let assetHoldings = decoded.assets?.map { holding in
            AlgorandStandardAsset(
                id: holding.assetId,
                unitName: "",
                name: "",
                creatorAddress: "",
                accountBalance: holding.amount
            )
        } ?? []

        return WalletAccount(
            address: decoded.address,
            balanceMicroAlgos: decoded.amount,
            authAddress: decoded.authAddr,
            assets: assetHoldings
        )
    }

    // MARK: - Persistence

    private func persistWallets() {
        guard let data = try? JSONEncoder().encode(connectedWallets) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }

    private func loadPersistedWallets() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let wallets = try? JSONDecoder().decode([AlgorandWallet].self, from: data)
        else { return }
        connectedWallets = wallets
    }
}
