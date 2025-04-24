// SPDX-License-Identifier: MIT

/**
 * Token addresses for the BSD Insurance Protocol
 * These tokens represent various real-world assets (RWA) that can be insured
 */

export interface TokenInfo {
  symbol: string;
  name: string;
  address: string;
  decimals: number;
  category: string;
  description: string;
}

// Import database functions
import {
  getAllTokens,
  getTokenByAddress as getTokenByAddressDb,
  getTokenBySymbol as getTokenBySymbolDb,
  isValidTokenAddress as isValidTokenAddressDb
} from '../lib/token-db';

// Example token addresses for Flare Testnet (used only for seeding)
export const FLARE_TESTNET_TOKENS: TokenInfo[] = [
  {
    symbol: "REAL",
    name: "Real Estate Token",
    address: "0x2D2acD205bd6d9D0BACCa14bfd1fAfFc1E6C144f",
    decimals: 18,
    category: "Real Estate",
    description: "Tokenized real estate property representing commercial buildings"
  },
  {
    symbol: "COMM",
    name: "Commodity Token",
    address: "0x0F9Dd53E2dB1825B8C40b8AA31F4c6b1b6c81d2E",
    decimals: 18,
    category: "Commodities",
    description: "Tokenized gold and silver reserves"
  },
  {
    symbol: "CRED",
    name: "Credit Token",
    address: "0x3Ee7094DADda15810F191DD6AcF7E4FFa37571e4",
    decimals: 18,
    category: "Credit",
    description: "Tokenized corporate bonds and credit instruments"
  },
  {
    symbol: "INFR",
    name: "Infrastructure Token",
    address: "0x19a6304a0CF45187A5Bd6EdE94E6d146d8aDc06C",
    decimals: 18,
    category: "Infrastructure",
    description: "Tokenized infrastructure projects like roads and utilities"
  },
  {
    symbol: "AGRI",
    name: "Agriculture Token",
    address: "0x3dAB4506BcFCaFc556d2EA245B4D6621A6Cba61A",
    decimals: 18,
    category: "Agriculture",
    description: "Tokenized agricultural assets and farmland"
  },
  {
    symbol: "CARB",
    name: "Carbon Credit Token",
    address: "0x1D80c49BbBCd1C0911346656B7DFadfc0564c62b",
    decimals: 18,
    category: "Environmental",
    description: "Tokenized carbon credits and environmental assets"
  },
  {
    symbol: "ART",
    name: "Art Token",
    address: "0x02f0826ef76a43f4c5e544aabf88b65fa34907c0",
    decimals: 18,
    category: "Art",
    description: "Tokenized fine art and collectibles"
  }
];

// Stablecoins for settlement
export const STABLECOINS: TokenInfo[] = [
  {
    symbol: "USDT",
    name: "Tether USD",
    address: "0x0F9Dd53E2dB1825B8C40b8AA31F4c6b1b6c81d2E",
    decimals: 6,
    category: "Stablecoin",
    description: "USDT used for claim settlements"
  },
  {
    symbol: "USDC",
    name: "USD Coin",
    address: "0x2D2acD205bd6d9D0BACCa14bfd1fAfFc1E6C144f",
    decimals: 6,
    category: "Stablecoin",
    description: "USDC alternative for claim settlements"
  }
];

// BSD token (platform token)
export const BSD_TOKEN: TokenInfo = {
  symbol: "BSD",
  name: "Backed Stable Digital Token",
  address: "0x0000000000000000000000000000000000000000", // Replace with actual address
  decimals: 18,
  category: "Platform Token",
  description: "The primary token of the BSD Insurance Protocol, used for premiums and governance"
};

// Function to update the BSD token address
export const updateBSDTokenAddress = (address: string): void => {
  const bsdTokenIndex = FLARE_TESTNET_TOKENS.findIndex(token => token.symbol === "BSD");
  if (bsdTokenIndex !== -1) {
    FLARE_TESTNET_TOKENS[bsdTokenIndex].address = address;
  }
};

// Function to get all tokens from database
export const getFlareTestnetTokens = async (): Promise<TokenInfo[]> => {
  return await getAllTokens();
};

// Function to get token by address
export const getTokenByAddress = async (address: string): Promise<TokenInfo | null> => {
  return await getTokenByAddressDb(address);
};

// Function to get token by symbol
export const getTokenBySymbol = async (symbol: string): Promise<TokenInfo | null> => {
  return await getTokenBySymbolDb(symbol);
};

// Function to validate if an address is a valid token address
export const isValidTokenAddress = async (address: string): Promise<boolean> => {
  return await isValidTokenAddressDb(address);
}; 