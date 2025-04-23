"use client";
import { useState } from "react";
import { InsuranceOptions } from "./InsuranceOptions";
import { PolicyDetails } from "./PolicyDetails";
import { ClaimHistory } from "./ClaimHistory";
import { PolicyCreator } from "./PolicyCreator";
import { useAccount } from "wagmi";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";

export const Dashboard = () => {
    const [selectedContract, setSelectedContract] = useState<string>("InsuranceCore");
    const [activeTab, setActiveTab] = useState<string>("browse");
    const { address } = useAccount();

    // Check if user has admin role in the contract
    const { data: hasAdminRole } = useScaffoldReadContract({
        contractName: "InsuranceCore",
        functionName: "hasRole",
        args: [
            "0x0000000000000000000000000000000000000000000000000000000000000000", // DEFAULT_ADMIN_ROLE
            address
        ],
    });

    const isAdmin = hasAdminRole === true;

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
            case "create":
                return <PolicyCreator />;
            default:
                return <InsuranceOptions />;
        }
    };

    return (
        <div className="flex flex-col gap-6 p-6 bg-base-100">
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
                {isAdmin && (
                    <button
                        className={`px-4 py-2 font-medium text-sm ${activeTab === "create"
                            ? "border-b-2 border-accent text-accent"
                            : "text-base-content/60 hover:text-base-content"
                            }`}
                        onClick={() => setActiveTab("create")}
                    >
                        Create Policy
                    </button>
                )}
            </div>

            {/* Contract Selection (only visible in contract tab) */}
            {activeTab === "contracts" && (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                    {contracts.map(contract => (
                        <div
                            key={contract.name}
                            className={`p-4 rounded-lg border cursor-pointer transition-all ${selectedContract === contract.name
                                ? "border-primary bg-primary/10"
                                : "border-gray-200 hover:border-primary/50"
                                }`}
                            onClick={() => handleContractSelect(contract.name)}
                        >
                            <h3 className="font-semibold">{contract.name}</h3>
                            <p className="text-sm text-gray-500">{contract.description}</p>
                        </div>
                    ))}
                </div>
            )}

            {/* Tab Content */}
            {renderTabContent()}
        </div>
    );
}; 