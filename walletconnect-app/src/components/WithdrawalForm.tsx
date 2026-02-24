"use client";

import {
  Alert,
  Box,
  Button,
  CircularProgress,
  Divider,
  Paper,
  TextField,
  Typography,
} from "@mui/material";
import SendIcon from "@mui/icons-material/Send";
import OpenInNewIcon from "@mui/icons-material/OpenInNew";
import { useEffect, useState } from "react";
import { useWallet } from "@/context/WalletContext";
import { useTransaction } from "@/hooks/useTransaction";
import { isValidAddress, isValidAmount } from "@/utils/validation";

export default function WithdrawalForm() {
  const { isConnected, chain } = useWallet();
  const { gasEstimate, isEstimating, isSending, error, result, estimateGas, sendTransaction } =
    useTransaction();

  const [recipient, setRecipient] = useState("");
  const [amount, setAmount] = useState("");
  const [recipientError, setRecipientError] = useState("");
  const [amountError, setAmountError] = useState("");

  const symbol = chain?.nativeCurrency.symbol ?? "ETH";

  // Re-estimate gas whenever valid inputs change
  useEffect(() => {
    if (isValidAddress(recipient) && isValidAmount(amount)) {
      estimateGas(recipient, amount);
    }
  }, [recipient, amount, estimateGas]);

  function validateInputs(): boolean {
    let valid = true;
    if (!isValidAddress(recipient)) {
      setRecipientError("Enter a valid Ethereum address");
      valid = false;
    } else {
      setRecipientError("");
    }
    if (!isValidAmount(amount)) {
      setAmountError("Enter a positive amount");
      valid = false;
    } else {
      setAmountError("");
    }
    return valid;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!validateInputs()) return;
    await sendTransaction(recipient, amount);
  }

  if (!isConnected) {
    return (
      <Alert severity="info">
        Connect your wallet to make a withdrawal.
      </Alert>
    );
  }

  return (
    <Paper elevation={2} sx={{ p: 3 }}>
      <Typography variant="h6" gutterBottom>
        Withdraw {symbol}
      </Typography>

      <Box component="form" onSubmit={handleSubmit} display="flex" flexDirection="column" gap={2}>
        <TextField
          label="Recipient Address"
          placeholder="0x…"
          value={recipient}
          onChange={(e) => setRecipient(e.target.value)}
          error={!!recipientError}
          helperText={recipientError}
          fullWidth
          size="small"
          inputProps={{ "aria-label": "Recipient Address" }}
        />

        <TextField
          label={`Amount (${symbol})`}
          placeholder="0.01"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          error={!!amountError}
          helperText={amountError}
          fullWidth
          size="small"
          type="number"
          inputProps={{ min: 0, step: "any", "aria-label": "Amount" }}
        />

        {/* Gas estimate panel */}
        {(isEstimating || gasEstimate) && (
          <Box>
            <Divider sx={{ mb: 1 }} />
            <Typography variant="caption" color="text.secondary">
              Transaction Details
            </Typography>
            {isEstimating ? (
              <Box display="flex" alignItems="center" gap={1} mt={0.5}>
                <CircularProgress size={14} />
                <Typography variant="caption">Estimating gas…</Typography>
              </Box>
            ) : gasEstimate ? (
              <Box display="flex" flexDirection="column" gap={0.5} mt={0.5}>
                <Typography variant="caption">
                  Gas price: {gasEstimate.gasPrice}
                </Typography>
                <Typography variant="caption">
                  Gas limit: {gasEstimate.gasLimit}
                </Typography>
                <Typography variant="caption" fontWeight="bold">
                  Estimated fee: {gasEstimate.estimatedFee} {symbol}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Required confirmations: 1
                </Typography>
              </Box>
            ) : null}
          </Box>
        )}

        {/* Error alert */}
        {error && (
          <Alert severity="error">
            {error}
          </Alert>
        )}

        {/* Transaction result */}
        {result && (
          <Alert severity={result.status === "success" ? "success" : result.status === "pending" ? "info" : "error"}>
            {result.status === "pending" && "Transaction submitted — waiting for confirmation…"}
            {result.status === "success" && "Transaction confirmed!"}
            {result.status === "failed" && "Transaction failed on-chain."}
            {" "}
            {chain && (
              <a
                href={`${chain.blockExplorerUrl}/tx/${result.hash}`}
                target="_blank"
                rel="noopener noreferrer"
                style={{ display: "inline-flex", alignItems: "center", gap: 2 }}
              >
                View on explorer <OpenInNewIcon sx={{ fontSize: 12, ml: 0.5 }} />
              </a>
            )}
          </Alert>
        )}

        <Button
          type="submit"
          variant="contained"
          endIcon={isSending ? <CircularProgress size={16} color="inherit" /> : <SendIcon />}
          disabled={isSending || !isConnected}
          aria-label="Send withdrawal transaction"
        >
          {isSending ? "Sending…" : "Send Withdrawal"}
        </Button>
      </Box>
    </Paper>
  );
}
