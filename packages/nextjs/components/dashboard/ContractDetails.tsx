"use client";
import { useEffect, useState } from "react";
import { AddressInput, IntegerInput, InputBase } from "~~/components/scaffold-eth";
import { useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { useChainId } from "wagmi";
import DeployedContracts from "~~/contracts/deployedContracts";

// Define the available contract names based on the test file
type ContractName = "InsuranceCore";

interface ContractDetailsProps {
    contractName: ContractName;
}

interface ContractInteraction {
    name: "addCoverageOption" | "evaluateRWA" | "grantRole" | "renounceRole" | "revokeRole";
    label: string;
    args: string[];
}

type ContractFunction = "addCoverageOption" | "evaluateRWA" | "calculatePremium";

export const ContractDetails = ({ contractName }: ContractDetailsProps) => {
    const [contractData, setContractData] = useState<any>(null);
    const [error, setError] = useState<string | null>(null);
    const [formData, setFormData] = useState<Record<string, any>>({});
    const chainId = useChainId();

    const { writeContractAsync } = useScaffoldWriteContract(contractName);

    // Use a valid function from the InsuranceCore contract
    const { data: contractInfo, isLoading: isContractInfoLoading } = useScaffoldReadContract({
        contractName,
        functionName: "coverageOptionCount", // This is a valid function from the test
    });

    useEffect(() => {
        if (contractInfo) {
            setContractData(contractInfo);
        }
    }, [contractInfo]);

    const handleContractInteraction = async (functionName: ContractFunction, args: (string | number | FormDataEntryValue | null)[]) => {
        if (!args.every(arg => arg !== null)) {
            console.error("Invalid arguments provided");
            return;
        }

        try {
            switch (functionName) {
                case "addCoverageOption":
                    await writeContractAsync({
                        functionName,
                        args: [
                            BigInt(String(args[0])), // coverageLimit
                            BigInt(String(args[1])), // premiumRate
                            BigInt(String(args[2])), // minDuration
                            BigInt(String(args[3]))  // maxDuration
                        ] as const,
                    });
                    break;
                case "evaluateRWA":
                    await writeContractAsync({
                        functionName,
                        args: [
                            args[0] as `0x${string}`, // tokenAddress
                            BigInt(String(args[1])),  // value
                            BigInt(String(args[2]))   // riskScore
                        ] as const,
                    });
                    break;
                case "calculatePremium":
                    await writeContractAsync({
                        functionName,
                        args: [
                            BigInt(String(args[0])), // coverageAmount
                            BigInt(String(args[1])), // duration
                            args[2] as `0x${string}` // tokenAddress
                        ] as const,
                    });
                    break;
                case "getCoverageOption":
                    // Implementation needed
                    break;
                case "getRWAEvaluation":
                    // Implementation needed
                    break;
                default:
                    throw new Error(`Unsupported function: ${functionName}`);
            }
        } catch (error) {
            console.error(`Error calling ${functionName}:`, error);
        }
    };

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

        // Find the contract in DeployedContracts
        const chainContracts = Object.entries(DeployedContracts).find(
            ([_, contracts]) => contracts[contractName]
        );
        const contractAddress = chainContracts ? chainContracts[1][contractName].address : "";

        return (
            <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                    <div>
                        <h3 className="text-sm font-medium text-base-content/60">Contract Address</h3>
                        <AddressInput
                            value={contractAddress}
                            onChange={() => { }}
                            disabled
                            placeholder="Contract address"
                        />
                    </div>
                    <div>
                        <h3 className="text-sm font-medium text-base-content/60">Coverage Options</h3>
                        <div className="text-base-content">{contractData.toString()}</div>
                    </div>
                </div>
            </div>
        );
    };

    const renderContractInteractions = () => {
        const contractInteractions: Record<ContractName, ContractInteraction[]> = {
            InsuranceCore: [
                {
                    name: "addCoverageOption",
                    label: "Add Coverage Option",
                    args: ["coverageLimit", "premiumRate", "minDuration", "maxDuration"]
                },
                {
                    name: "evaluateRWA",
                    label: "Evaluate RWA",
                    args: ["tokenAddress", "value", "riskScore"]
                },
                {
                    name: "grantRole",
                    label: "Grant Role",
                    args: ["role", "account"]
                },
            ],
        };

        const interactions = contractInteractions[contractName] || [];

        return (
            <div className="space-y-4">
                {interactions.map((interaction: ContractInteraction) => (
                    <div key={interaction.name} className="p-4 border border-base-300 rounded-lg">
                        <h3 className="font-medium text-base-content">{interaction.label}</h3>
                        <form
                            className="mt-2 space-y-2"
                            onSubmit={async e => {
                                e.preventDefault();
                                const formData = new FormData(e.currentTarget);
                                const args = interaction.args.map((arg: string) => formData.get(arg));
                                await handleContractInteraction(interaction.name as ContractFunction, args);
                            }}
                        >
                            {interaction.args.map((arg: string) => (
                                <div key={arg}>
                                    <label className="block text-sm font-medium text-base-content/60">{arg}</label>
                                    {arg === "coverageLimit" || arg === "premiumRate" || arg === "minDuration" || arg === "maxDuration" || arg === "value" || arg === "riskScore" ? (
                                        <IntegerInput
                                            name={arg}
                                            value={formData[arg] || ""}
                                            onChange={value => setFormData(prev => ({ ...prev, [arg]: value }))}
                                            placeholder={`Enter ${arg}`}
                                        />
                                    ) : arg === "tokenAddress" || arg === "account" ? (
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
                            >
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