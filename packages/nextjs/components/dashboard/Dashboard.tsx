"use client";
import { useState } from "react";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { useAccount } from "wagmi";
import { InsuranceOptions } from "./InsuranceOptions";
import { PolicyDetails } from "./PolicyDetails";
import { ClaimHistory } from "./ClaimHistory";
import { CreatePolicy } from "./CreatePolicy";
import { CrossChainClaim } from "./CrossChainClaim";
import { ClaimVerification } from "./ClaimVerification";
import TokenCreation from "./TokenCreation";

export const Dashboard = () => {
    const { address } = useAccount();
    const [activeTab, setActiveTab] = useState<string>("browse");

    const { data: isAdmin } = useScaffoldReadContract({
        contractName: "InsuranceCore",
        functionName: "hasRole",
        args: ["0x0000000000000000000000000000000000000000000000000000000000000000", address],
    });

    const { data: isVerifier } = useScaffoldReadContract({
        contractName: "InsuranceCore",
        functionName: "hasRole",
        args: ["0x0000000000000000000000000000000000000000000000000000000000000001", address],
    });

    const renderTabContent = () => {
        switch (activeTab) {

            case "browse":
                return <InsuranceOptions />;
            case "policies":
                return <PolicyDetails />;
            case "claims":
                return <ClaimHistory />;
            case "create":
                return <CreatePolicy />;
            case "cross-chain-claim":
                return <CrossChainClaim />;
            case "verify-claims":
                return <ClaimVerification />;
            case "create-token":
                return <TokenCreation />;
            default:
                return <InsuranceOptions />;
        }
    };

    return (
        <div className="container mx-auto px-4 py-8">
            <div className="mb-8">
                <h1 className="text-3xl font-bold mb-4 text-base-content">
                    Insurance Dashboard
                </h1>
            </div>

            <div className="tabs tabs-boxed mb-6">
                <button
                    className={`tab ${activeTab === "browse" ? "tab-active" : ""}`}
                    onClick={() => setActiveTab("browse")}
                >
                    Browse Insurance
                </button>
                <button
                    className={`tab ${activeTab === "policies" ? "tab-active" : ""}`}
                    onClick={() => setActiveTab("policies")}
                >
                    My Policies
                </button>
                <button
                    className={`tab ${activeTab === "claims" ? "tab-active" : ""}`}
                    onClick={() => setActiveTab("claims")}
                >
                    Claim History
                </button>
                <button
                    className={`tab ${activeTab === "cross-chain-claim" ? "tab-active" : ""}`}
                    onClick={() => setActiveTab("cross-chain-claim")}
                >
                    Submit Claim
                </button>
                {isVerifier && (
                    <button
                        className={`tab ${activeTab === "verify-claims" ? "tab-active" : ""}`}
                        onClick={() => setActiveTab("verify-claims")}
                    >
                        Verify Claims
                    </button>
                )}
                {isAdmin && (
                    <>
                        <button
                            className={`tab ${activeTab === "create" ? "tab-active" : ""}`}
                            onClick={() => setActiveTab("create")}
                        >
                            Create Policy
                        </button>
                        <button
                            className={`tab ${activeTab === "create-token" ? "tab-active" : ""}`}
                            onClick={() => setActiveTab("create-token")}
                        >
                            Create Token
                        </button>
                    </>
                )}
            </div>

            <div className="bg-base-100 rounded-lg shadow-lg p-6">
                {renderTabContent()}
            </div>
        </div>
    );
}; 