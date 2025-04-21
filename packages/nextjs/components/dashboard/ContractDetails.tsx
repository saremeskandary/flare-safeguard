"use client";
import { useEffect, useState } from "react";
import { useContractInteraction } from "~~/hooks/scaffold-eth/useContractInteraction";
import { AddressInput, IntegerInput, InputBase } from "~~/components/scaffold-eth";

interface ContractDetailsProps {
    contractName: string;
}

export const ContractDetails = ({ contractName }: ContractDetailsProps) => {
    const { readContract, writeContract, isLoading } = useContractInteraction();
    const [contractData, setContractData] = useState<any>(null);
    const [error, setError] = useState<string | null>(null);
    const [formData, setFormData] = useState<Record<string, any>>({});

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
                        <AddressInput
                            value={contractData.address}
                            onChange={() => { }}
                            disabled
                            placeholder="Contract address"
                        />
                    </div>
                    <div>
                        <h3 className="text-sm font-medium text-base-content/60">Owner</h3>
                        <AddressInput
                            value={contractData.owner}
                            onChange={() => { }}
                            disabled
                            placeholder="Contract owner"
                        />
                    </div>
                </div>
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
                                    {arg === "amount" ? (
                                        <IntegerInput
                                            name={arg}
                                            value={formData[arg] || ""}
                                            onChange={value => setFormData(prev => ({ ...prev, [arg]: value }))}
                                            placeholder={`Enter ${arg}`}
                                        />
                                    ) : arg === "to" || arg === "spender" ? (
                                        <AddressInput
                                            name={arg}
                                            value={formData[arg] || ""}
                                            onChange={value => setFormData(prev => ({ ...prev, [arg]: value }))}
                                            placeholder={`Enter ${arg} address`}
                                        />
                                    ) : (
                                        <InputBase
                                            name={arg}
                                            value={formData[arg] || ""}
                                            onChange={value => setFormData(prev => ({ ...prev, [arg]: value }))}
                                            placeholder={`Enter ${arg}`}
                                        />
                                    )}
                                </div>
                            ))}
                            <button
                                type="submit"
                                className="btn btn-secondary btn-sm"
                                disabled={isLoading}
                            >
                                {isLoading && <span className="loading loading-spinner loading-xs"></span>}
                                Send 💸
                            </button>
                        </form>
                    </div>
                ))}
            </div>
        );
    };

    return (
        <div className="space-y-6">
            <div className="p-6 rounded-lg border border-base-300">
                <h2 className="text-xl font-semibold mb-4 text-base-content">Contract Information</h2>
                {renderContractInfo()}
            </div>

            <div className="p-6 rounded-lg border border-base-300">
                <h2 className="text-xl font-semibold mb-4 text-base-content">Contract Interactions</h2>
                {renderContractInteractions()}
            </div>
        </div>
    );
}; 