"use client";

import { useState } from "react";
import { useAccount } from "wagmi";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { toast } from "react-hot-toast";

const TokenCreation = () => {
    const [tokenName, setTokenName] = useState("");
    const [tokenSymbol, setTokenSymbol] = useState("");
    const [verificationAddress, setVerificationAddress] = useState<`0x${string}` | undefined>();
    const [isDeployingVerification, setIsDeployingVerification] = useState(false);
    const { address } = useAccount();

    const { writeContractAsync: writeTokenContractAsync } = useScaffoldWriteContract({
        contractName: "MockBSDToken",
    });

    const deployDataVerification = async () => {
        if (!address) {
            toast.error("Please connect your wallet first");
            return;
        }

        try {
            setIsDeployingVerification(true);
            const result = await writeTokenContractAsync({
                functionName: "mint",
                args: [address, BigInt(0)],
            });

            if (result) {
                setVerificationAddress(result as `0x${string}`);
                toast.success("Verification contract deployed successfully!");
            }
        } catch (error) {
            console.error("Error deploying verification contract:", error);
            toast.error("Failed to deploy verification contract");
        } finally {
            setIsDeployingVerification(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!address) {
            toast.error("Please connect your wallet first");
            return;
        }
        if (!verificationAddress) {
            toast.error("Please deploy or provide a verification contract address");
            return;
        }

        try {
            const result = await writeTokenContractAsync({
                functionName: "mint",
                args: [address, BigInt(0)],
            });

            if (result) {
                toast.success("Token creation initiated!");
            }
        } catch (error) {
            console.error("Error creating token:", error);
            toast.error("Failed to create token");
        }
    };

    return (
        <div className="max-w-2xl mx-auto p-6">
            <h2 className="text-2xl font-bold mb-6">Create New Token</h2>
            <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                    <label className="block text-sm font-medium mb-1">Token Name</label>
                    <input
                        type="text"
                        value={tokenName}
                        onChange={(e) => setTokenName(e.target.value)}
                        className="w-full p-2 border rounded"
                        placeholder="Enter token name"
                    />
                </div>
                <div>
                    <label className="block text-sm font-medium mb-1">Token Symbol</label>
                    <input
                        type="text"
                        value={tokenSymbol}
                        onChange={(e) => setTokenSymbol(e.target.value)}
                        className="w-full p-2 border rounded"
                        placeholder="Enter token symbol"
                    />
                </div>
                <div>
                    <label className="block text-sm font-medium mb-1">Verification Address</label>
                    <div className="flex gap-2">
                        <input
                            type="text"
                            value={verificationAddress || ""}
                            onChange={(e) => setVerificationAddress(e.target.value as `0x${string}`)}
                            className="flex-1 p-2 border rounded"
                            placeholder="Enter verification contract address"
                        />
                        <button
                            type="button"
                            onClick={deployDataVerification}
                            disabled={isDeployingVerification}
                            className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50"
                        >
                            {isDeployingVerification ? "Deploying..." : "Deploy New"}
                        </button>
                    </div>
                </div>
                <button
                    type="submit"
                    className="w-full py-2 bg-green-500 text-white rounded hover:bg-green-600"
                >
                    Create Token
                </button>
            </form>
        </div>
    );
};

export default TokenCreation;