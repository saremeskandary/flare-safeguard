"use client";
import { useTheme } from "next-themes";
import { useClaims } from "~~/hooks/useClaims";

export const ClaimHistory = () => {
    const { claims, isLoading, error } = useClaims();
    const { resolvedTheme } = useTheme();
    const isDarkMode = resolvedTheme === "dark";

    const formatDate = (date: Date | null) => {
        if (!date) return "N/A";
        return new Date(date).toLocaleDateString("en-US", {
            year: "numeric",
            month: "short",
            day: "numeric",
        });
    };

    const getStatusStyles = (status: string) => {
        if (isDarkMode) {
            switch (status) {
                case "approved":
                    return "bg-emerald-900/50 text-emerald-300 ring-1 ring-emerald-500/30";
                case "pending":
                    return "bg-amber-900/50 text-amber-300 ring-1 ring-amber-500/30";
                case "rejected":
                    return "bg-red-900/50 text-red-300 ring-1 ring-red-500/30";
                default:
                    return "bg-gray-800/50 text-gray-300 ring-1 ring-gray-500/30";
            }
        } else {
            switch (status) {
                case "approved":
                    return "bg-emerald-100 text-emerald-800 ring-1 ring-emerald-600/20";
                case "pending":
                    return "bg-amber-100 text-amber-800 ring-1 ring-amber-600/20";
                case "rejected":
                    return "bg-red-100 text-red-800 ring-1 ring-red-600/20";
                default:
                    return "bg-gray-100 text-gray-800 ring-1 ring-gray-600/20";
            }
        }
    };

    if (error) {
        return (
            <div className="p-6 rounded-xl border border-red-200 backdrop-blur-sm shadow-sm">
                <h2 className="text-xl font-semibold mb-4 text-red-700">Error</h2>
                <p className="text-red-600">{error}</p>
            </div>
        );
    }

    if (isLoading) {
        return (
            <div className="p-6 rounded-xl border border-gray-100 bg-base-200/50 backdrop-blur-sm shadow-sm flex justify-center items-center h-40">
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
            </div>
        );
    }

    if (claims.length === 0) {
        return (
            <div className="p-8 rounded-xl border border-gray-100 bg-base-200/50 backdrop-blur-sm shadow-sm">
                <h2 className="text-xl font-semibold mb-4">Claim History</h2>
                <p className="text-gray-500">You don&apos;t have any insurance claims.</p>
            </div>
        );
    }

    return (
        <div className="space-y-6 max-w-6xl mx-auto">
            <div className="p-8 rounded-xl border border-gray-100 bg-base-200/50 backdrop-blur-sm shadow-sm">
                <h2 className="text-2xl font-semibold mb-6 text-base-content">Claim History</h2>

                <div className="space-y-6">
                    {claims.map(claim => (
                        <div
                            key={claim.id}
                            className="p-6 rounded-xl border border-gray-100 bg-base-200 shadow-sm hover:shadow-md transition-shadow duration-200"
                        >
                            <div className="flex justify-between items-start mb-4">
                                <div>
                                    <h3 className="text-lg font-semibold text-base-content">Claim #{claim.id}</h3>
                                    <div className="mt-1 flex items-center gap-3">
                                        <p className="text-sm text-base-content/70">Policy ID: {claim.policyId}</p>
                                    </div>
                                </div>
                                <span className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusStyles(claim.status)}`}>
                                    {claim.status}
                                </span>
                            </div>

                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-6">
                                <div className="space-y-4">
                                    <div className="bg-base-300/50 p-4 rounded-lg">
                                        <h4 className="text-sm font-medium text-base-content/80 mb-1">Claim Amount</h4>
                                        <p className="text-lg font-semibold text-base-content">${claim.amount.toLocaleString()}</p>
                                    </div>
                                    <div className="bg-base-300/50 p-4 rounded-lg">
                                        <h4 className="text-sm font-medium text-base-content/80 mb-1">Claim Date</h4>
                                        <p className="text-lg font-semibold text-base-content">{formatDate(claim.timestamp)}</p>
                                    </div>
                                </div>

                                <div className="space-y-4">
                                    {claim.processedAt && (
                                        <div className="bg-base-300/50 p-4 rounded-lg">
                                            <h4 className="text-sm font-medium text-base-content/80 mb-1">Processed Date</h4>
                                            <p className="text-lg font-semibold text-base-content">{formatDate(claim.processedAt)}</p>
                                        </div>
                                    )}
                                    {claim.processedBy && (
                                        <div className="bg-base-300/50 p-4 rounded-lg">
                                            <h4 className="text-sm font-medium text-base-content/80 mb-1">Processed By</h4>
                                            <p className="text-lg font-semibold text-base-content">{claim.processedBy}</p>
                                        </div>
                                    )}
                                </div>
                            </div>

                            <div className="mt-6 p-4 bg-base-300/50 rounded-lg">
                                <h4 className="text-sm font-medium text-base-content/80 mb-2">Description</h4>
                                <p className="text-sm text-base-content/90">{claim.description}</p>
                            </div>

                            <div className="mt-6 pt-4 border-t border-gray-100">
                                <div className="flex justify-end">
                                    <button className="px-4 py-2 text-sm font-medium text-primary hover:text-primary/80 hover:bg-primary/5 rounded-lg transition-colors duration-200">
                                        View Details →
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