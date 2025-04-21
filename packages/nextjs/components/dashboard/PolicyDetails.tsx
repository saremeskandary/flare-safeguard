"use client";

import { useState, useEffect } from "react";
import { useContractInteraction } from "~~/hooks/scaffold-eth/useContractInteraction";

export const PolicyDetails = () => {
    const { isLoading } = useContractInteraction();
    const [policies, setPolicies] = useState<any[]>([]);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        const fetchPolicies = async () => {
            try {
                // In a real implementation, this would fetch from the contract
                // For now, we'll use mock data
                const mockPolicies = [
                    {
                        id: "POL-001",
                        tokenId: "REAL-ESTATE-001",
                        tokenName: "Real Estate Project 001",
                        coverageAmount: 75000,
                        premiumAmount: 1875,
                        startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 30 days ago
                        endDate: new Date(Date.now() + 335 * 24 * 60 * 60 * 1000), // 335 days from now
                        status: "Active",
                    },
                    {
                        id: "POL-002",
                        tokenId: "REAL-ESTATE-002",
                        tokenName: "Real Estate Project 002",
                        coverageAmount: 112500,
                        premiumAmount: 3375,
                        startDate: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000), // 60 days ago
                        endDate: new Date(Date.now() + 305 * 24 * 60 * 60 * 1000), // 305 days from now
                        status: "Active",
                    },
                ];

                setPolicies(mockPolicies);
            } catch (err) {
                setError(err instanceof Error ? err.message : "Failed to fetch policies");
            }
        };

        fetchPolicies();
    }, []);

    const formatDate = (date: Date) => {
        return date.toLocaleDateString("en-US", {
            year: "numeric",
            month: "short",
            day: "numeric",
        });
    };

    const calculateRemainingDays = (endDate: Date) => {
        const now = new Date();
        const diffTime = endDate.getTime() - now.getTime();
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        return diffDays;
    };

    if (error) {
        return (
            <div className="p-6 rounded-lg border border-red-200 bg-red-50">
                <h2 className="text-xl font-semibold mb-4 text-red-700">Error</h2>
                <p className="text-red-600">{error}</p>
            </div>
        );
    }

    if (isLoading) {
        return (
            <div className="p-6 rounded-lg border border-gray-200 flex justify-center items-center h-40">
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
            </div>
        );
    }

    if (policies.length === 0) {
        return (
            <div className="p-6 rounded-lg border border-gray-200">
                <h2 className="text-xl font-semibold mb-4">My Policies</h2>
                <p className="text-gray-500">You don&apos;t have any active insurance policies.</p>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            <div className="p-6 rounded-lg border border-gray-200">
                <h2 className="text-xl font-semibold mb-4">My Policies</h2>

                <div className="space-y-4">
                    {policies.map(policy => (
                        <div key={policy.id} className="p-4 rounded-lg border border-gray-200">
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

                            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
                                <div>
                                    <h4 className="text-sm font-medium text-gray-500">Coverage Amount</h4>
                                    <p className="mt-1">${policy.coverageAmount.toLocaleString()}</p>
                                </div>
                                <div>
                                    <h4 className="text-sm font-medium text-gray-500">Premium Amount</h4>
                                    <p className="mt-1">${policy.premiumAmount.toLocaleString()}</p>
                                </div>
                                <div>
                                    <h4 className="text-sm font-medium text-gray-500">Remaining Days</h4>
                                    <p className="mt-1">{calculateRemainingDays(policy.endDate)} days</p>
                                </div>
                            </div>

                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
                                <div>
                                    <h4 className="text-sm font-medium text-gray-500">Start Date</h4>
                                    <p className="mt-1">{formatDate(policy.startDate)}</p>
                                </div>
                                <div>
                                    <h4 className="text-sm font-medium text-gray-500">End Date</h4>
                                    <p className="mt-1">{formatDate(policy.endDate)}</p>
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
                                                    width: `${Math.min(100, Math.max(0, (1 - calculateRemainingDays(policy.endDate) / 365) * 100))}%`
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