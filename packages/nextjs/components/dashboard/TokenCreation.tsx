"use client";

import { useState } from "react";
import { useScaffoldWriteContract, useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { useAccount } from "wagmi";
import { TOKEN_RWA_FACTORY_ADMIN_ROLE } from "~~/utils/contractConstants";

export const TokenCreation = () => {
    const [tokenName, setTokenName] = useState("");
    const [tokenSymbol, setTokenSymbol] = useState("");
    const [isCreating, setIsCreating] = useState(false);
    const [error, setError] = useState("");
    const [success, setSuccess] = useState("");
    const { address } = useAccount();

    // Check if the current user has the ADMIN_ROLE
    const { data: hasAdminRole } = useScaffoldReadContract({
        contractName: "TokenRWAFactory",
        functionName: "hasRole",
        args: [TOKEN_RWA_FACTORY_ADMIN_ROLE, address],
    });

    // Use the recommended object parameter version
    const { writeContractAsync } = useScaffoldWriteContract({
        contractName: "TokenRWAFactory",
    });

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError("");
        setSuccess("");

        if (!tokenName || !tokenSymbol) {
            setError("Please fill in all fields");
            return;
        }

        try {
            setIsCreating(true);

            // Call the contract with the correct parameters
            const tx = await writeContractAsync({
                functionName: "createToken",
                args: [tokenName, tokenSymbol],
            });

            if (tx) {
                // Wait for transaction to be mined
                await new Promise(resolve => setTimeout(resolve, 5000)); // Wait for 5 seconds
                setSuccess("Token created successfully!");
                setTokenName("");
                setTokenSymbol("");
            }
        } catch (error) {
            console.error("Error creating token:", error);
            setError("Failed to create token. Please try again.");
        } finally {
            setIsCreating(false);
        }
    };

    return (
        <div className="flex flex-col gap-6 p-6 bg-base-200 rounded-lg">
            <h2 className="text-2xl font-bold">Create New RWA Token</h2>
            {error && (
                <div className="alert alert-error">
                    <span>{error}</span>
                </div>
            )}
            {success && (
                <div className="alert alert-success">
                    <span>{success}</span>
                </div>
            )}
            {hasAdminRole === false && (
                <div className="alert alert-warning">
                    <span>You don't have permission to create tokens. You need the ADMIN_ROLE.</span>
                </div>
            )}
            <form onSubmit={handleSubmit} className="flex flex-col gap-4">
                <div className="form-control">
                    <label className="label">
                        <span className="label-text">Token Name</span>
                    </label>
                    <input
                        type="text"
                        placeholder="Enter token name"
                        className="input input-bordered w-full"
                        value={tokenName}
                        onChange={e => setTokenName(e.target.value)}
                        disabled={isCreating || hasAdminRole === false}
                    />
                </div>
                <div className="form-control">
                    <label className="label">
                        <span className="label-text">Token Symbol</span>
                    </label>
                    <input
                        type="text"
                        placeholder="Enter token symbol"
                        className="input input-bordered w-full"
                        value={tokenSymbol}
                        onChange={e => setTokenSymbol(e.target.value)}
                        disabled={isCreating || hasAdminRole === false}
                    />
                </div>
                <button
                    type="submit"
                    className={`btn btn-primary ${isCreating ? "loading" : ""}`}
                    disabled={isCreating || hasAdminRole === false}
                >
                    {isCreating ? "Creating Token..." : "Create Token"}
                </button>
            </form>
        </div>
    );
};