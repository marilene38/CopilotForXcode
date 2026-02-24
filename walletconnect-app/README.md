# WalletConnect Withdrawal App

A secure, cross-chain withdrawal application built with [Next.js](https://nextjs.org/), [Material-UI](https://mui.com/), and [WalletConnect v2](https://docs.walletconnect.com/). It lets users connect any WalletConnect-compatible wallet, automatically detects the active blockchain network, and submits signed withdrawal transactions.

---

## Features

| Feature | Details |
|---|---|
| **Cross-chain support** | Ethereum Mainnet, BNB Smart Chain, Goerli Testnet, BSC Testnet |
| **Auto network detection** | Reads `chainId` from the connected wallet and adapts the UI |
| **Wallet connection** | WalletConnect v2 QR-modal – works with MetaMask Mobile, Trust Wallet, Rainbow, and more |
| **Withdrawal form** | Recipient address, amount, live gas estimate, required confirmations |
| **Secure signing** | All transactions are signed inside the user's own wallet via WalletConnect |
| **Error handling** | Validates address format, amount range, and reports on-chain failures |
| **Material-UI design** | Polished, accessible component library |
| **Tests** | Jest + ts-jest unit tests for chain config and validation utilities |

---

## Prerequisites

- **Node.js** ≥ 18
- **npm** ≥ 9
- A **WalletConnect Project ID** – free at <https://cloud.walletconnect.com>

---

## Getting Started

### 1. Clone & install

```bash
git clone <repo-url>
cd walletconnect-app
npm install
```

### 2. Configure environment

```bash
cp .env.example .env.local
```

Open `.env.local` and replace `your_project_id_here` with your WalletConnect Project ID:

```env
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=abc123...
```

### 3. Run the development server

```bash
npm run dev
```

Open <http://localhost:3000> in your browser.

---

## Connecting Your Wallet

1. Click **Connect Wallet** in the top-right of the app bar.
2. A WalletConnect QR modal appears – scan it with any compatible wallet app, or copy the URI.
3. Approve the connection in your wallet.
4. The app bar shows your abbreviated address and the currently active network.

To switch networks, change the network inside your wallet app. The app detects the new `chainId` automatically and updates the currency symbol and block-explorer links.

---

## Making a Withdrawal

1. Ensure your wallet is connected and on one of the supported networks.
2. Enter the **Recipient Address** (must be a valid EVM address).
3. Enter the **Amount** in the native currency (ETH, BNB, etc.).
4. The app estimates **gas price**, **gas limit**, and **estimated fee** in real time.
5. Click **Send Withdrawal**.
6. Approve the transaction in your wallet app.
7. The status banner updates from *pending* → *confirmed* (or *failed*) and shows a block-explorer link.

---

## Testnet Usage

| Network | Chain ID | Faucet |
|---|---|---|
| Goerli (Ethereum) | 5 | <https://goerlifaucet.com> |
| BSC Testnet | 97 | <https://testnet.bnbchain.org/faucet-smart> |

Switch your wallet to a testnet before testing. The app badge turns orange for testnet chains.

---

## Running Tests

```bash
npm test
```

Tests cover:

- `src/__tests__/chain.test.ts` – chain registry (supported chains, `getChainById`)
- `src/__tests__/validation.test.ts` – address validation, amount validation, gas formatting, address shortening

---

## Project Structure

```
walletconnect-app/
├── src/
│   ├── app/                    # Next.js App Router pages & layout
│   │   ├── layout.tsx          # Root layout with WalletProvider
│   │   └── page.tsx            # Main page
│   ├── components/
│   │   ├── WalletConnectButton.tsx  # Connect/disconnect + status chip
│   │   ├── WithdrawalForm.tsx       # Withdrawal form with gas estimate
│   │   └── NetworkInfo.tsx          # Supported-chains panel
│   ├── context/
│   │   └── WalletContext.tsx   # WalletConnect provider & wallet state
│   ├── hooks/
│   │   └── useTransaction.ts   # Gas estimation & transaction sending
│   ├── types/
│   │   ├── chain.ts            # Chain interface, SUPPORTED_CHAINS, getChainById
│   │   └── transaction.ts      # WithdrawalFormValues, TransactionResult, GasEstimate
│   ├── utils/
│   │   └── validation.ts       # isValidAddress, isValidAmount, formatGasEstimate, shortenAddress
│   └── __tests__/
│       ├── chain.test.ts
│       └── validation.test.ts
├── .env.example
├── jest.config.ts
└── package.json
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| *"Connect Wallet" does nothing* | Ensure `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID` is set and valid |
| Gas estimation fails | Make sure the recipient address is valid and you have enough balance |
| Transaction rejected | You declined the request in your wallet – try again |
| Wrong currency symbol | Switch your wallet to the desired network |
| Tests fail | Run `npm install` to ensure all dev dependencies are present |

---

## Security Notes

- **No private keys** are ever handled by this application. All signing happens inside the user's wallet via WalletConnect.
- Always test on a testnet before interacting with mainnet funds.
- The WalletConnect Project ID is a public key; it does **not** need to be kept secret, but it should be scoped to your allowed domains in the WalletConnect dashboard.

---

## License

This project is part of the CopilotForXcode repository and is distributed under the same license.
