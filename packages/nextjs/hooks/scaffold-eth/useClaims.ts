import { useScaffoldReadContract } from "./useScaffoldReadContract";
import { useAccount } from "wagmi";

export interface Claim {
  id: bigint;
  policyId: bigint;
  amount: bigint;
  claimDate: bigint;
  processedDate: bigint;
  processedBy: string;
  status: number; // 0: Pending, 1: Approved, 2: Rejected
  chainId: bigint;
  txHash: string;
  requiredConfirmations: bigint;
  verifiedBy: string;
}

export const useClaims = () => {
  const { address } = useAccount();
  const { data: claims, isLoading, error } = useScaffoldReadContract({
    contractName: "InsuranceCore",
    functionName: "getClaimsByUser",
    args: [address],
  });

  return {
    claims: claims as Claim[] | undefined,
    isLoading,
    error,
  };
}; 