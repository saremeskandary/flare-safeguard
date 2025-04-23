export interface TokenInfo {
  symbol: string;
  name: string;
  address: string;
  decimals: number;
  logoURI?: string;
}

// Flare Testnet Token Addresses
export const FLARE_TESTNET_TOKENS: TokenInfo[] = [
  {
    symbol: "USDC",
    name: "USD Coin",
    address: "0x2D2acD205bd6d9D0BACCa14bfd1fAfFc1E6C144f",
    decimals: 6,
  },
  {
    symbol: "USDT",
    name: "Tether USD",
    address: "0x0F9Dd53E2dB1825B8C40b8AA31F4c6b1b6c81d2E",
    decimals: 6,
  },
  {
    symbol: "DAI",
    name: "Dai Stablecoin",
    address: "0x3Ee7094DADda15810F191DD6AcF7E4FFa37571e4",
    decimals: 18,
  },
  {
    symbol: "WETH",
    name: "Wrapped Ether",
    address: "0x19a6304a0CF45187A5Bd6EdE94E6d146d8aDc06C",
    decimals: 18,
  },
  {
    symbol: "WBTC",
    name: "Wrapped Bitcoin",
    address: "0x3dAB4506BcFCaFc556d2EA245B4D6621A6Cba61A",
    decimals: 8,
  },
  {
    symbol: "FLR",
    name: "Flare",
    address: "0x1D80c49BbBCd1C0911346656B7DFadfc0564c62b",
    decimals: 18,
  },
  {
    symbol: "SGB",
    name: "Songbird",
    address: "0x02f0826ef76a43f4c5e544aabf88b65fa34907c0",
    decimals: 18,
  },
  {
    symbol: "BSD",
    name: "BSD Token",
    address: "0x0000000000000000000000000000000000000000", // This will be updated with the actual mock token address
    decimals: 18,
  },
];

// Function to update the BSD token address
export const updateBSDTokenAddress = (address: string): void => {
  const bsdTokenIndex = FLARE_TESTNET_TOKENS.findIndex(token => token.symbol === "BSD");
  if (bsdTokenIndex !== -1) {
    FLARE_TESTNET_TOKENS[bsdTokenIndex].address = address;
  }
};

// Function to get token by address
export const getTokenByAddress = (address: string): TokenInfo | undefined => {
  return FLARE_TESTNET_TOKENS.find(
    token => token.address.toLowerCase() === address.toLowerCase()
  );
};

// Function to get token by symbol
export const getTokenBySymbol = (symbol: string): TokenInfo | undefined => {
  return FLARE_TESTNET_TOKENS.find(
    token => token.symbol.toLowerCase() === symbol.toLowerCase()
  );
};

// Function to validate if an address is a valid token address
export const isValidTokenAddress = (address: string): boolean => {
  return FLARE_TESTNET_TOKENS.some(
    token => token.address.toLowerCase() === address.toLowerCase()
  );
}; 