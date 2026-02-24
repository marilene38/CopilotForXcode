export interface WithdrawalFormValues {
  recipientAddress: string;
  amount: string;
}

export interface TransactionResult {
  hash: string;
  status: "pending" | "success" | "failed";
}

export interface GasEstimate {
  gasPrice: string;
  gasLimit: string;
  estimatedFee: string;
}
