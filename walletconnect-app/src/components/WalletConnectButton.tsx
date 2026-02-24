"use client";

import {
  Alert,
  Box,
  Button,
  Chip,
  CircularProgress,
  Typography,
} from "@mui/material";
import AccountBalanceWalletIcon from "@mui/icons-material/AccountBalanceWallet";
import { useWallet } from "@/context/WalletContext";
import { shortenAddress } from "@/utils/validation";

export default function WalletConnectButton() {
  const { address, chain, isConnected, isConnecting, connect, disconnect } =
    useWallet();

  return (
    <Box display="flex" flexDirection="column" gap={1}>
      {isConnected && chain && (
        <Box display="flex" alignItems="center" gap={1}>
          <Chip
            size="small"
            color={chain.isTestnet ? "warning" : "success"}
            label={chain.name}
          />
          {chain.isTestnet && (
            <Alert severity="warning" sx={{ py: 0, px: 1, fontSize: "0.75rem" }}>
              Testnet
            </Alert>
          )}
        </Box>
      )}

      {isConnected && address ? (
        <Box display="flex" alignItems="center" gap={2}>
          <Typography variant="body2" fontFamily="monospace">
            {shortenAddress(address)}
          </Typography>
          <Button
            variant="outlined"
            color="error"
            size="small"
            onClick={disconnect}
          >
            Disconnect
          </Button>
        </Box>
      ) : (
        <Button
          variant="contained"
          startIcon={
            isConnecting ? (
              <CircularProgress size={16} color="inherit" />
            ) : (
              <AccountBalanceWalletIcon />
            )
          }
          onClick={connect}
          disabled={isConnecting}
        >
          {isConnecting ? "Connecting…" : "Connect Wallet"}
        </Button>
      )}
    </Box>
  );
}
