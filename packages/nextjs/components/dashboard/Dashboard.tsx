"use client";
import { useState } from "react";
import { useTheme } from "next-themes";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth/useScaffoldReadContract";
import { useAccount } from "wagmi";
import { InsuranceOptions } from "./InsuranceOptions";
import { PolicyDetails } from "./PolicyDetails";
import { ClaimHistory } from "./ClaimHistory";
import { CreatePolicy } from "./CreatePolicy";
import { CrossChainClaim } from "./CrossChainClaim";

export const Dashboard = () => {
    const { theme } = useTheme();
    const { address } = useAccount();
    const [selectedContract, setSelectedContract] = useState<string>("");
    const [activeTab, setActiveTab] = useState<string>("browse");

    const { data: isAdmin } = useScaffoldReadContract({
        contractName: "InsuranceCore",
        functionName: "hasRole",
        args: ["0x0000000000000000000000000000000000000000000000000000000000000000", address], // DEFAULT_ADMIN_ROLE
    });

    const { data: isVerifier } = useScaffoldReadContract({
        contractName: "InsuranceCore",
        functionName: "hasRole",
        args: ["0x0000000000000000000000000000000000000000000000000000000000000001", address], // VERIFIER_ROLE
    });

    const contracts = [
        {
            name: "InsuranceCore",
            description: "Core insurance contract for policy management",
        },
        {
            name: "ClaimProcessor",
            description: "Contract for processing insurance claims",
        },
    ];

    const handleContractSelect = (contractName: string) => {
        setSelectedContract(contractName);
    };

    const renderTabContent = () => {
        if (!selectedContract) {
            return (
                <div className={`p-6 rounded-lg ${theme === "dark" ? "bg-gray-800" : "bg-white"}`}>
                    <p className={`${theme === "dark" ? "text-gray-300" : "text-gray-700"}`}>
                        Please select a contract to continue.
                    </p>
                </div>
            );
        }

        switch (activeTab) {
            case "browse":
                return <InsuranceOptions />;
            case "policies":
                return <PolicyDetails />;
            case "claims":
                return <ClaimHistory />;
            case "create":
                return isAdmin ? <CreatePolicy /> : <div>Access denied</div>;
            case "cross-chain-claim":
                return <CrossChainClaim />;
            default:
                return <div>Select a tab</div>;
        }
    };

    return (
        <div className="container mx-auto px-4 py-8">
            <div className="mb-8">
                <h1 className={`text-3xl font-bold mb-4 ${theme === "dark" ? "text-white" : "text-gray-900"}`}>
                    Insurance Dashboard
                </h1>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {contracts.map(contract => (
                        <div
                            key={contract.name}
                            className={`p-4 rounded-lg border cursor-pointer transition-colors ${selectedContract === contract.name
                                ? theme === "dark"
                                    ? "border-blue-500 bg-blue-900/20"
                                    : "border-blue-500 bg-blue-50"
                                : theme === "dark"
                                    ? "border-gray-700 hover:border-gray-600"
                                    : "border-gray-200 hover:border-gray-300"
                                }`}
                            onClick={() => handleContractSelect(contract.name)}
                        >
                            <h3 className={`text-lg font-semibold mb-2 ${theme === "dark" ? "text-white" : "text-gray-900"}`}>
                                {contract.name}
                            </h3>
                            <p className={`text-sm ${theme === "dark" ? "text-gray-400" : "text-gray-600"}`}>
                                {contract.description}
                            </p>
                        </div>
                    ))}
                </div>
            </div>

            <div className="mb-6">
                <nav className="flex space-x-4">
                    <button
                        onClick={() => setActiveTab("browse")}
                        className={`px-4 py-2 rounded-lg ${activeTab === "browse"
                            ? theme === "dark"
                                ? "bg-blue-600 text-white"
                                : "bg-blue-500 text-white"
                            : theme === "dark"
                                ? "text-gray-300 hover:bg-gray-700"
                                : "text-gray-700 hover:bg-gray-100"
                            }`}
                    >
                        Browse Insurance
                    </button>
                    <button
                        onClick={() => setActiveTab("policies")}
                        className={`px-4 py-2 rounded-lg ${activeTab === "policies"
                            ? theme === "dark"
                                ? "bg-blue-600 text-white"
                                : "bg-blue-500 text-white"
                            : theme === "dark"
                                ? "text-gray-300 hover:bg-gray-700"
                                : "text-gray-700 hover:bg-gray-100"
                            }`}
                    >
                        My Policies
                    </button>
                    <button
                        onClick={() => setActiveTab("claims")}
                        className={`px-4 py-2 rounded-lg ${activeTab === "claims"
                            ? theme === "dark"
                                ? "bg-blue-600 text-white"
                                : "bg-blue-500 text-white"
                            : theme === "dark"
                                ? "text-gray-300 hover:bg-gray-700"
                                : "text-gray-700 hover:bg-gray-100"
                            }`}
                    >
                        Claim History
                    </button>
                    <button
                        onClick={() => setActiveTab("cross-chain-claim")}
                        className={`px-4 py-2 rounded-lg ${activeTab === "cross-chain-claim"
                            ? theme === "dark"
                                ? "bg-blue-600 text-white"
                                : "bg-blue-500 text-white"
                            : theme === "dark"
                                ? "text-gray-300 hover:bg-gray-700"
                                : "text-gray-700 hover:bg-gray-100"
                            }`}
                    >
                        Submit Cross-Chain Claim
                    </button>
                    {isAdmin && (
                        <button
                            onClick={() => setActiveTab("create")}
                            className={`px-4 py-2 rounded-lg ${activeTab === "create"
                                ? theme === "dark"
                                    ? "bg-blue-600 text-white"
                                    : "bg-blue-500 text-white"
                                : theme === "dark"
                                    ? "text-gray-300 hover:bg-gray-700"
                                    : "text-gray-700 hover:bg-gray-100"
                                }`}
                        >
                            Create Policy
                        </button>
                    )}
                </nav>
            </div>

            {renderTabContent()}
        </div>
    );
}; 