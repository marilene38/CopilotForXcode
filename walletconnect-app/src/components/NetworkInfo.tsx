"use client";

import {
  Box,
  Chip,
  Divider,
  Paper,
  Tooltip,
  Typography,
} from "@mui/material";
import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import { SUPPORTED_CHAINS } from "@/types/chain";

export default function NetworkInfo() {
  return (
    <Paper variant="outlined" sx={{ p: 2 }}>
      <Box display="flex" alignItems="center" gap={1} mb={1}>
        <Typography variant="subtitle2">Supported Networks</Typography>
        <Tooltip title="The app automatically detects the connected chain. Switch networks in your wallet.">
          <InfoOutlinedIcon fontSize="small" color="action" />
        </Tooltip>
      </Box>
      <Divider sx={{ mb: 1.5 }} />
      <Box display="flex" flexWrap="wrap" gap={1}>
        {SUPPORTED_CHAINS.map((chain) => (
          <Chip
            key={chain.id}
            label={chain.name}
            size="small"
            color={chain.isTestnet ? "warning" : "primary"}
            variant={chain.isTestnet ? "outlined" : "filled"}
          />
        ))}
      </Box>
      <Typography variant="caption" color="text.secondary" sx={{ mt: 1.5, display: "block" }}>
        Mainnet chains are shown in blue. Testnet chains are outlined in orange.
        Switch the network inside your wallet app to interact with a different chain.
      </Typography>
    </Paper>
  );
}
