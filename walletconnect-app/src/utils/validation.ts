import { ethers } from "ethers";
import { GasEstimate } from "@/types/transaction";

/**
 * Returns true when `address` is a valid checksummed or lowercase Ethereum address.
 */
export function isValidAddress(address: string): boolean {
  return ethers.isAddress(address);
}

/**
 * Returns true when `amount` is a positive finite decimal number with at most
 * 18 decimal places.
 */
export function isValidAmount(amount: string): boolean {
  if (!amount || amount.trim() === "") return false;
  const num = parseFloat(amount);
  if (!isFinite(num) || num <= 0) return false;
  const parts = amount.split(".");
  if (parts.length > 1 && parts[1].length > 18) return false;
  return true;
}

/**
 * Formats a gas estimate into human-readable strings.
 */
export function formatGasEstimate(
  gasPriceWei: bigint,
  gasLimit: bigint
): GasEstimate {
  const fee = gasPriceWei * gasLimit;
  return {
    gasPrice: `${ethers.formatUnits(gasPriceWei, "gwei")} Gwei`,
    gasLimit: gasLimit.toString(),
    estimatedFee: ethers.formatEther(fee),
  };
}

/**
 * Shortens an Ethereum address to "0x1234…abcd" form.
 */
export function shortenAddress(address: string): string {
  if (!isValidAddress(address)) return address;
  return `${address.slice(0, 6)}…${address.slice(-4)}`;
}
