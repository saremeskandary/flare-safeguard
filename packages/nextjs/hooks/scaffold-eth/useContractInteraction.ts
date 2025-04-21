import { useState, useCallback, useEffect } from "react";
import { useAccount } from "wagmi";

interface ContractInteractionOptions {
  contractName: string;
  functionName: string;
  args?: any[];
}

export const useContractInteraction = () => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const { address } = useAccount();

  // Clear messages after a delay
  useEffect(() => {
    let timer: NodeJS.Timeout;

    if (error || successMessage) {
      timer = setTimeout(() => {
        setError(null);
        setSuccessMessage(null);
      }, 5000); // Clear after 5 seconds
    }

    return () => {
      if (timer) clearTimeout(timer);
    };
  }, [error, successMessage]);

  const readContract = useCallback(async ({ contractName, functionName, args = [] }: ContractInteractionOptions) => {
    try {
      setIsLoading(true);
      setError(null);
      setSuccessMessage(null);

      const response = await fetch(`/api/contracts?contract=${contractName}&function=${functionName}&args=${JSON.stringify(args)}`);
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "Failed to read contract");
      }

      return data.data;
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "An error occurred";
      setError(errorMessage);
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const writeContract = useCallback(async ({ contractName, functionName, args = [] }: ContractInteractionOptions) => {
    if (!address) {
      const errorMessage = "Please connect your wallet";
      setError(errorMessage);
      return null;
    }

    try {
      setIsLoading(true);
      setError(null);
      setSuccessMessage(null);

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

      setSuccessMessage("Transaction successful!");
      return data.data;
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "An error occurred";
      setError(errorMessage);
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
    successMessage,
  };
}; 