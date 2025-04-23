"use client";

import { useState, useEffect } from "react";
import { usePolicies } from "~~/hooks/usePolicies";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { useAccount } from "wagmi";

export const PolicyDetails = () => {
    const { policies, isLoading, error } = usePolicies();
    const [policiesFromContract, setPoliciesFromContract] = useState<any[]>([]);
    const [errorFromContract, setErrorFromContract] = useState<string | null>(null);
    const [contractLoading, setContractLoading] = useState<boolean>(false);
    const { address } = useAccount();
    const { data: userClaimsResult, isLoading: isClaimsLoading } = useScaffoldReadContract({
        contractName: "ClaimProcessor",
        functionName: "getUserClaims",
        args: [address], // This should be the connected user's address
    });

    useEffect(() => {
        const fetchPoliciesFromContract = async () => {
            try {
                setContractLoading(true);
                // Ensure userClaims is an array
                const userClaims = Array.isArray(userClaimsResult) ? userClaimsResult : [];

                if (userClaims.length === 0) {
                    setPoliciesFromContract([]);
                    return;
                }

                // Fetch policy details for each claim
                const policyPromises = userClaims.map(async (claimId: bigint) => {
                    const { data: claimData } = await useScaffoldReadContract({
                        contractName: "ClaimProcessor",
                        functionName: "getClaim",
                        args: [claimId],
                    });

                    if (!claimData) return null;

                    const claim = claimData;

                    const { data: policyData } = await useScaffoldReadContract({
                        contractName: "ClaimProcessor",
                        functionName: "getPolicy",
                        args: [claim[0]],
                    });

                    if (!policyData) return null;

                    const policy = policyData;

                    return {
                        id: `POL-${claimId.toString()}`,
                        tokenId: policy[0],
                        tokenName: `Policy for ${policy[0].substring(0, 6)}...${policy[0].substring(policy[0].length - 4)}`,
                        coverageAmount: policy[1],
                        premiumAmount: policy[2],
                        startDate: new Date(Number(policy[3]) * 1000),
                        endDate: new Date(Number(policy[4]) * 1000),
                        status: policy[5] ? "Active" : "Expired",
                    };
                });

                const resolvedPolicies = await Promise.all(policyPromises);
                const validPolicies = resolvedPolicies.filter(policy => policy !== null);

                setPoliciesFromContract(validPolicies);
            } catch (err) {
                console.error("Error fetching policies from contract:", err);
                setErrorFromContract(err instanceof Error ? err.message : "Failed to fetch policies from contract");
            } finally {
                setContractLoading(false);
            }
        };

        if (userClaimsResult) {
            fetchPoliciesFromContract();
        }
    }, [userClaimsResult]);

    const formatDate = (date: Date) => {
        return date.toLocaleDateString("en-US", {
            year: "numeric",
            month: "short",
            day: "numeric",
        });
    };

    const calculateRemainingDays = (endDate: Date) => {
        try {
            const now = new Date();
            const diffTime = endDate.getTime() - now.getTime();
            const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
            return diffDays;
        } catch (error) {
            console.error('Error calculating remaining days:', error);
            return 0;
        }
    };

    if (isLoading || contractLoading || isClaimsLoading) {
        return (
            <div className="p-6 rounded-xl border border-gray-100 bg-base-200/50 backdrop-blur-sm shadow-sm flex justify-center items-center h-40">
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
            </div>
        );
    }

    if (error || errorFromContract) {
        return (
            <div className="p-6 rounded-xl border border-red-200 bg-red-50/50 backdrop-blur-sm shadow-sm">
                <h2 className="text-xl font-semibold mb-4 text-red-700">Error</h2>
                <p className="text-red-600">{error || errorFromContract}</p>
            </div>
        );
    }

    // Combine policies from database and contract
    const allPolicies = [...policies, ...policiesFromContract];

    if (allPolicies.length === 0) {
        return (
            <div className="p-8 rounded-xl border border-gray-100 bg-base-200/50 backdrop-blur-sm shadow-sm">
                <h2 className="text-xl font-semibold mb-4">Your Policies</h2>
                <p className="text-gray-500">You don&apos;t have any insurance policies.</p>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            <div className="p-6 rounded-lg border border-gray-200">
                <h2 className="text-xl font-semibold mb-6">My Policies</h2>

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {allPolicies.map(policy => (
                        <div key={policy.id} className="p-4 rounded-lg border border-gray-200 max-w-96">
                            <div className="flex justify-between items-start mb-2">
                                <div>
                                    <h3 className="font-semibold">{policy.tokenName}</h3>
                                    <p className="text-sm text-gray-500">Policy ID: {policy.id}</p>
                                </div>
                                <span className={`px-2 py-1 rounded-full text-xs font-medium ${policy.status === "Active" ? "bg-green-100 text-green-800" : "bg-gray-100 text-gray-800"
                                    }`}>
                                    {policy.status}
                                </span>
                            </div>

                            <div className="grid grid-cols-2 gap-4 mt-4">
                                <div>
                                    <h4 className="text-sm font-medium text-gray-500">Coverage Amount</h4>
                                    <p className="mt-1">${policy.coverageAmount?.toString() || '0'}</p>
                                </div>
                                <div>
                                    <h4 className="text-sm font-medium text-gray-500">Premium Amount</h4>
                                    <p className="mt-1">${policy.premiumAmount?.toString() || '0'}</p>
                                </div>
                                <div>
                                    <h4 className="text-sm font-medium text-gray-500">Remaining Days</h4>
                                    <p className="mt-1">{calculateRemainingDays(new Date(policy.endDate))} days</p>
                                </div>
                                <div>
                                    <h4 className="text-sm font-medium text-gray-500">Start Date</h4>
                                    <p className="mt-1">{formatDate(new Date(policy.startDate))}</p>
                                </div>
                                <div>
                                    <h4 className="text-sm font-medium text-gray-500">End Date</h4>
                                    <p className="mt-1">{formatDate(new Date(policy.endDate))}</p>
                                </div>
                            </div>

                            <div className="mt-4 pt-4 border-t border-gray-200">
                                <div className="flex justify-between items-center">
                                    <div className="text-sm">
                                        <span className="text-gray-500">Policy Progress:</span>
                                        <div className="w-full bg-gray-200 rounded-full h-2.5 mt-1">
                                            <div
                                                className="bg-primary h-2.5 rounded-full"
                                                style={{
                                                    width: `${Math.min(100, Math.max(0, (1 - calculateRemainingDays(new Date(policy.endDate)) / 365) * 100))}%`
                                                }}
                                            ></div>
                                        </div>
                                    </div>
                                    <button className="text-sm text-primary hover:text-primary/80 font-medium">
                                        View Details
                                    </button>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
}; 