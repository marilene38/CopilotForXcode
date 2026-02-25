import Foundation

// MARK: - Wallet Types

/// The type of an Algorand wallet.
public enum WalletType: String, Codable, CaseIterable {
    case standard
    case ledger
    case rekeyed
    case watchOnly
}

/// Represents a single Algorand account within a wallet.
public struct WalletAccount: Identifiable, Codable, Equatable {
    public var id: UUID
    /// Algorand public address (58-character base32-encoded string).
    public var address: String
    /// Human-readable name for this account.
    public var name: String
    /// Balance in microAlgos.
    public var balanceMicroAlgos: UInt64
    /// Whether this account is rekeyed to another address.
    public var authAddress: String?
    /// Algorand Standard Assets held by this account.
    public var assets: [AlgorandStandardAsset]

    public var balanceAlgos: Double {
        Double(balanceMicroAlgos) / 1_000_000
    }

    public init(
        id: UUID = UUID(),
        address: String,
        name: String = "Account",
        balanceMicroAlgos: UInt64 = 0,
        authAddress: String? = nil,
        assets: [AlgorandStandardAsset] = []
    ) {
        self.id = id
        self.address = address
        self.name = name
        self.balanceMicroAlgos = balanceMicroAlgos
        self.authAddress = authAddress
        self.assets = assets
    }

    /// Returns `true` if the account has been rekeyed to a different auth address.
    public var isRekeyed: Bool {
        guard let auth = authAddress else { return false }
        return auth != address
    }
}

/// Represents an Allo Wallet, which may hold one or more accounts on the Algorand blockchain.
public struct AlgorandWallet: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var type: WalletType
    public var accounts: [WalletAccount]
    /// The date the wallet was connected.
    public var connectedAt: Date
    /// Whether this wallet is currently active in the session.
    public var isConnected: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        type: WalletType,
        accounts: [WalletAccount] = [],
        connectedAt: Date = Date(),
        isConnected: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.accounts = accounts
        self.connectedAt = connectedAt
        self.isConnected = isConnected
    }
}
