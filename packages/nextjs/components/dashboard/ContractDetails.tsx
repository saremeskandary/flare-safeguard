"use client";
import { useEffect, useState } from "react";
import { useContractInteraction } from "~~/hooks/scaffold-eth/useContractInteraction";

interface ContractDetailsProps {
    contractName: string;
}

export const ContractDetails = ({ contractName }: ContractDetailsProps) => {
    const { readContract, writeContract, isLoading } = useContractInteraction();
    const [contractData, setContractData] = useState<any>(null);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        let mounted = true;

        const fetchContractData = async () => {
            if (!contractName) return;

            try {
                const data = await readContract({
                    contractName,
                    functionName: "getContractInfo",
                });

                if (mounted) {
                    setContractData(data);
                }
            } catch (err) {
                if (mounted) {
                    setError(err instanceof Error ? err.message : "Failed to fetch contract data");
                }
            }
        };

        fetchContractData();

        return () => {
            mounted = false;
        };
    }, [contractName, readContract]);

    const renderContractInfo = () => {
        if (error) {
            return <div className="text-error">{error}</div>;
        }

        if (!contractData) {
            return <div className="text-base-content/60">Loading contract information...</div>;
        }

        return (
            <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                    <div>
                        <h3 className="text-sm font-medium text-base-content/60">Contract Address</h3>
                        <p className="mt-1 text-base-content">{contractData.address}</p>
                    </div>
                    <div>
                        <h3 className="text-sm font-medium text-base-content/60">Owner</h3>
                        <p className="mt-1 text-base-content">{contractData.owner}</p>
                    </div>
                </div>
                {/* Add more contract-specific information here */}
            </div>
        );
    };

    const renderContractInteractions = () => {
        const interactions = {
            InsuranceCore: [
                { name: "createPolicy", label: "Create Policy", args: ["amount", "duration"] },
                { name: "claimInsurance", label: "Claim Insurance", args: ["policyId"] },
            ],
            InsuranceAutomation: [
                { name: "automateClaim", label: "Automate Claim", args: ["policyId"] },
                { name: "checkAutomationStatus", label: "Check Status", args: ["claimId"] },
            ],
            LiquidityPool: [
                { name: "deposit", label: "Deposit", args: ["amount"] },
                { name: "withdraw", label: "Withdraw", args: ["amount"] },
            ],
            BSDToken: [
                { name: "transfer", label: "Transfer", args: ["to", "amount"] },
                { name: "approve", label: "Approve", args: ["spender", "amount"] },
            ],
        };

        const contractInteractions = interactions[contractName as keyof typeof interactions] || [];

        return (
            <div className="space-y-4">
                {contractInteractions.map(interaction => (
                    <div key={interaction.name} className="p-4 border border-base-300 rounded-lg">
                        <h3 className="font-medium text-base-content">{interaction.label}</h3>
                        <form
                            className="mt-2 space-y-2"
                            onSubmit={async e => {
                                e.preventDefault();
                                const formData = new FormData(e.currentTarget);
                                const args = interaction.args.map(arg => formData.get(arg));
                                try {
                                    await writeContract({
                                        contractName,
                                        functionName: interaction.name,
                                        args,
                                    });
                                } catch (err) {
                                    console.error(err);
                                }
                            }}
                        >
                            {interaction.args.map(arg => (
                                <div key={arg}>
                                    <label className="block text-sm font-medium text-base-content/60">{arg}</label>
                                    <input
                                        type="text"
                                        name={arg}
                                        className="mt-1 block w-full rounded-md border-base-300 bg-base-200 text-base-content shadow-sm focus:border-accent focus:ring-accent sm:text-sm"
                                    />
                                </div>
                            ))}
                            <button
                                type="submit"
                                className="mt-2 inline-flex justify-center rounded-md border border-transparent bg-accent px-4 py-2 text-sm font-medium text-accent-content shadow-sm hover:bg-accent/90 focus:outline-none focus:ring-2 focus:ring-accent focus:ring-offset-2"
                                disabled={isLoading}
                            >
                                {isLoading ? "Processing..." : "Submit"}
                            </button>
                        </form>
                    </div>
                ))}
            </div>
        );
    };

    return (
        <div className="space-y-6">
            <div className="p-6 rounded-lg border border-base-300 bg-base-200">
                <h2 className="text-xl font-semibold mb-4 text-base-content">Contract Information</h2>
                {renderContractInfo()}
            </div>

            <div className="p-6 rounded-lg border border-base-300 bg-base-200">
                <h2 className="text-xl font-semibold mb-4 text-base-content">Contract Interactions</h2>
                {renderContractInteractions()}
            </div>
        </div>
    );
}; 