import XCTest

@testable import AlloWallet

final class AlloWalletTests: XCTestCase {
    // MARK: - AlgorandWallet Model Tests

    func test_wallet_creation_defaults() {
        let wallet = AlgorandWallet(name: "Test Wallet", type: .standard)
        XCTAssertFalse(wallet.accounts.isEmpty == false, "New wallet should have no accounts by default")
        XCTAssertFalse(wallet.isConnected)
        XCTAssertEqual(wallet.type, .standard)
        XCTAssertEqual(wallet.name, "Test Wallet")
    }

    func test_wallet_account_balance_conversion() {
        let account = WalletAccount(address: String(repeating: "A", count: 58), balanceMicroAlgos: 1_500_000)
        XCTAssertEqual(account.balanceAlgos, 1.5, accuracy: 0.000001)
    }

    func test_wallet_account_rekeyed_detection() {
        let regularAccount = WalletAccount(address: String(repeating: "A", count: 58))
        XCTAssertFalse(regularAccount.isRekeyed)

        let rekeyedAccount = WalletAccount(
            address: String(repeating: "A", count: 58),
            authAddress: String(repeating: "B", count: 58)
        )
        XCTAssertTrue(rekeyedAccount.isRekeyed)
    }

    func test_wallet_account_same_auth_address_not_rekeyed() {
        let address = String(repeating: "A", count: 58)
        let account = WalletAccount(address: address, authAddress: address)
        XCTAssertFalse(account.isRekeyed)
    }

    // MARK: - AlgorandStandardAsset Tests

    func test_asa_formatted_balance_no_decimals() {
        let asa = AlgorandStandardAsset(
            id: 1,
            unitName: "MYTOKEN",
            name: "My Token",
            creatorAddress: String(repeating: "A", count: 58),
            accountBalance: 100
        )
        XCTAssertEqual(asa.formattedBalance, "100")
    }

    func test_asa_formatted_balance_with_decimals() {
        let asa = AlgorandStandardAsset(
            id: 31566704,
            unitName: "USDC",
            name: "USD Coin",
            decimals: 6,
            creatorAddress: String(repeating: "A", count: 58),
            accountBalance: 5_000_000
        )
        XCTAssertTrue(asa.formattedBalance.contains("5.000000"))
        XCTAssertTrue(asa.formattedBalance.contains("USDC"))
    }

    // MARK: - AlloWalletService Validation Tests

    func test_valid_algorand_address() {
        let service = AlloWalletService()
        let validAddress = String(repeating: "A", count: 58)
        XCTAssertTrue(service.isValidAlgorandAddress(validAddress))
    }

    func test_invalid_algorand_address_too_short() {
        let service = AlloWalletService()
        XCTAssertFalse(service.isValidAlgorandAddress("SHORT"))
    }

    func test_invalid_algorand_address_with_special_chars() {
        let service = AlloWalletService()
        let invalidAddress = String(repeating: "A", count: 57) + "!"
        XCTAssertFalse(service.isValidAlgorandAddress(invalidAddress))
    }

    func test_invalid_algorand_address_empty() {
        let service = AlloWalletService()
        XCTAssertFalse(service.isValidAlgorandAddress(""))
    }

    // MARK: - QR Code Parsing Tests

    func test_qr_parse_plain_address() {
        let service = AlloWalletService()
        let address = String(repeating: "A", count: 58)
        XCTAssertEqual(service.parseQRCode(address), address)
    }

    func test_qr_parse_algorand_uri() {
        let service = AlloWalletService()
        let address = String(repeating: "A", count: 58)
        let uri = "algorand://\(address)"
        XCTAssertEqual(service.parseQRCode(uri), address)
    }

    func test_qr_parse_invalid_string() {
        let service = AlloWalletService()
        XCTAssertNil(service.parseQRCode("not-an-address"))
    }

    // MARK: - Signature Request Tests

    func test_add_and_resolve_signature_request() {
        let service = AlloWalletService()
        XCTAssertTrue(service.pendingSignatureRequests.isEmpty)

        let address = String(repeating: "A", count: 58)
        service.requestSignature(
            unsignedTxnBase64: "dGVzdA==",
            description: "Test transaction",
            signerAddress: address
        )
        XCTAssertEqual(service.pendingSignatureRequests.count, 1)

        let requestID = service.pendingSignatureRequests[0].id
        service.resolveSignatureRequest(id: requestID)
        XCTAssertTrue(service.pendingSignatureRequests.isEmpty)
    }

    // MARK: - Connect/Disconnect Tests

    func test_connect_invalid_address_throws() async {
        let service = AlloWalletService()
        do {
            try await service.connect(address: "INVALID", name: "Test", type: .standard)
            XCTFail("Expected AlloWalletError.invalidAddress to be thrown")
        } catch AlloWalletError.invalidAddress {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_disconnect_removes_wallet() async throws {
        let service = AlloWalletService()
        // Manually inject a wallet without network call
        let wallet = AlgorandWallet(name: "Injected", type: .standard, isConnected: true)
        service.connectedWallets.append(wallet)
        XCTAssertEqual(service.connectedWallets.count, 1)

        service.disconnect(walletID: wallet.id)
        XCTAssertTrue(service.connectedWallets.isEmpty)
    }

    // MARK: - AlloWalletError Tests

    func test_error_descriptions_not_empty() {
        let errors: [AlloWalletError] = [
            .invalidAddress,
            .networkUnavailable,
            .accountNotFound(address: "TEST"),
            .sessionExpired,
            .twoFactorRequired,
            .unsupportedWalletType,
        ]
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}
