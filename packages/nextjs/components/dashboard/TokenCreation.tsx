"use client";

import { useState } from "react";
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { toast } from "react-hot-toast";

const TokenCreation = () => {
    const { address } = useAccount();
    const [tokenName, setTokenName] = useState("");
    const [tokenSymbol, setTokenSymbol] = useState("");
    const [verificationAddress, setVerificationAddress] = useState("");
    const [isLoading, setIsLoading] = useState(false);

    const { writeContract, data: hash } = useWriteContract();

    const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
        hash,
    });

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!address) {
            toast.error("Please connect your wallet first");
            return;
        }

        try {
            setIsLoading(true);
            await writeContract({
                address: process.env.NEXT_PUBLIC_TOKEN_RWA_ADDRESS as `0x${string}`,
                abi: [
                    {
                        inputs: [
                            { name: "name", type: "string" },
                            { name: "symbol", type: "string" },
                            { name: "verificationAddress", type: "address" }
                        ],
                        name: "constructor",
                        stateMutability: "nonpayable",
                        type: "constructor"
                    }
                ],
                functionName: "constructor",
                args: [tokenName, tokenSymbol, verificationAddress as `0x${string}`],
            });
            toast.success("Token creation initiated!");
        } catch (error) {
            console.error("Error creating token:", error);
            toast.error("Failed to create token");
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="flex flex-col gap-6 p-6 rounded-lg">
            <h2 className="text-2xl font-bold">Create RWA Token</h2>
            <form onSubmit={handleSubmit} className="flex flex-col gap-4">
                <div className="form-control">
                    <label className="label">
                        <span className="label-text">Token Name</span>
                    </label>
                    <input
                        type="text"
                        placeholder="Enter token name"
                        className="input input-bordered w-full bg-base-200"
                        value={tokenName}
                        onChange={(e) => setTokenName(e.target.value)}
                        required
                    />
                </div>

                <div className="form-control">
                    <label className="label">
                        <span className="label-text">Token Symbol</span>
                    </label>
                    <input
                        type="text"
                        placeholder="Enter token symbol"
                        className="input input-bordered w-full bg-base-200"
                        value={tokenSymbol}
                        onChange={(e) => setTokenSymbol(e.target.value)}
                        required
                    />
                </div>

                <div className="form-control">
                    <label className="label">
                        <span className="label-text">Verification Address</span>
                    </label>
                    <input
                        type="text"
                        placeholder="Enter verification contract address"
                        className="input input-bordered w-full bg-base-200"
                        value={verificationAddress}
                        onChange={(e) => setVerificationAddress(e.target.value)}
                        required
                    />
                </div>

                <button
                    type="submit"
                    className={`btn btn-primary ${isLoading || isConfirming ? "loading" : ""}`}
                    disabled={isLoading || isConfirming}
                >
                    {isLoading ? "Creating Token..." : isConfirming ? "Confirming..." : "Create Token"}
                </button>

                {isConfirmed && (
                    <div className="alert alert-success">
                        <span>Token created successfully!</span>
                    </div>
                )}
            </form>
        </div>
    );
};

export default TokenCreation; 