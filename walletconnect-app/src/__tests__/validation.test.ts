import {
  isValidAddress,
  isValidAmount,
  shortenAddress,
  formatGasEstimate,
} from "../utils/validation";

describe("isValidAddress", () => {
  it("returns true for a valid checksummed address", () => {
    expect(isValidAddress("0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")).toBe(true);
  });

  it("returns true for a lowercase valid address", () => {
    expect(isValidAddress("0xd8da6bf26964af9d7eed9e03e53415d37aa96045")).toBe(true);
  });

  it("returns false for an address that is too short", () => {
    expect(isValidAddress("0x1234")).toBe(false);
  });

  it("returns false for an empty string", () => {
    expect(isValidAddress("")).toBe(false);
  });

  it("returns false for a non-hex string", () => {
    expect(isValidAddress("not-an-address")).toBe(false);
  });
});

describe("isValidAmount", () => {
  it("returns true for a valid positive decimal", () => {
    expect(isValidAmount("0.01")).toBe(true);
  });

  it("returns true for a whole number", () => {
    expect(isValidAmount("1")).toBe(true);
  });

  it("returns false for zero", () => {
    expect(isValidAmount("0")).toBe(false);
  });

  it("returns false for a negative number", () => {
    expect(isValidAmount("-1")).toBe(false);
  });

  it("returns false for an empty string", () => {
    expect(isValidAmount("")).toBe(false);
  });

  it("returns false for a non-numeric string", () => {
    expect(isValidAmount("abc")).toBe(false);
  });

  it("returns false for more than 18 decimal places", () => {
    expect(isValidAmount("0.1234567890123456789")).toBe(false);
  });

  it("returns true for exactly 18 decimal places", () => {
    expect(isValidAmount("0.123456789012345678")).toBe(true);
  });
});

describe("shortenAddress", () => {
  it("shortens a valid address", () => {
    const addr = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045";
    const short = shortenAddress(addr);
    expect(short.startsWith("0xd8dA")).toBe(true);
    expect(short.endsWith("6045")).toBe(true);
    expect(short).toContain("…");
  });

  it("returns the original string for an invalid address", () => {
    expect(shortenAddress("invalid")).toBe("invalid");
  });
});

describe("formatGasEstimate", () => {
  it("formats gas price in Gwei", () => {
    const estimate = formatGasEstimate(BigInt("1000000000"), BigInt(21000));
    expect(estimate.gasPrice).toContain("Gwei");
    expect(estimate.gasLimit).toBe("21000");
  });

  it("computes estimated fee", () => {
    // gasPrice = 1 Gwei = 1e9 Wei, gasLimit = 21000
    // fee = 21000 * 1e9 = 21000e9 Wei = 0.000021 ETH
    const estimate = formatGasEstimate(BigInt("1000000000"), BigInt(21000));
    expect(estimate.estimatedFee).toBe("0.000021");
  });
});
