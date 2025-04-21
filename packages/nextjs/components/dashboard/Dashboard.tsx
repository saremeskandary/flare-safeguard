"use client";
import { useState } from "react";
import { useAccount } from "wagmi";
import { useContractInteraction } from "~~/hooks/scaffold-eth/useContractInteraction";
import { Address } from "~~/components/scaffold-eth";
import { ContractDetails } from "./ContractDetails";
import { InsuranceOptions } from "./InsuranceOptions";
import { PolicyDetails } from "./PolicyDetails";
import { ClaimHistory } from "./ClaimHistory";
import { Notification } from "./Notification";

export const Dashboard = () => {
    const { address } = useAccount();
    const { isLoading, error, successMessage } = useContractInteraction();
    const [selectedContract, setSelectedContract] = useState<string>("InsuranceCore");
    const [activeTab, setActiveTab] = useState<string>("browse");

    const contracts = [
        { name: "InsuranceCore", description: "Core insurance contract" },
        { name: "InsuranceAutomation", description: "Automated insurance processes" },
        { name: "LiquidityPool", description: "Liquidity pool management" },
        { name: "BSDToken", description: "BSD token contract" },
    ];

    const handleContractSelect = (contractName: string) => {
        setSelectedContract(contractName);
    };

    const renderTabContent = () => {
        switch (activeTab) {
            case "browse":
                return <InsuranceOptions />;
            case "policies":
                return <PolicyDetails />;
            case "claims":
                return <ClaimHistory />;
            case "contract":
                return <ContractDetails contractName={selectedContract} />;
            default:
                return <InsuranceOptions />;
        }
    };

    return (
        <div className="flex flex-col gap-6 p-6 bg-base-100">
            <Notification error={error} successMessage={successMessage} />
            {/* Navigation Tabs */}
            <div className="flex border-b border-base-300">
                <button
                    className={`px-4 py-2 font-medium text-sm ${activeTab === "browse"
                        ? "border-b-2 border-accent text-accent"
                        : "text-base-content/60 hover:text-base-content"
                        }`}
                    onClick={() => setActiveTab("browse")}
                >
                    Browse Insurance
                </button>
                <button
                    className={`px-4 py-2 font-medium text-sm ${activeTab === "policies"
                        ? "border-b-2 border-accent text-accent"
                        : "text-base-content/60 hover:text-base-content"
                        }`}
                    onClick={() => setActiveTab("policies")}
                >
                    My Policies
                </button>
                <button
                    className={`px-4 py-2 font-medium text-sm ${activeTab === "claims"
                        ? "border-b-2 border-accent text-accent"
                        : "text-base-content/60 hover:text-base-content"
                        }`}
                    onClick={() => setActiveTab("claims")}
                >
                    Claim History
                </button>
                <button
                    className={`px-4 py-2 font-medium text-sm ${activeTab === "contract"
                        ? "border-b-2 border-accent text-accent"
                        : "text-base-content/60 hover:text-base-content"
                        }`}
                    onClick={() => setActiveTab("contract")}
                >
                    Contract Details
                </button>
            </div>

            {/* Contract Selection (only visible in contract tab) */}
            {activeTab === "contract" && (
                <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                    {contracts.map(contract => (
                        <div
                            key={contract.name}
                            className={`p-4 rounded-lg border cursor-pointer transition-all ${selectedContract === contract.name
                                ? "border-accent bg-accent/10"
                                : "border-base-300 hover:border-accent/50"
                                }`}
                            onClick={() => handleContractSelect(contract.name)}
                        >
                            <h3 className="font-semibold text-base-content">{contract.name}</h3>
                            <p className="text-sm text-base-content/60">{contract.description}</p>
                        </div>
                    ))}
                </div>
            )}

            {/* Tab Content */}
            <div className="mt-4">
                {renderTabContent()}
            </div>

            {isLoading && (
                <div className="fixed inset-0 bg-base-100/80 backdrop-blur-sm flex items-center justify-center">
                    <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-accent"></div>
                </div>
            )}
        </div>
    );
}; 