"use client";
import { useState, useEffect } from "react";
import { useInsuranceOptions } from "~~/hooks/useInsuranceOptions";
import { useWriteContract } from "wagmi";
import { useDeployedContractInfo, useTransactor, useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { TokenSelector } from "./TokenSelector";
import { TokenInfo, getTokenByAddress, updateBSDTokenAddress } from "~~/utils/tokenAddresses";

// Define the InsuranceOption interface to match what's coming from the API
interface InsuranceOption {
    id: string;
    name: string;
    description: string;
    coverageAmount: bigint;
    premiumRate: number;
    duration: number;
    tokenAddress: string;
    tokenSymbol: string;
    tokenPrice: number;
}

export const InsuranceOptions = () => {
    const { options, isLoading: insuranceOptionsLoading, error: insuranceOptionsError } = useInsuranceOptions();
    const [selectedToken, setSelectedToken] = useState<TokenInfo | null>(null);
    const [coverageAmount, setCoverageAmount] = useState<string>("");
    const [duration, setDuration] = useState<number>(180); // Default to 6 months
    const [calculatedPremium, setCalculatedPremium] = useState<number>(0);
    const [selectedPaymentToken, setSelectedPaymentToken] = useState<TokenInfo | null>(null);
    const [error, setError] = useState<string | null>(null);
    const { writeContractAsync, isPending } = useWriteContract();
    const { data: mockBSDToken } = useDeployedContractInfo({ contractName: "MockBSDToken" });
    const { data: insuranceCore } = useDeployedContractInfo({ contractName: "InsuranceCore" });

    const writeTx = useTransactor();

    // Get token price from the contract
    const { data: tokenPrice } = useScaffoldReadContract({
        contractName: "InsuranceCore",
        functionName: "calculatePremium",
        args: [
            BigInt(parseFloat(coverageAmount) || 0),
            BigInt(duration),
            selectedToken?.address as `0x${string}` || "0x0000000000000000000000000000000000000000"
        ],
    });

    // Get coverage options from the contract
    const { data: coverageOptionsCount } = useScaffoldReadContract({
        contractName: "InsuranceCore",
        functionName: "coverageOptionCount",
    });

    // Get coverage option details
    const { data: coverageOption } = useScaffoldReadContract({
        contractName: "InsuranceCore",
        functionName: "getCoverageOption",
        args: [BigInt(0)], // Get first coverage option
    });

    // Create insurance options based on contract data
    const insuranceOptions: InsuranceOption[] = coverageOption ? [
        {
            id: "1",
            name: "Basic Coverage",
            description: "Basic insurance coverage for your assets",
            coverageAmount: coverageOption[0], // coverageLimit
            premiumRate: Number(coverageOption[1]), // premiumRate
            duration: Number(coverageOption[3]), // maxDuration
            tokenAddress: selectedToken?.address || "0x0000000000000000000000000000000000000000",
            tokenSymbol: selectedToken?.symbol || "TOKEN",
            tokenPrice: tokenPrice ? Number(tokenPrice) / 1e8 : 0,
        }
    ] : [];

    // Update the BSD token address in our token list when the mock token is loaded
    useEffect(() => {
        const updateToken = async () => {
            if (mockBSDToken) {
                // Update the BSD token address
                updateBSDTokenAddress(mockBSDToken.address);

                // Set the selected payment token to BSD if not already set
                if (!selectedPaymentToken) {
                    const bsdToken = await getTokenByAddress(mockBSDToken.address);
                    if (bsdToken) {
                        setSelectedPaymentToken(bsdToken);
                    }
                }
            }
        };
        updateToken();
    }, [mockBSDToken, selectedPaymentToken]);

    useEffect(() => {
        const calculatePremium = async () => {
            if (!coverageAmount || !selectedToken || !tokenPrice) return;

            try {
                // Use the contract directly instead of the hook
                if (insuranceCore) {
                    // Use the contract's ABI to call the function
                    const premium = await insuranceCore.abi.find(
                        (item) => item.type === "function" && item.name === "calculatePremium"
                    );

                    if (premium) {
                        // Use the contract's address and ABI to call the function
                        const result = await window.ethereum.request({
                            method: "eth_call",
                            params: [
                                {
                                    to: insuranceCore.address,
                                    data: window.ethereum.utils.solidityPack(
                                        ["uint256", "uint256", "address"],
                                        [BigInt(parseFloat(coverageAmount)), BigInt(duration), selectedToken.address]
                                    ),
                                },
                                "latest",
                            ],
                        });

                        if (result) {
                            const premiumValue = BigInt(result);
                            setCalculatedPremium(Number(premiumValue) / 1e8);
                        }
                    }
                }
            } catch (err) {
                console.error("Error calculating premium:", err);
                setError("Failed to calculate premium");
            }
        };

        calculatePremium();
    }, [coverageAmount, selectedToken, tokenPrice, duration, insuranceCore]);

    const handleTokenSelect = (token: TokenInfo) => {
        setSelectedToken(token);
        setCoverageAmount("");
        setCalculatedPremium(0);
    };

    const handleCoverageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const value = e.target.value;
        if (/^\d*\.?\d*$/.test(value)) {
            setCoverageAmount(value);
        }
    };

    const handleDurationChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
        setDuration(Number(e.target.value));
    };

    if (insuranceOptionsLoading) {
        return (
            <div className="flex justify-center items-center h-40">
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
            </div>
        );
    }

    if (insuranceOptionsError || error) {
        return (
            <div className="p-4 rounded-lg border border-error bg-error/10">
                <p className="text-error">{insuranceOptionsError || error}</p>
            </div>
        );
    }

    const handlePurchaseInsurance = async () => {
        if (!selectedPaymentToken || !selectedToken) {
            setError("Please select both a token and payment token");
            return;
        }

        try {
            // First approve the token transfer
            await writeContractAsync({
                address: selectedPaymentToken.address as `0x${string}`,
                abi: mockBSDToken?.abi || [],
                functionName: "approve",
                args: [mockBSDToken?.address || "0x0", BigInt(calculatedPremium * 1e8)],
            });

            // Then create the policy
            await writeContractAsync({
                address: insuranceCore?.address as `0x${string}`,
                abi: insuranceCore?.abi || [],
                functionName: "addCoverageOption",
                args: [
                    BigInt(parseFloat(coverageAmount)),
                    BigInt(calculatedPremium * 1e8),
                    BigInt(duration),
                    BigInt(duration * 2), // maxDuration is 2x the selected duration
                ],
            });
        } catch (err) {
            console.error("Error purchasing insurance:", err);
            setError("Failed to purchase insurance");
        }
    };

    return (
        <div className="space-y-6">
            <div className="p-6 rounded-lg border border-base-300">
                <h2 className="text-xl font-semibold mb-6">Insurance Options</h2>

                <div className="space-y-6">
                    <div>
                        <label className="block text-sm font-medium mb-2">Select Token</label>
                        <TokenSelector
                            onTokenSelect={handleTokenSelect}
                            selectedTokenAddress={selectedToken?.address}
                        />
                    </div>

                    {selectedToken && (
                        <>
                            <div>
                                <label className="block text-sm font-medium mb-2">
                                    Coverage Amount ({selectedToken.symbol})
                                </label>
                                <input
                                    type="text"
                                    value={coverageAmount}
                                    onChange={handleCoverageChange}
                                    className="input input-bordered w-full"
                                    placeholder="Enter coverage amount"
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-medium mb-2">Duration</label>
                                <select
                                    value={duration}
                                    onChange={handleDurationChange}
                                    className="select select-bordered w-full"
                                >
                                    <option value={180}>6 months</option>
                                    <option value={365}>1 year</option>
                                    <option value={730}>2 years</option>
                                    <option value={1095}>3 years</option>
                                </select>
                            </div>

                            {tokenPrice && (
                                <div className="p-4 rounded-lg bg-base-200">
                                    <h3 className="font-semibold mb-2">Premium Calculation</h3>
                                    <div className="space-y-2">
                                        <div className="flex justify-between">
                                            <span className="text-base-content/60">Token Price:</span>
                                            <span>${(Number(tokenPrice) / 1e8).toFixed(2)}</span>
                                        </div>
                                        <div className="flex justify-between">
                                            <span className="text-base-content/60">Coverage Value:</span>
                                            <span>
                                                ${((parseFloat(coverageAmount) || 0) * (Number(tokenPrice) / 1e8)).toFixed(2)}
                                            </span>
                                        </div>
                                        <div className="flex justify-between">
                                            <span className="text-base-content/60">Duration:</span>
                                            <span>{(duration / 30).toFixed(0)} months</span>
                                        </div>
                                        <div className="flex justify-between font-semibold">
                                            <span>Estimated Premium:</span>
                                            <span>${calculatedPremium.toFixed(2)}</span>
                                        </div>
                                    </div>
                                </div>
                            )}
                        </>
                    )}
                </div>
            </div>

            {insuranceOptions.length > 0 && (
                <div className="p-6 rounded-lg border border-base-300">
                    <h2 className="text-xl font-semibold mb-6">Available Insurance Options</h2>
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {insuranceOptions.map((option) => (
                            <div key={option.id} className="p-4 rounded-lg border border-base-300">
                                <h3 className="font-semibold">{option.name}</h3>
                                <p className="text-sm text-base-content/60 mb-4">{option.description}</p>
                                <div className="space-y-2">
                                    <div className="flex justify-between">
                                        <span className="text-base-content/60">Coverage:</span>
                                        <span>
                                            {option.coverageAmount.toString()} {option.tokenSymbol}
                                        </span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-base-content/60">Premium Rate:</span>
                                        <span>{(option.premiumRate / 100).toFixed(2)}%</span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-base-content/60">Duration:</span>
                                        <span>{(option.duration / 30).toFixed(0)} months</span>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            )}

            <div className="p-6 rounded-lg border border-base-300">
                <h2 className="text-xl font-semibold mb-4">Configure Your Insurance</h2>

                <div className="space-y-4">
                    <div>
                        <label className="block text-sm font-medium mb-2">Payment Token</label>
                        <TokenSelector
                            onTokenSelect={token => setSelectedPaymentToken(token)}
                            selectedTokenAddress={selectedPaymentToken?.address}
                        />
                    </div>

                    <div className="bg-base-200 p-4 rounded-lg">
                        <h4 className="font-medium mb-2">Insurance Summary</h4>
                        <div className="grid grid-cols-2 gap-2 text-sm">
                            <div>
                                <span className="text-base-content/60">Token:</span>
                                <span className="ml-1">{selectedToken?.name}</span>
                            </div>
                            <div>
                                <span className="text-base-content/60">Coverage Amount:</span>
                                <span className="ml-1">
                                    {coverageAmount} {selectedToken?.symbol}
                                </span>
                            </div>
                            <div>
                                <span className="text-base-content/60">Duration:</span>
                                <span className="ml-1">{(duration / 30).toFixed(0)} months</span>
                            </div>
                            <div>
                                <span className="text-base-content/60">Total Premium:</span>
                                <span className="ml-1">${calculatedPremium.toFixed(2)}</span>
                            </div>
                            {selectedPaymentToken && (
                                <div className="col-span-2">
                                    <span className="text-base-content/60">Payment Token:</span>
                                    <span className="ml-1">{selectedPaymentToken.symbol}</span>
                                </div>
                            )}
                        </div>
                    </div>

                    <button
                        onClick={handlePurchaseInsurance}
                        disabled={isPending || !selectedPaymentToken || !selectedToken}
                        className="w-full inline-flex justify-center rounded-md border border-transparent bg-primary px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 disabled:opacity-50"
                    >
                        {isPending ? "Processing..." : "Purchase Insurance"}
                    </button>
                </div>
            </div>
        </div>
    );
}; 