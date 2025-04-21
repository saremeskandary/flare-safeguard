import { useState, useCallback } from "react";
import { useAccount } from "wagmi";
import { notification } from "~~/components/scaffold-eth";

interface ContractInteractionOptions {
  contractName: string;
  functionName: string;
  args?: any[];
}

export const useContractInteraction = () => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { address } = useAccount();

  const readContract = useCallback(async ({ contractName, functionName, args = [] }: ContractInteractionOptions) => {
    try {
      setIsLoading(true);
      setError(null);

      const response = await fetch(`/api/contracts?contract=${contractName}&function=${functionName}&args=${JSON.stringify(args)}`);
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "Failed to read contract");
      }

      return data.data;
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "An error occurred";
      setError(errorMessage);
      notification.error(errorMessage);
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const writeContract = useCallback(async ({ contractName, functionName, args = [] }: ContractInteractionOptions) => {
    if (!address) {
      throw new Error("Please connect your wallet");
    }

    try {
      setIsLoading(true);
      setError(null);

      const response = await fetch("/api/contracts", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          contractName,
          functionName,
          args,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "Failed to write to contract");
      }

      notification.success("Transaction successful!");
      return data.data;
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "An error occurred";
      setError(errorMessage);
      notification.error(errorMessage);
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, [address]);

  return {
    readContract,
    writeContract,
    isLoading,
    error,
  };
}; 