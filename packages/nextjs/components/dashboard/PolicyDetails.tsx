"use client";

import { useState, useEffect } from "react";
import { usePolicies } from "~~/hooks/usePolicies";
import { useScaffoldReadContract, useScaffoldWriteContract, useScaffoldContract } from "~~/hooks/scaffold-eth";
import { useAccount } from "wagmi";
import { TokenSelector } from "./TokenSelector";
import { TokenInfo } from "~~/utils/tokenAddresses";

interface Policy {
    id: string;
    tokenId: string;
    tokenName: string;
    coverageAmount: number;
    premiumAmount: number;
    startDate: Date;
    endDate: Date;
    status: string;
    remainingCoverage?: number;
}

interface PolicyWithCoverage extends Policy {
    remainingCoverage?: number;
}

export const PolicyDetails = () => {
    const { policies, isLoading, error } = usePolicies();
    const [policiesFromContract, setPoliciesFromContract] = useState<PolicyWithCoverage[]>([]);
    const [errorFromContract, setErrorFromContract] = useState<string | null>(null);
    const [contractLoading, setContractLoading] = useState<boolean>(false);
    const [selectedPolicy, setSelectedPolicy] = useState<PolicyWithCoverage | null>(null);
    const [isRenewing, setIsRenewing] = useState(false);
    const [isCancelling, setIsCancelling] = useState(false);
    const [renewalDuration, setRenewalDuration] = useState<number>(180); // Default to 6 months
    const [renewalToken, setRenewalToken] = useState<TokenInfo | null>(null);
    const { address } = useAccount();

    // Get the contract instance
    const { data: claimProcessorContract } = useScaffoldContract({
        contractName: "ClaimProcessor",
    });

    const { writeContractAsync: renewPolicyAsync } = useScaffoldWriteContract({
        contractName: "ClaimProcessor",
    });

    const { data: userClaimsResult, isLoading: isClaimsLoading } = useScaffoldReadContract({
        contractName: "ClaimProcessor",
        functionName: "getUserClaims",
        args: [address],
    });

    useEffect(() => {
        const fetchPoliciesFromContract = async () => {
            try {
                setContractLoading(true);
                const userClaims = Array.isArray(userClaimsResult) ? userClaimsResult : [];

                if (userClaims.length === 0) {
                    setPoliciesFromContract([]);
                    return;
                }

                const policyPromises = userClaims.map(async (claimId: bigint) => {
                    if (!claimProcessorContract) return null;

                    const claimData = await claimProcessorContract.read.getClaim([claimId]);

                    if (!claimData) return null;

                    const claim = claimData;
                    const policyData = await claimProcessorContract.read.getPolicy([claim[0]]);

                    if (!policyData) return null;

                    const policy = policyData;
                    const remainingCoverage = await claimProcessorContract.read.getPolicy([claim[0]]);

                    return {
                        id: `POL-${claimId.toString()}`,
                        tokenId: policy[0],
                        tokenName: `Policy for ${policy[0].substring(0, 6)}...${policy[0].substring(policy[0].length - 4)}`,
                        coverageAmount: Number(policy[1]),
                        premiumAmount: Number(policy[2]),
                        startDate: new Date(Number(policy[3]) * 1000),
                        endDate: new Date(Number(policy[4]) * 1000),
                        status: policy[5] ? "Active" : "Expired",
                        remainingCoverage: remainingCoverage ? Number(remainingCoverage[1]) : undefined,
                    } as PolicyWithCoverage;
                });

                const resolvedPolicies = await Promise.all(policyPromises);
                const validPolicies = resolvedPolicies.filter((policy): policy is PolicyWithCoverage => policy !== null);
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

    const handleRenewPolicy = async () => {
        if (!selectedPolicy || !renewalToken) return;

        try {
            setIsRenewing(true);
            await renewPolicyAsync({
                functionName: "createPolicy",
                args: [
                    renewalToken.address as `0x${string}`,
                    BigInt(selectedPolicy.coverageAmount),
                    BigInt(selectedPolicy.premiumAmount),
                    BigInt(renewalDuration) // Duration in days
                ] as const,
            });
            // Refresh policies after renewal
            window.location.reload();
        } catch (error) {
            console.error("Error renewing policy:", error);
        } finally {
            setIsRenewing(false);
            setSelectedPolicy(null);
        }
    };

    if (isLoading || contractLoading || isClaimsLoading) {
        return (
            <div className="p-6 rounded-xl border border-base-300 bg-base-200/50 backdrop-blur-sm shadow-sm flex justify-center items-center h-40">
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
            </div>
        );
    }

    if (error || errorFromContract) {
        return (
            <div className="p-6 rounded-xl border border-error bg-error/10 backdrop-blur-sm shadow-sm">
                <h2 className="text-xl font-semibold mb-4 text-error">Error</h2>
                <p className="text-error">{error || errorFromContract}</p>
            </div>
        );
    }

    const allPolicies = [...policies, ...policiesFromContract] as PolicyWithCoverage[];

    if (allPolicies.length === 0) {
        return (
            <div className="p-8 rounded-xl border border-base-300 bg-base-200/50 backdrop-blur-sm shadow-sm">
                <h2 className="text-xl font-semibold mb-4">Your Policies</h2>
                <p className="text-base-content/60">You don&apos;t have any insurance policies.</p>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            <div className="p-6 rounded-lg border border-base-300">
                <h2 className="text-xl font-semibold mb-6">My Policies</h2>

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {allPolicies.map(policy => (
                        <div key={policy.id} className="p-4 rounded-lg border border-base-300 max-w-96">
                            <div className="flex justify-between items-start mb-2">
                                <div>
                                    <h3 className="font-semibold">{policy.tokenName}</h3>
                                    <p className="text-sm text-base-content/60">Policy ID: {policy.id}</p>
                                </div>
                                <span className={`px-2 py-1 rounded-full text-xs font-medium ${policy.status === "Active"
                                    ? "bg-success/20 text-success"
                                    : "bg-base-content/20 text-base-content"
                                    }`}>
                                    {policy.status}
                                </span>
                            </div>

                            <div className="grid grid-cols-2 gap-4 mt-4">
                                <div>
                                    <h4 className="text-sm font-medium text-base-content/60">Coverage Amount</h4>
                                    <p className="mt-1">${policy.coverageAmount?.toString() || '0'}</p>
                                </div>
                                <div>
                                    <h4 className="text-sm font-medium text-base-content/60">Premium Amount</h4>
                                    <p className="mt-1">${policy.premiumAmount?.toString() || '0'}</p>
                                </div>
                                <div>
                                    <h4 className="text-sm font-medium text-base-content/60">Remaining Coverage</h4>
                                    <p className="mt-1">${policy.remainingCoverage?.toString() || '0'}</p>
                                </div>
                                <div>
                                    <h4 className="text-sm font-medium text-base-content/60">Remaining Days</h4>
                                    <p className="mt-1">{calculateRemainingDays(new Date(policy.endDate))} days</p>
                                </div>
                                <div>
                                    <h4 className="text-sm font-medium text-base-content/60">Start Date</h4>
                                    <p className="mt-1">{formatDate(new Date(policy.startDate))}</p>
                                </div>
                                <div>
                                    <h4 className="text-sm font-medium text-base-content/60">End Date</h4>
                                    <p className="mt-1">{formatDate(new Date(policy.endDate))}</p>
                                </div>
                            </div>

                            <div className="mt-4 pt-4 border-t border-base-300">
                                <div className="flex justify-between items-center">
                                    <div className="text-sm">
                                        <span className="text-base-content/60">Policy Progress:</span>
                                        <div className="w-full bg-base-200 rounded-full h-2.5 mt-1">
                                            <div
                                                className="bg-primary h-2.5 rounded-full"
                                                style={{
                                                    width: `${Math.min(100, Math.max(0, (1 - calculateRemainingDays(new Date(policy.endDate)) / 365) * 100))}%`
                                                }}
                                            ></div>
                                        </div>
                                    </div>
                                    <div className="flex gap-2">
                                        <button
                                            onClick={() => setSelectedPolicy(policy)}
                                            className="btn btn-sm btn-primary"
                                        >
                                            Renew
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            {/* Renewal Modal */}
            {selectedPolicy && !isCancelling && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center">
                    <div className="bg-base-100 p-6 rounded-lg max-w-md w-full">
                        <h3 className="text-lg font-semibold mb-4">Renew Policy</h3>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium mb-1">
                                    Renewal Duration
                                </label>
                                <select
                                    value={renewalDuration}
                                    onChange={e => setRenewalDuration(Number(e.target.value))}
                                    className="select select-bordered w-full"
                                >
                                    <option value={180}>6 months</option>
                                    <option value={365}>1 year</option>
                                    <option value={730}>2 years</option>
                                    <option value={1095}>3 years</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm font-medium mb-1">
                                    Payment Token
                                </label>
                                <TokenSelector
                                    onTokenSelect={setRenewalToken}
                                    selectedTokenAddress={renewalToken?.address}
                                />
                            </div>
                            <div className="flex justify-end gap-2 mt-4">
                                <button
                                    onClick={() => setSelectedPolicy(null)}
                                    className="btn btn-ghost"
                                >
                                    Cancel
                                </button>
                                <button
                                    onClick={handleRenewPolicy}
                                    disabled={isRenewing || !renewalToken}
                                    className="btn btn-primary"
                                >
                                    {isRenewing ? (
                                        <>
                                            <span className="loading loading-spinner loading-sm"></span>
                                            Renewing...
                                        </>
                                    ) : (
                                        "Renew Policy"
                                    )}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}; 