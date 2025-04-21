"use client";
import { useState } from "react";
import { useContractInteraction } from "~~/hooks/scaffold-eth/useContractInteraction";
import { useInsuranceOptions } from "~~/hooks/useInsuranceOptions";

export const InsuranceOptions = () => {
    const { writeContract, isLoading } = useContractInteraction();
    const { options, isLoading: insuranceOptionsLoading, error } = useInsuranceOptions();
    const [selectedToken, setSelectedToken] = useState<string>("REAL-ESTATE-001");
    const [coverageAmount, setCoverageAmount] = useState<number>(75);
    const [duration, setDuration] = useState<number>(12);

    if (insuranceOptionsLoading) {
        return (
            <div className="p-6 rounded-xl border border-gray-100 bg-base-200/50 backdrop-blur-sm shadow-sm flex justify-center items-center h-40">
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="p-6 rounded-xl border border-red-200 bg-red-50/50 backdrop-blur-sm shadow-sm">
                <h2 className="text-xl font-semibold mb-4 text-red-700">Error</h2>
                <p className="text-red-600">{error}</p>
            </div>
        );
    }

    if (options.length === 0) {
        return (
            <div className="p-8 rounded-xl border border-gray-100 bg-base-200/50 backdrop-blur-sm shadow-sm">
                <h2 className="text-xl font-semibold mb-4">Insurance Options</h2>
                <p className="text-gray-500">No insurance options available.</p>
            </div>
        );
    }

    // Use the options from the database instead of mock data
    const availableTokens = options;

    const selectedTokenData = availableTokens.find(token => token.id === selectedToken);
    const premiumAmount = selectedTokenData
        ? (selectedTokenData.value * (coverageAmount / 100) * (selectedTokenData.premiumRate / 100)) / 12
        : 0;

    const handlePurchaseInsurance = async () => {
        try {
            await writeContract({
                contractName: "InsuranceCore",
                functionName: "createPolicy",
                args: [selectedToken, coverageAmount, duration],
            });
        } catch (error) {
            console.error("Failed to purchase insurance:", error);
        }
    };

    return (
        <div className="space-y-6">
            <div className="p-6 rounded-lg border border-gray-200">
                <h2 className="text-xl font-semibold mb-4">Available Insurance Options</h2>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                    {availableTokens.map(token => (
                        <div
                            key={token.id}
                            className={`p-4 rounded-lg border cursor-pointer transition-all ${selectedToken === token.id
                                ? "border-primary bg-primary/10"
                                : "border-gray-200 hover:border-primary/50"
                                }`}
                            onClick={() => setSelectedToken(token.id)}
                        >
                            <h3 className="font-semibold">{token.name}</h3>
                            <p className="text-sm text-gray-500 mb-2">{token.description}</p>
                            <div className="grid grid-cols-2 gap-2 text-sm">
                                <div>
                                    <span className="text-gray-500">Value:</span>
                                    <span className="ml-1">${token.value.toLocaleString()}</span>
                                </div>
                                <div>
                                    <span className="text-gray-500">Premium Rate:</span>
                                    <span className="ml-1">{token.premiumRate}%</span>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>

                {selectedTokenData && (
                    <div className="p-6 rounded-lg border border-gray-200 ">
                        <h3 className="text-lg font-semibold mb-4">Configure Your Insurance</h3>

                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">
                                    Coverage Amount (%)
                                </label>
                                <div className="flex items-center gap-4 max-w-40">
                                    <input
                                        type="range"
                                        min="50"
                                        max="100"
                                        step="25"
                                        value={coverageAmount}
                                        onChange={e => setCoverageAmount(Number(e.target.value))}
                                        className="w-full"
                                    />
                                    <span className="text-sm font-medium">{coverageAmount}%</span>
                                </div>
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">
                                    Policy Duration (months)
                                </label>
                                <select
                                    value={duration}
                                    onChange={e => setDuration(Number(e.target.value))}
                                    className="max-w-40 mt-1 p-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary sm:text-sm"
                                >
                                    <option value={6}>6 months</option>
                                    <option value={12}>12 months</option>
                                    <option value={24}>24 months</option>
                                    <option value={36}>36 months</option>
                                </select>
                            </div>

                            <div className="bg-base-200 p-4 rounded-lg">
                                <h4 className="font-medium mb-2">Insurance Summary</h4>
                                <div className="grid grid-cols-2 gap-2 text-sm">
                                    <div>
                                        <span className="text-gray-500">Token:</span>
                                        <span className="ml-1">{selectedTokenData.name}</span>
                                    </div>
                                    <div>
                                        <span className="text-gray-500">Coverage Amount:</span>
                                        <span className="ml-1">${(selectedTokenData.value * (coverageAmount / 100)).toLocaleString()}</span>
                                    </div>
                                    <div>
                                        <span className="text-gray-500">Premium Rate:</span>
                                        <span className="ml-1">{selectedTokenData.premiumRate}%</span>
                                    </div>
                                    <div>
                                        <span className="text-gray-500">Monthly Premium:</span>
                                        <span className="ml-1">${premiumAmount.toLocaleString()}</span>
                                    </div>
                                    <div>
                                        <span className="text-gray-500">Duration:</span>
                                        <span className="ml-1">{duration} months</span>
                                    </div>
                                    <div>
                                        <span className="text-gray-500">Total Premium:</span>
                                        <span className="ml-1">${(premiumAmount * duration).toLocaleString()}</span>
                                    </div>
                                </div>
                            </div>

                            <button
                                onClick={handlePurchaseInsurance}
                                disabled={isLoading}
                                className="w-full inline-flex justify-center rounded-md border border-transparent bg-primary px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2"
                            >
                                {isLoading ? "Processing..." : "Purchase Insurance"}
                            </button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}; 