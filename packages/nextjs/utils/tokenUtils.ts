import { getContract } from "wagmi/actions";
import { erc20ABI } from "wagmi";

// Standard ERC20 ABI for name, symbol, and decimals
const ERC20_ABI = [
  {
    constant: true,
    inputs: [],
    name: "name",
    outputs: [{ name: "", type: "string" }],
    type: "function",
  },
  {
    constant: true,
    inputs: [],
    name: "symbol",
    outputs: [{ name: "", type: "string" }],
    type: "function",
  },
  {
    constant: true,
    inputs: [],
    name: "decimals",
    outputs: [{ name: "", type: "uint8" }],
    type: "function",
  },
];

/**
 * Fetches token information from the blockchain
 * @param address Token contract address
 * @returns Token information or null if not found
 */
export const fetchTokenInfo = async (address: string): Promise<{
  name: string;
  symbol: string;
  decimals: number;
} | null> => {
  try {
    // Create contract instance
    const contract = getContract({
      address: address as `0x${string}`,
      abi: ERC20_ABI,
      publicClient: {
        chain: {
          id: 114, // Flare Testnet
          name: "Flare Testnet",
          network: "flare-testnet",
          nativeCurrency: {
            name: "Flare",
            symbol: "FLR",
            decimals: 18,
          },
          rpcUrls: {
            default: {
              http: ["https://flare-testnet.publicnode.com"],
            },
            public: {
              http: ["https://flare-testnet.publicnode.com"],
            },
          },
        },
      },
    });

    // Fetch token information
    const [name, symbol, decimals] = await Promise.all([
      contract.read.name(),
      contract.read.symbol(),
      contract.read.decimals(),
    ]);

    return {
      name,
      symbol,
      decimals: Number(decimals),
    };
  } catch (error) {
    console.error("Error fetching token info:", error);
    return null;
  }
};

/**
 * Validates if an address is a valid ERC20 token
 * @param address Token contract address
 * @returns True if valid, false otherwise
 */
export const isValidERC20Token = async (address: string): Promise<boolean> => {
  try {
    const tokenInfo = await fetchTokenInfo(address);
    return tokenInfo !== null;
  } catch (error) {
    console.error("Error validating token:", error);
    return false;
  }
}; 