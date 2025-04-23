"use client";
import { useState } from "react";
import { useWriteContract } from "wagmi";
import { useDeployedContractInfo, useTransactor } from "~~/hooks/scaffold-eth";
import { TokenSelector } from "./TokenSelector";
import { TokenInfo } from "~~/utils/tokenAddresses";

interface InsuranceOption {
    id: string;
    name: string;
    value: number;
    premiumRate: number;
    description: string;
    tokenAddress?: string;
}

export const CreatePolicy = () => {
    const [newOption, setNewOption] = useState<InsuranceOption>({
        id: "",
        name: "",
        value: 0,
        premiumRate: 0,
        description: "",
        tokenAddress: "",
    });
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [success, setSuccess] = useState<string | null>(null);

    const { writeContractAsync } = useWriteContract();
    const { data: deployedContractData } = useDeployedContractInfo({ contractName: "InsuranceCore" });
    const writeTx = useTransactor();

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
        const { name, value } = e.target;
        setNewOption(prev => ({
            ...prev,
            [name]: name === "value" || name === "premiumRate" ? parseFloat(value) || 0 : value,
        }));
    };

    const handleTokenSelect = (token: TokenInfo) => {
        setNewOption(prev => ({
            ...prev,
            tokenAddress: token.address,
            id: token.symbol,
            name: token.name,
        }));
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsSubmitting(true);
        setError(null);
        setSuccess(null);

        try {
            // Validate token address
            if (!newOption.tokenAddress) {
                throw new Error("Please select a token");
            }

            // First, create the option in the database
            const response = await fetch("/api/insurance-options", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify(newOption),
            });

            if (!response.ok) {
                throw new Error("Failed to create insurance option");
            }

            // Then, create the option in the smart contract
            if (deployedContractData) {
                const writeContractAsyncWithParams = () =>
                    writeContractAsync({
                        address: deployedContractData.address,
                        abi: deployedContractData.abi,
                        functionName: "addCoverageOption",
                        args: [
                            BigInt(newOption.value),
                            BigInt(Math.floor(newOption.premiumRate * 100)), // Convert percentage to basis points
                            BigInt(180), // Minimum duration (6 months)
                            BigInt(1095), // Maximum duration (3 years)
                        ],
                    });

                await writeTx(writeContractAsyncWithParams, { blockConfirmations: 1 });
            }

            setSuccess("Insurance option created successfully!");
            setNewOption({
                id: "",
                name: "",
                value: 0,
                premiumRate: 0,
                description: "",
                tokenAddress: "",
            });
        } catch (err) {
            setError(err instanceof Error ? err.message : "Failed to create insurance option");
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <div className="space-y-6">
            <div className="p-6 rounded-lg border border-gray-200">
                <h2 className="text-xl font-semibold mb-6">Create Insurance Option</h2>

                {error && (
                    <div className="mb-4 p-4 rounded-lg bg-red-50 border border-red-200">
                        <p className="text-red-600">{error}</p>
                    </div>
                )}

                {success && (
                    <div className="mb-4 p-4 rounded-lg bg-green-50 border border-green-200">
                        <p className="text-green-600">{success}</p>
                    </div>
                )}

                <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                        <label htmlFor="tokenSelector" className="block text-sm font-medium text-gray-700 mb-1">
                            Select Token
                        </label>
                        <TokenSelector
                            onTokenSelect={handleTokenSelect}
                            selectedTokenAddress={newOption.tokenAddress}
                        />
                    </div>

                    <div>
                        <label htmlFor="value" className="block text-sm font-medium text-gray-700 mb-1">
                            Token Value (USD)
                        </label>
                        <input
                            type="number"
                            id="value"
                            name="value"
                            value={newOption.value}
                            onChange={handleInputChange}
                            className="w-full p-2 border border-gray-300 rounded-md focus:ring-primary focus:border-primary"
                            required
                            min="0"
                        />
                    </div>

                    <div>
                        <label htmlFor="premiumRate" className="block text-sm font-medium text-gray-700 mb-1">
                            Premium Rate (%)
                        </label>
                        <input
                            type="number"
                            id="premiumRate"
                            name="premiumRate"
                            value={newOption.premiumRate}
                            onChange={handleInputChange}
                            className="w-full p-2 border border-gray-300 rounded-md focus:ring-primary focus:border-primary"
                            required
                            min="0"
                            step="0.1"
                        />
                    </div>

                    <div>
                        <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-1">
                            Description
                        </label>
                        <textarea
                            id="description"
                            name="description"
                            value={newOption.description}
                            onChange={handleInputChange}
                            className="w-full p-2 border border-gray-300 rounded-md focus:ring-primary focus:border-primary"
                            rows={3}
                            required
                        />
                    </div>

                    <button
                        type="submit"
                        disabled={isSubmitting || !newOption.tokenAddress}
                        className="w-full inline-flex justify-center rounded-md border border-transparent bg-primary px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        {isSubmitting ? "Creating..." : "Create Insurance Option"}
                    </button>
                </form>
            </div>
        </div>
    );
}; 