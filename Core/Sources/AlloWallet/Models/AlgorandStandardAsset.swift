import Foundation

/// Represents an Algorand Standard Asset (ASA).
public struct AlgorandStandardAsset: Identifiable, Codable, Equatable {
    /// The unique ASA identifier on the Algorand network.
    public var id: UInt64
    /// Ticker symbol (e.g. "USDC").
    public var unitName: String
    /// Full asset name (e.g. "USD Coin").
    public var name: String
    /// Total supply expressed in the asset's base unit.
    public var totalSupply: UInt64
    /// Number of decimal places for the asset.
    public var decimals: UInt
    /// The account that created this asset.
    public var creatorAddress: String
    /// Optional URL associated with the asset.
    public var url: String?

    /// The amount held by an account, expressed in base units.
    public var accountBalance: UInt64

    public var formattedBalance: String {
        guard decimals > 0 else { return "\(accountBalance)" }
        let divisor = pow(10.0, Double(decimals))
        let value = Double(accountBalance) / divisor
        return String(format: "%.\(decimals)f %@", value, unitName)
    }

    public init(
        id: UInt64,
        unitName: String,
        name: String,
        totalSupply: UInt64 = 0,
        decimals: UInt = 0,
        creatorAddress: String,
        url: String? = nil,
        accountBalance: UInt64 = 0
    ) {
        self.id = id
        self.unitName = unitName
        self.name = name
        self.totalSupply = totalSupply
        self.decimals = decimals
        self.creatorAddress = creatorAddress
        self.url = url
        self.accountBalance = accountBalance
    }
}

// MARK: - Algorand Transaction

/// Represents a pending signature request for an Algorand transaction.
public struct AlgorandSignatureRequest: Identifiable, Codable, Equatable {
    public var id: UUID
    /// Base64-encoded unsigned transaction bytes.
    public var unsignedTxnBase64: String
    /// Human-readable description of the transaction.
    public var description: String
    /// The account address that should sign the transaction.
    public var signerAddress: String

    public init(
        id: UUID = UUID(),
        unsignedTxnBase64: String,
        description: String,
        signerAddress: String
    ) {
        self.id = id
        self.unsignedTxnBase64 = unsignedTxnBase64
        self.description = description
        self.signerAddress = signerAddress
    }
}
