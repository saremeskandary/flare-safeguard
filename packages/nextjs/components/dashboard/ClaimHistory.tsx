"use client";
import { useTheme } from "next-themes";
import { useClaims, type Claim } from "~~/hooks/scaffold-eth/useClaims";
import { useAccount } from "wagmi";

export const ClaimHistory = () => {
    const { theme } = useTheme();
    const { address } = useAccount();
    const { claims, isLoading, error } = useClaims();

    const formatDate = (timestamp: bigint) => {
        return new Date(Number(timestamp) * 1000).toLocaleDateString();
    };

    const getStatusStyles = (status: number) => {
        const baseStyles = "px-3 py-1 rounded-full text-sm font-medium";
        if (theme === "dark") {
            switch (status) {
                case 0: // Pending
                    return `${baseStyles} bg-yellow-900 text-yellow-200`;
                case 1: // Approved
                    return `${baseStyles} bg-green-900 text-green-200`;
                case 2: // Rejected
                    return `${baseStyles} bg-red-900 text-red-200`;
                default:
                    return `${baseStyles} bg-gray-700 text-gray-300`;
            }
        } else {
            switch (status) {
                case 0: // Pending
                    return `${baseStyles} bg-yellow-100 text-yellow-800`;
                case 1: // Approved
                    return `${baseStyles} bg-green-100 text-green-800`;
                case 2: // Rejected
                    return `${baseStyles} bg-red-100 text-red-800`;
                default:
                    return `${baseStyles} bg-gray-100 text-gray-800`;
            }
        }
    };

    if (error) {
        return (
            <div className={`p-4 rounded-lg ${theme === "dark" ? "bg-red-900/20" : "bg-red-50"}`}>
                <p className={`${theme === "dark" ? "text-red-200" : "text-red-800"}`}>
                    Error loading claims: {error.message}
                </p>
            </div>
        );
    }

    if (isLoading) {
        return (
            <div className={`p-4 rounded-lg ${theme === "dark" ? "bg-gray-800" : "bg-white"}`}>
                <p className={`${theme === "dark" ? "text-gray-300" : "text-gray-700"}`}>Loading claims...</p>
            </div>
        );
    }

    if (!claims || claims.length === 0) {
        return (
            <div className={`p-4 rounded-lg ${theme === "dark" ? "bg-gray-800" : "bg-white"}`}>
                <p className={`${theme === "dark" ? "text-gray-300" : "text-gray-700"}`}>No claims found.</p>
            </div>
        );
    }

    return (
        <div className={`p-6 rounded-lg ${theme === "dark" ? "bg-gray-800" : "bg-white"}`}>
            <h2 className={`text-2xl font-bold mb-6 ${theme === "dark" ? "text-white" : "text-gray-900"}`}>
                Claim History
            </h2>
            <div className="space-y-4">
                {claims.map((claim: Claim) => (
                    <div
                        key={claim.id.toString()}
                        className={`p-4 rounded-lg ${theme === "dark" ? "bg-gray-800" : "bg-white"
                            } shadow-sm`}
                    >
                        <div className="flex justify-between items-start">
                            <div>
                                <h3 className={`text-lg font-semibold ${theme === "dark" ? "text-white" : "text-gray-900"}`}>
                                    Claim #{claim.id.toString()}
                                </h3>
                                <p className={`text-sm ${theme === "dark" ? "text-gray-400" : "text-gray-500"}`}>
                                    Policy ID: {claim.policyId.toString()}
                                </p>
                            </div>
                            <span className={getStatusStyles(claim.status)}>
                                {claim.status === 0 ? "Pending" : claim.status === 1 ? "Approved" : "Rejected"}
                            </span>
                        </div>
                        <div className="mt-2 grid grid-cols-2 gap-2 text-sm">
                            <div>
                                <span className="text-gray-500">Amount: </span>
                                <span>{claim.amount.toString()} wei</span>
                            </div>
                            <div>
                                <span className="text-gray-500">Chain ID:</span>
                                <span>{claim.chainId.toString()}</span>
                            </div>
                            <div>
                                <span className="text-gray-500">Transaction Hash:</span>
                                <span className="font-mono text-sm break-all">{claim.txHash}</span>
                            </div>
                            <div>
                                <span className="text-gray-500">Required Confirmations:</span>
                                <span>{claim.requiredConfirmations.toString()}</span>
                            </div>
                            <div>
                                <span className="text-gray-500">Claim Date: </span>
                                <span>{formatDate(claim.claimDate)}</span>
                            </div>
                            {claim.processedDate > BigInt(0) && (
                                <div>
                                    <span className="text-gray-500">Processed Date: </span>
                                    <span>{formatDate(claim.processedDate)}</span>
                                </div>
                            )}
                            {claim.processedBy && (
                                <div>
                                    <span className="text-gray-500">Processed By: </span>
                                    <span>{claim.processedBy}</span>
                                </div>
                            )}
                            {claim.verifiedBy && (
                                <div>
                                    <span className="text-gray-500">Verified By:</span>
                                    <span className="font-mono text-sm break-all">{claim.verifiedBy}</span>
                                </div>
                            )}
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}; 