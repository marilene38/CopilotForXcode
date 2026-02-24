"use client";

import { useCallback, useState } from "react";
import { ethers, BrowserProvider } from "ethers";
import { useWallet } from "@/context/WalletContext";
import { GasEstimate, TransactionResult } from "@/types/transaction";
import { formatGasEstimate } from "@/utils/validation";

export function useTransaction() {
  const { provider, address } = useWallet();
  const [gasEstimate, setGasEstimate] = useState<GasEstimate | null>(null);
  const [isEstimating, setIsEstimating] = useState(false);
  const [isSending, setIsSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<TransactionResult | null>(null);

  const estimateGas = useCallback(
    async (to: string, amountEther: string) => {
      if (!provider || !address) return;
      setIsEstimating(true);
      setError(null);
      try {
        const web3Provider = new BrowserProvider(provider as unknown as ethers.Eip1193Provider);
        const feeData = await web3Provider.getFeeData();
        const gasPrice = feeData.gasPrice ?? BigInt(0);
        const gasLimit = await web3Provider.estimateGas({
          from: address,
          to,
          value: ethers.parseEther(amountEther),
        });
        setGasEstimate(formatGasEstimate(gasPrice, gasLimit));
      } catch (err: unknown) {
        setError(
          err instanceof Error ? err.message : "Failed to estimate gas"
        );
        setGasEstimate(null);
      } finally {
        setIsEstimating(false);
      }
    },
    [provider, address]
  );

  const sendTransaction = useCallback(
    async (to: string, amountEther: string): Promise<TransactionResult | null> => {
      if (!provider || !address) return null;
      setIsSending(true);
      setError(null);
      setResult(null);
      try {
        const web3Provider = new BrowserProvider(provider as unknown as ethers.Eip1193Provider);
        const signer = await web3Provider.getSigner();
        const tx = await signer.sendTransaction({
          to,
          value: ethers.parseEther(amountEther),
        });
        const pending: TransactionResult = { hash: tx.hash, status: "pending" };
        setResult(pending);

        const receipt = await tx.wait();
        const final: TransactionResult = {
          hash: tx.hash,
          status: receipt?.status === 1 ? "success" : "failed",
        };
        setResult(final);
        return final;
      } catch (err: unknown) {
        const message =
          err instanceof Error ? err.message : "Transaction failed";
        setError(message);
        return null;
      } finally {
        setIsSending(false);
      }
    },
    [provider, address]
  );

  return {
    gasEstimate,
    isEstimating,
    isSending,
    error,
    result,
    estimateGas,
    sendTransaction,
  };
}
