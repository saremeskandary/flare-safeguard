import { useState } from "react";
import { useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";

export const CrossChainClaim = () => {
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
        <div className={`p-6 rounded-lg border border-base-300`}>
            <h2 className={`text-2xl font-bold mb-6`}>
                Submit Cross-Chain Claim
            </h2>
            {policy ? (
                <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                        <label className={`block mb-2 `}>
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
                        <label className={`block mb-2`}>
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
                        <label className={`block mb-2 `}>
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
                        <label className={`block mb-2 `}>
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
                            ? "bg-base-200"
                            : "bg-primary hover:bg-primary-content"
                            }`}
                    >
                        {isMining ? "Submitting..." : "Submit Claim"}
                    </button>
                </form>
            ) : (
                <div className={`text-center py-8`}>
                    No active policy found. Please create a policy first.
                </div>
            )}
        </div>
    );
}; 