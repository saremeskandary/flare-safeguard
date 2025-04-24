"use client";
import { useState, useEffect } from "react";
import { useScaffoldReadContract, useScaffoldContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { useAccount } from "wagmi";

interface Claim {
    id: number;
    policyId: number;
    claimant: string;
    amount: bigint;
    status: number; // 0: Pending, 1: UnderReview, 2: Approved, 3: Rejected, 4: Paid
    proof: string;
    verifiedBy: string;
    requiredConfirmations: number;
    rejectionReason?: string;
}

type ClaimResult = [bigint, bigint, bigint, bigint, number, string, string, number];

export const ClaimVerification = () => {
    const { address } = useAccount();
    const [pendingClaims, setPendingClaims] = useState<Claim[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [selectedClaim, setSelectedClaim] = useState<Claim | null>(null);
    const [rejectionReason, setRejectionReason] = useState("");
    const [isProcessing, setIsProcessing] = useState(false);

    // Get the contract instance
    const { data: claimProcessorContract } = useScaffoldContract({
        contractName: "ClaimProcessor",
    });

    // Get all claims
    const { data: claimCount, isLoading: isLoadingCount } = useScaffoldReadContract({
        contractName: "ClaimProcessor",
        functionName: "claimCount",
    });

    // Fetch pending claims
    useEffect(() => {
        const fetchPendingClaims = async () => {
            if (!claimCount || !claimProcessorContract) return;

            try {
                const claims: Claim[] = [];
                for (let i = 0; i < Number(claimCount); i++) {
                    // Use the contract directly instead of the hook
                    const claimId = BigInt(i);
                    const result = await claimProcessorContract.read.getClaim([claimId]);

                    if (result) {
                        const claim = {
                            id: Number(result[0]),
                            policyId: Number(result[1]),
                            claimant: result[2].toString(),
                            amount: result[3],
                            status: Number(result[4]),
                            proof: result[5].toString(),
                            verifiedBy: result[6],
                            requiredConfirmations: Number(result[7]),
                            rejectionReason: undefined,
                        };

                        // Only include claims that are pending or under review
                        if (claim.status === 0 || claim.status === 1) {
                            claims.push(claim);
                        }
                    }
                }
                setPendingClaims(claims);
            } catch (err) {
                setError(err instanceof Error ? err.message : "Failed to fetch claims");
            } finally {
                setIsLoading(false);
            }
        };

        fetchPendingClaims();
    }, [claimCount, claimProcessorContract, address]);

    const { writeContractAsync } = useScaffoldWriteContract({
        contractName: "ClaimProcessor",
    });

    const handleVerifyClaim = async (claim: Claim) => {
        if (!claimProcessorContract) return;
        setIsProcessing(true);
        try {
            await writeContractAsync({
                functionName: "reviewClaim",
                args: [BigInt(claim.id), true, ""],
            });
            // Refresh claims after verification
            setPendingClaims(prevClaims => prevClaims.filter(c => c.id !== claim.id));
        } catch (err) {
            setError(err instanceof Error ? err.message : "Failed to verify claim");
        } finally {
            setIsProcessing(false);
        }
    };

    const handleRejectClaim = async (claim: Claim) => {
        if (!claimProcessorContract || !rejectionReason) return;
        setIsProcessing(true);
        try {
            await writeContractAsync({
                functionName: "reviewClaim",
                args: [BigInt(claim.id), false, rejectionReason],
            });
            // Refresh claims after rejection
            setPendingClaims(prevClaims => prevClaims.filter(c => c.id !== claim.id));
            setSelectedClaim(null);
            setRejectionReason("");
        } catch (err) {
            setError(err instanceof Error ? err.message : "Failed to reject claim");
        } finally {
            setIsProcessing(false);
        }
    };

    if (isLoading || isLoadingCount) {
        return (
            <div className="flex justify-center items-center h-64">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="text-center text-red-500 p-4">
                <p>Error: {error}</p>
            </div>
        );
    }

    if (!pendingClaims || pendingClaims.length === 0) {
        return (
            <div className="text-center text-gray-500 p-4">
                <p>No pending claims found</p>
            </div>
        );
    }

    return (
        <div className="space-y-4">
            <h2 className="text-2xl font-bold mb-4">Pending Claims</h2>
            <div className="grid gap-4">
                {pendingClaims.map((claim) => (
                    <div
                        key={claim.id}
                        className="bg-base-100 p-4 rounded-lg shadow-md border border-base-300"
                    >
                        <div className="flex justify-between items-start mb-2">
                            <div>
                                <h3 className="text-lg font-semibold">Claim #{claim.id}</h3>
                                <p className="text-sm text-base-content/60">
                                    Policy ID: {claim.policyId}
                                </p>
                            </div>
                            <div className="flex gap-2">
                                <button
                                    className="btn btn-sm btn-success"
                                    onClick={() => handleVerifyClaim(claim)}
                                    disabled={isProcessing}
                                >
                                    Verify
                                </button>
                                <button
                                    className="btn btn-sm btn-error"
                                    onClick={() => setSelectedClaim(claim)}
                                    disabled={isProcessing}
                                >
                                    Reject
                                </button>
                            </div>
                        </div>
                        <div className="space-y-2">
                            <p>
                                <span className="font-medium">Amount:</span>{" "}
                                {claim.amount.toString()} wei
                            </p>
                            <p>
                                <span className="font-medium">Proof:</span>{" "}
                                {claim.proof}
                            </p>
                            <p>
                                <span className="font-medium">Required confirmations:</span>{" "}
                                {claim.requiredConfirmations}
                            </p>
                        </div>
                    </div>
                ))}
            </div>

            {/* Rejection Modal */}
            {selectedClaim && (
                <div className="modal modal-open">
                    <div className="modal-box">
                        <h3 className="font-bold text-lg mb-4">Reject Claim #{selectedClaim.id}</h3>
                        <div className="form-control">
                            <label className="label">
                                <span className="label-text">Rejection Reason</span>
                            </label>
                            <textarea
                                className="textarea textarea-bordered"
                                value={rejectionReason}
                                onChange={(e) => setRejectionReason(e.target.value)}
                                placeholder="Enter reason for rejection"
                            />
                        </div>
                        <div className="modal-action">
                            <button
                                className="btn btn-error"
                                onClick={() => handleRejectClaim(selectedClaim)}
                                disabled={!rejectionReason || isProcessing}
                            >
                                Reject Claim
                            </button>
                            <button
                                className="btn"
                                onClick={() => {
                                    setSelectedClaim(null);
                                    setRejectionReason("");
                                }}
                            >
                                Cancel
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}; 