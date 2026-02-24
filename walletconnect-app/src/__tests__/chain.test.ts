import {
  SUPPORTED_CHAINS,
  getChainById,
  Chain,
} from "../types/chain";

describe("SUPPORTED_CHAINS", () => {
  it("contains at least one mainnet and one testnet chain", () => {
    const mainnets = SUPPORTED_CHAINS.filter((c) => !c.isTestnet);
    const testnets = SUPPORTED_CHAINS.filter((c) => c.isTestnet);
    expect(mainnets.length).toBeGreaterThan(0);
    expect(testnets.length).toBeGreaterThan(0);
  });

  it("includes Ethereum Mainnet with chain id 1", () => {
    const eth = getChainById(1);
    expect(eth).toBeDefined();
    expect(eth!.name).toBe("Ethereum Mainnet");
    expect(eth!.nativeCurrency.symbol).toBe("ETH");
    expect(eth!.isTestnet).toBe(false);
  });

  it("includes BNB Smart Chain with chain id 56", () => {
    const bsc = getChainById(56);
    expect(bsc).toBeDefined();
    expect(bsc!.name).toBe("BNB Smart Chain");
    expect(bsc!.isTestnet).toBe(false);
  });

  it("includes Goerli Testnet with chain id 5", () => {
    const goerli = getChainById(5);
    expect(goerli).toBeDefined();
    expect(goerli!.isTestnet).toBe(true);
  });

  it("includes BSC Testnet with chain id 97", () => {
    const bscTestnet = getChainById(97);
    expect(bscTestnet).toBeDefined();
    expect(bscTestnet!.isTestnet).toBe(true);
  });

  it("returns undefined for unknown chain id", () => {
    expect(getChainById(999999)).toBeUndefined();
  });

  it("every chain has required fields", () => {
    SUPPORTED_CHAINS.forEach((chain: Chain) => {
      expect(chain.id).toBeGreaterThan(0);
      expect(chain.name).toBeTruthy();
      expect(chain.rpcUrl).toMatch(/^https?:\/\//);
      expect(chain.blockExplorerUrl).toMatch(/^https?:\/\//);
      expect(chain.nativeCurrency.decimals).toBe(18);
    });
  });
});
