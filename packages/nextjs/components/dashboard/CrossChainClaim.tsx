import { useState } from "react";
import { useTheme } from "next-themes";
import { useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { useAccount } from "wagmi";

interface Policy {
    coverageAmount: bigint;
    premium: bigint;
    duration: bigint;
    active: boolean;
}

export const CrossChainClaim = () => {
    const { theme } = useTheme();
    const { address } = useAccount();
    const [txHash, setTxHash] = useState("");
    const [chainId, setChainId] = useState("");
    const [claimAmount, setClaimAmount] = useState("");
    const [requiredConfirmations, setRequiredConfirmations] = useState("12");

    // Get policy for the current user
    const { data: policy } = useScaffoldReadContract({
        contractName: "InsuranceCore",
        functionName: "getCoverageOption",
        args: [BigInt(0)], // Get the first coverage option
    });

    const { writeContractAsync, isMining } = useScaffoldWriteContract({
        contractName: "InsuranceCore",
    });

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!chainId || !txHash || !claimAmount || !requiredConfirmations) {
            alert("Please fill in all fields");
            return;
        }

        try {
            await writeContractAsync({
                functionName: "evaluateRWA",
                args: [
                    `0x${txHash.replace(/^0x/, '')}`, // Use txHash as token address
                    BigInt(claimAmount),
                    BigInt(requiredConfirmations)
                ],
            });

            // Reset form
            setTxHash("");
            setChainId("");
            setClaimAmount("");
            setRequiredConfirmations("12");
        } catch (error) {
            console.error("Error submitting claim:", error);
            alert("Failed to submit claim. Please try again.");
        }
    };

    return (
        <div className={`p-6 rounded-lg ${theme === "dark" ? "bg-gray-800" : "bg-white"}`}>
            <h2 className={`text-2xl font-bold mb-6 ${theme === "dark" ? "text-white" : "text-gray-900"}`}>
                Submit Cross-Chain Claim
            </h2>
            {policy ? (
                <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                        <label className={`block mb-2 ${theme === "dark" ? "text-gray-300" : "text-gray-700"}`}>
                            Transaction Hash
                        </label>
                        <input
                            type="text"
                            value={txHash}
                            onChange={e => setTxHash(e.target.value)}
                            placeholder="0x..."
                            className="w-full p-2 border rounded"
                            required
                        />
                    </div>
                    <div>
                        <label className={`block mb-2 ${theme === "dark" ? "text-gray-300" : "text-gray-700"}`}>
                            Chain ID
                        </label>
                        <input
                            type="text"
                            value={chainId}
                            onChange={e => setChainId(e.target.value)}
                            placeholder="e.g. 11155111 for Sepolia"
                            className="w-full p-2 border rounded"
                            required
                        />
                    </div>
                    <div>
                        <label className={`block mb-2 ${theme === "dark" ? "text-gray-300" : "text-gray-700"}`}>
                            Claim Amount
                        </label>
                        <input
                            type="text"
                            value={claimAmount}
                            onChange={e => setClaimAmount(e.target.value)}
                            placeholder="Amount in wei"
                            className="w-full p-2 border rounded"
                            required
                        />
                    </div>
                    <div>
                        <label className={`block mb-2 ${theme === "dark" ? "text-gray-300" : "text-gray-700"}`}>
                            Required Confirmations
                        </label>
                        <input
                            type="number"
                            value={requiredConfirmations}
                            onChange={e => setRequiredConfirmations(e.target.value)}
                            min="1"
                            className="w-full p-2 border rounded"
                            required
                        />
                    </div>
                    <button
                        type="submit"
                        disabled={isMining}
                        className={`w-full p-3 text-white rounded ${isMining
                            ? "bg-gray-400"
                            : theme === "dark"
                                ? "bg-blue-600 hover:bg-blue-700"
                                : "bg-blue-500 hover:bg-blue-600"
                            }`}
                    >
                        {isMining ? "Submitting..." : "Submit Claim"}
                    </button>
                </form>
            ) : (
                <div className={`text-center py-8 ${theme === "dark" ? "text-gray-300" : "text-gray-700"}`}>
                    No active policy found. Please create a policy first.
                </div>
            )}
        </div>
    );
}; 