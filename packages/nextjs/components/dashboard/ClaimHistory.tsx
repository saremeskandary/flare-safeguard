"use client";
import { useState, useEffect } from "react";
import { useScaffoldReadContract, useScaffoldContract } from "~~/hooks/scaffold-eth";
import { useAccount, usePublicClient } from "wagmi";

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

export const ClaimHistory = () => {
    const { address } = useAccount();
    const publicClient = usePublicClient();
    const [claims, setClaims] = useState<Claim[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    // Get the contract instance
    const { data: claimProcessorContract } = useScaffoldContract({
        contractName: "ClaimProcessor",
    });

    // First, get the user's claim IDs
    const { data: claimIds, isLoading: isLoadingIds } = useScaffoldReadContract({
        contractName: "ClaimProcessor",
        functionName: "getUserClaims",
        args: [address],
    }) as { data: bigint[] | undefined; isLoading: boolean };

    // Then, fetch each claim's details
    useEffect(() => {
        const fetchClaims = async () => {
            if (!claimIds || !Array.isArray(claimIds) || !claimProcessorContract || !publicClient) return;

            try {
                const claimPromises = claimIds.map(async (claimId: bigint) => {
                    // Use publicClient instead of hooks
                    const result = await publicClient.readContract({
                        address: claimProcessorContract.address,
                        abi: claimProcessorContract.abi,
                        functionName: "getClaim",
                        args: [claimId],
                    });
                    return result;
                });

                const claimResults = await Promise.all(claimPromises);
                // Convert the results to the Claim type
                const typedClaims = claimResults.map((result: any) => ({
                    id: Number(result[0]),
                    policyId: Number(result[1]),
                    claimant: result[1],
                    amount: result[2],
                    status: Number(result[3]),
                    proof: result[4],
                    verifiedBy: result[5],
                    requiredConfirmations: Number(result[6]),
                    rejectionReason: result[7],
                }));
                setClaims(typedClaims);
            } catch (err) {
                setError(err instanceof Error ? err.message : "Failed to fetch claims");
            } finally {
                setIsLoading(false);
            }
        };

        fetchClaims();
    }, [claimIds, claimProcessorContract, publicClient]);

    const getStatusText = (status: number): string => {
        switch (status) {
            case 0:
                return "Pending";
            case 1:
                return "Under Review";
            case 2:
                return "Approved";
            case 3:
                return "Rejected";
            case 4:
                return "Paid";
            default:
                return "Unknown";
        }
    };

    const getStatusStyles = (status: number): string => {
        switch (status) {
            case 0:
                return "bg-yellow-100 text-yellow-800";
            case 1:
                return "bg-blue-100 text-blue-800";
            case 2:
                return "bg-green-100 text-green-800";
            case 3:
                return "bg-red-100 text-red-800";
            case 4:
                return "bg-purple-100 text-purple-800";
            default:
                return "bg-gray-100 text-gray-800";
        }
    };

    if (isLoading || isLoadingIds) {
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

    if (!claims || claims.length === 0) {
        return (
            <div className="text-center text-gray-500 p-4">
                <p>No claims found</p>
            </div>
        );
    }

    return (
        <div className="space-y-4">
            <h2 className="text-2xl font-bold mb-4">Claim History</h2>
            <div className="grid gap-4">
                {claims.map((claim) => (
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
                            <span
                                className={`px-2 py-1 rounded-full text-sm ${getStatusStyles(
                                    claim.status,
                                )}`}
                            >
                                {getStatusText(claim.status)}
                            </span>
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
                            {claim.verifiedBy && (
                                <p>
                                    <span className="font-medium">Verified by:</span>{" "}
                                    {claim.verifiedBy}
                                </p>
                            )}
                            {claim.rejectionReason && (
                                <p>
                                    <span className="font-medium">Rejection reason:</span>{" "}
                                    {claim.rejectionReason}
                                </p>
                            )}
                            <p>
                                <span className="font-medium">Required confirmations:</span>{" "}
                                {claim.requiredConfirmations}
                            </p>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}; 