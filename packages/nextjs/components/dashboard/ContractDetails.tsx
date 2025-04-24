"use client";
import { useEffect, useState } from "react";
import { AddressInput, IntegerInput, InputBase } from "~~/components/scaffold-eth";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { useWriteContract, useChainId } from "wagmi";
import DeployedContracts from "~~/contracts/deployedContracts";

type ContractName = "MockBSDToken" | "ClaimProcessor";

interface ContractDetailsProps {
    contractName: ContractName;
}

export const ContractDetails = ({ contractName }: ContractDetailsProps) => {
    const [contractData, setContractData] = useState<any>(null);
    const [error, setError] = useState<string | null>(null);
    const [formData, setFormData] = useState<Record<string, any>>({});
    const { writeContractAsync, isPending } = useWriteContract();
    const chainId = useChainId() as keyof typeof DeployedContracts;

    const { data: contractInfo, isLoading: isContractInfoLoading } = useScaffoldReadContract({
        contractName,
        functionName: "symbol", // Using a valid function name from the contract
    });

    useEffect(() => {
        if (contractInfo) {
            setContractData(contractInfo);
        }
    }, [contractInfo]);

    const renderContractInfo = () => {
        if (error) {
            return <div className="text-error">{error}</div>;
        }

        if (isContractInfoLoading) {
            return <div className="text-base-content/60">Loading contract information...</div>;
        }

        if (!contractData) {
            return <div className="text-base-content/60">No contract information available</div>;
        }

        return (
            <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                    <div>
                        <h3 className="text-sm font-medium text-base-content/60">Contract Address</h3>
                        <AddressInput
                            value={chainId && DeployedContracts[chainId] && (contractName in DeployedContracts[chainId] as any)
                                ? (DeployedContracts[chainId] as any)[contractName].address
                                : ""}
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
            MockBSDToken: [
                { name: "transfer", label: "Transfer", args: ["to", "amount"] },
                { name: "approve", label: "Approve", args: ["spender", "amount"] },
            ],
            ClaimProcessor: [
                { name: "getClaim", label: "Get Claim", args: ["claimId"] },
                { name: "getUserClaims", label: "Get User Claims", args: ["userAddress"] },
            ],
        };

        const handleContractInteraction = async (functionName: string, args: any[]) => {
            try {
                // Implementation would go here
                console.log(`Calling ${functionName} with args:`, args);
            } catch (error) {
                console.error(`Error calling ${functionName}:`, error);
            }
        };

        return (
            <div className="space-y-4">
                {interactions[contractName]?.map((interaction: { name: string; label: string; args: string[] }) => (
                    <div key={interaction.name} className="p-4 border border-base-300 rounded-lg">
                        <h3 className="font-medium text-base-content">{interaction.label}</h3>
                        <form
                            className="mt-2 space-y-2"
                            onSubmit={async e => {
                                e.preventDefault();
                                const formData = new FormData(e.currentTarget);
                                const args = interaction.args.map((arg: string) => formData.get(arg));
                                await handleContractInteraction(interaction.name, args);
                            }}
                        >
                            {interaction.args.map((arg: string) => (
                                <div key={arg}>
                                    <label className="block text-sm font-medium text-base-content/60">{arg}</label>
                                    {arg === "amount" ? (
                                        <IntegerInput
                                            name={arg}
                                            value={formData[arg] || ""}
                                            onChange={value => setFormData(prev => ({ ...prev, [arg]: value }))}
                                            placeholder={`Enter ${arg}`}
                                        />
                                    ) : arg === "to" || arg === "spender" || arg === "userAddress" ? (
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
                                disabled={isPending}
                            >
                                {isPending && <span className="loading loading-spinner loading-xs"></span>}
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