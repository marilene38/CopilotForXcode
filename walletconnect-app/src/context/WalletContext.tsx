"use client";

import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from "react";
import EthereumProvider from "@walletconnect/ethereum-provider";
import { WalletConnectModal } from "@walletconnect/modal";
import { Chain, SUPPORTED_CHAINS, getChainById } from "@/types/chain";

// Replace with your own WalletConnect project ID from https://cloud.walletconnect.com
const PROJECT_ID =
  process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID ?? "YOUR_PROJECT_ID";

interface WalletContextValue {
  address: string | null;
  chainId: number | null;
  chain: Chain | undefined;
  isConnected: boolean;
  isConnecting: boolean;
  connect: () => Promise<void>;
  disconnect: () => Promise<void>;
  provider: EthereumProvider | null;
}

const WalletContext = createContext<WalletContextValue>({
  address: null,
  chainId: null,
  chain: undefined,
  isConnected: false,
  isConnecting: false,
  connect: async () => {},
  disconnect: async () => {},
  provider: null,
});

export function useWallet() {
  return useContext(WalletContext);
}

export function WalletProvider({ children }: { children: React.ReactNode }) {
  const [provider, setProvider] = useState<EthereumProvider | null>(null);
  const [modal, setModal] = useState<WalletConnectModal | null>(null);
  const [address, setAddress] = useState<string | null>(null);
  const [chainId, setChainId] = useState<number | null>(null);
  const [isConnecting, setIsConnecting] = useState(false);

  // Initialise provider and modal once on mount
  useEffect(() => {
    let cancelled = false;

    async function init() {
      const wcProvider = await EthereumProvider.init({
        projectId: PROJECT_ID,
        chains: SUPPORTED_CHAINS.map((c) => c.id) as [number, ...number[]],
        showQrModal: false, // We control the modal manually
        metadata: {
          name: "WalletConnect Withdrawal App",
          description: "Secure cross-chain withdrawal application",
          url: typeof window !== "undefined" ? window.location.origin : "",
          icons: [],
        },
      });

      const wcModal = new WalletConnectModal({
        projectId: PROJECT_ID,
        chains: SUPPORTED_CHAINS.map((c) => `eip155:${c.id}`),
      });

      if (cancelled) return;

      // Restore a pre-existing session
      if (wcProvider.session) {
        const accounts = wcProvider.accounts;
        setAddress(accounts[0] ?? null);
        setChainId(wcProvider.chainId);
      }

      wcProvider.on("accountsChanged", (accounts: string[]) => {
        setAddress(accounts[0] ?? null);
      });

      wcProvider.on("chainChanged", (id: string | number) => {
        setChainId(typeof id === "string" ? parseInt(id, 16) : id);
      });

      wcProvider.on("disconnect", () => {
        setAddress(null);
        setChainId(null);
      });

      setProvider(wcProvider);
      setModal(wcModal);
    }

    init();
    return () => {
      cancelled = true;
    };
  }, []);

  const connect = useCallback(async () => {
    if (!provider || !modal) return;
    setIsConnecting(true);
    try {
      // Open the QR modal once the URI is available from the provider
      provider.once("display_uri", (uri: string) => {
        modal.openModal({ uri });
      });
      await provider.connect();
      const accounts = provider.accounts;
      setAddress(accounts[0] ?? null);
      setChainId(provider.chainId);
    } finally {
      modal.closeModal();
      setIsConnecting(false);
    }
  }, [provider, modal]);

  const disconnect = useCallback(async () => {
    if (!provider) return;
    await provider.disconnect();
    setAddress(null);
    setChainId(null);
  }, [provider]);

  const chain = chainId != null ? getChainById(chainId) : undefined;

  return (
    <WalletContext.Provider
      value={{
        address,
        chainId,
        chain,
        isConnected: !!address,
        isConnecting,
        connect,
        disconnect,
        provider,
      }}
    >
      {children}
    </WalletContext.Provider>
  );
}
