import {
  AppBar,
  Box,
  Container,
  Stack,
  Toolbar,
  Typography,
} from "@mui/material";
import AccountBalanceWalletIcon from "@mui/icons-material/AccountBalanceWallet";
import WalletConnectButton from "@/components/WalletConnectButton";
import WithdrawalForm from "@/components/WithdrawalForm";
import NetworkInfo from "@/components/NetworkInfo";

export default function Home() {
  return (
    <Box sx={{ minHeight: "100vh", bgcolor: "grey.50" }}>
      <AppBar position="static" color="primary" elevation={1}>
        <Toolbar>
          <AccountBalanceWalletIcon sx={{ mr: 1 }} />
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            WalletConnect Withdrawal
          </Typography>
          <WalletConnectButton />
        </Toolbar>
      </AppBar>

      <Container maxWidth="sm" sx={{ mt: 4 }}>
        <Stack spacing={3}>
          <NetworkInfo />
          <WithdrawalForm />
        </Stack>
      </Container>
    </Box>
  );
}
