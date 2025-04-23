"use client";
import { useState, useEffect } from "react";
import { FLARE_TESTNET_TOKENS, TokenInfo, isValidTokenAddress } from "~~/utils/tokenAddresses";
import { fetchTokenInfo, isValidERC20Token } from "~~/utils/tokenUtils";

interface TokenSelectorProps {
    onTokenSelect: (token: TokenInfo) => void;
    selectedTokenAddress?: string;
    className?: string;
}

export const TokenSelector = ({ onTokenSelect, selectedTokenAddress, className = "" }: TokenSelectorProps) => {
    const [isOpen, setIsOpen] = useState(false);
    const [searchTerm, setSearchTerm] = useState("");
    const [customAddress, setCustomAddress] = useState("");
    const [customSymbol, setCustomSymbol] = useState("");
    const [customName, setCustomName] = useState("");
    const [customDecimals, setCustomDecimals] = useState("18");
    const [isAddingCustom, setIsAddingCustom] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [isLoading, setIsLoading] = useState(false);

    const filteredTokens = FLARE_TESTNET_TOKENS.filter(
        token =>
            token.symbol.toLowerCase().includes(searchTerm.toLowerCase()) ||
            token.name.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const handleTokenSelect = (token: TokenInfo) => {
        onTokenSelect(token);
        setIsOpen(false);
        setSearchTerm("");
        setError(null);
    };

    const handleAddressChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const address = e.target.value;
        setCustomAddress(address);

        // If address is valid format, try to fetch token info
        if (/^0x[a-fA-F0-9]{40}$/.test(address)) {
            setIsLoading(true);
            setError(null);

            try {
                // Check if it's already in our list
                if (isValidTokenAddress(address)) {
                    setError("This token is already in the list");
                    setIsLoading(false);
                    return;
                }

                // Try to fetch token info from blockchain
                const tokenInfo = await fetchTokenInfo(address);

                if (tokenInfo) {
                    setCustomSymbol(tokenInfo.symbol);
                    setCustomName(tokenInfo.name);
                    setCustomDecimals(tokenInfo.decimals.toString());
                }
            } catch (err) {
                console.error("Error fetching token info:", err);
            } finally {
                setIsLoading(false);
            }
        }
    };

    const handleAddCustomToken = async () => {
        // Validate address format
        if (!/^0x[a-fA-F0-9]{40}$/.test(customAddress)) {
            setError("Invalid token address format");
            return;
        }

        // Check if address already exists in the list
        if (isValidTokenAddress(customAddress)) {
            setError("This token address already exists in the list");
            return;
        }

        // Validate if it's a real ERC20 token
        setIsLoading(true);
        try {
            const isValid = await isValidERC20Token(customAddress);

            if (!isValid) {
                setError("This address is not a valid ERC20 token");
                setIsLoading(false);
                return;
            }

            // If we don't have token info yet, try to fetch it
            if (!customSymbol || !customName) {
                const tokenInfo = await fetchTokenInfo(customAddress);

                if (tokenInfo) {
                    setCustomSymbol(tokenInfo.symbol);
                    setCustomName(tokenInfo.name);
                    setCustomDecimals(tokenInfo.decimals.toString());
                }
            }

            const newToken: TokenInfo = {
                symbol: customSymbol.toUpperCase(),
                name: customName,
                address: customAddress,
                decimals: parseInt(customDecimals, 10),
            };

            onTokenSelect(newToken);
            setIsOpen(false);
            setIsAddingCustom(false);
            setCustomAddress("");
            setCustomSymbol("");
            setCustomName("");
            setCustomDecimals("18");
            setError(null);
        } catch (err) {
            setError("Failed to validate token. Please check the address and try again.");
        } finally {
            setIsLoading(false);
        }
    };

    // Find the selected token
    const selectedToken = selectedTokenAddress
        ? FLARE_TESTNET_TOKENS.find(token => token.address.toLowerCase() === selectedTokenAddress.toLowerCase())
        : undefined;

    return (
        <div className={`relative ${className}`}>
            <div
                className="w-full p-2 border border-gray-300 rounded-md focus:ring-primary focus:border-primary cursor-pointer flex justify-between items-center"
                onClick={() => setIsOpen(!isOpen)}
            >
                {selectedToken ? (
                    <div className="flex items-center">
                        <span className="font-medium">{selectedToken.symbol}</span>
                        <span className="text-gray-500 text-sm ml-2">({selectedToken.name})</span>
                    </div>
                ) : (
                    <span className="text-gray-500">Select a token</span>
                )}
                <svg
                    className={`w-5 h-5 transition-transform ${isOpen ? 'transform rotate-180' : ''}`}
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                    xmlns="http://www.w3.org/2000/svg"
                >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
            </div>

            {isOpen && (
                <div className="absolute z-10 w-full mt-1 bg-base-300 border-gray-300 rounded-md shadow-lg">
                    <div className="p-2 border-b border-gray-200">
                        <input
                            type="text"
                            placeholder="Search tokens..."
                            className="w-full p-2 border border-gray-300 rounded-md focus:ring-primary focus:border-primary"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>

                    {!isAddingCustom ? (
                        <>
                            <div className="max-h-60 overflow-y-auto">
                                {filteredTokens.length > 0 ? (
                                    filteredTokens.map((token) => (
                                        <div
                                            key={token.address}
                                            className="p-2 hover:bg-base-200 cursor-pointer flex justify-between items-center"
                                            onClick={() => handleTokenSelect(token)}
                                        >
                                            <div>
                                                <span className="font-medium">{token.symbol}</span>
                                                <span className="text-gray-500 text-sm ml-2">({token.name})</span>
                                            </div>
                                            <span className="text-xs text-gray-500 truncate max-w-[120px]">{token.address}</span>
                                        </div>
                                    ))
                                ) : (
                                    <div className="p-2 text-gray-500 text-center">No tokens found</div>
                                )}
                            </div>
                            <div className="p-2 border-t border-gray-200">
                                <button
                                    className="w-full p-2 text-sm hover:bg-base-200 rounded-md "
                                    onClick={() => setIsAddingCustom(true)}
                                >
                                    + Add custom token
                                </button>
                            </div>
                        </>
                    ) : (
                        <div className="p-4">
                            <h3 className="text-lg font-medium mb-3">Add Custom Token</h3>

                            {error && (
                                <div className="mb-3 p-2 bg-red-50 text-red-600 rounded-md text-sm">
                                    {error}
                                </div>
                            )}

                            <div className="space-y-3">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">
                                        Token Address
                                    </label>
                                    <input
                                        type="text"
                                        placeholder="0x..."
                                        className="w-full p-2 border border-gray-300 rounded-md focus:ring-primary focus:border-primary"
                                        value={customAddress}
                                        onChange={handleAddressChange}
                                        disabled={isLoading}
                                    />
                                    {isLoading && (
                                        <div className="mt-1 text-sm text-gray-500">
                                            Validating token...
                                        </div>
                                    )}
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">
                                        Token Symbol
                                    </label>
                                    <input
                                        type="text"
                                        placeholder="USDC"
                                        className="w-full p-2 border border-gray-300 rounded-md focus:ring-primary focus:border-primary"
                                        value={customSymbol}
                                        onChange={(e) => setCustomSymbol(e.target.value)}
                                        disabled={isLoading}
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">
                                        Token Name
                                    </label>
                                    <input
                                        type="text"
                                        placeholder="USD Coin"
                                        className="w-full p-2 border border-gray-300 rounded-md focus:ring-primary focus:border-primary"
                                        value={customName}
                                        onChange={(e) => setCustomName(e.target.value)}
                                        disabled={isLoading}
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">
                                        Decimals
                                    </label>
                                    <input
                                        type="number"
                                        placeholder="18"
                                        className="w-full p-2 border border-gray-300 rounded-md focus:ring-primary focus:border-primary"
                                        value={customDecimals}
                                        onChange={(e) => setCustomDecimals(e.target.value)}
                                        disabled={isLoading}
                                    />
                                </div>

                                <div className="flex space-x-2 pt-2">
                                    <button
                                        className="flex-1 p-2 border border-gray-300 rounded-md hover:bg-base-200"
                                        onClick={() => {
                                            setIsAddingCustom(false);
                                            setError(null);
                                        }}
                                        disabled={isLoading}
                                    >
                                        Cancel
                                    </button>
                                    <button
                                        className="flex-1 p-2 bg-primary text-white rounded-md hover:bg-primary/90 disabled:opacity-50"
                                        onClick={handleAddCustomToken}
                                        disabled={isLoading || !customAddress || !customSymbol || !customName}
                                    >
                                        {isLoading ? "Validating..." : "Add Token"}
                                    </button>
                                </div>
                            </div>
                        </div>
                    )}
                </div>
            )}
        </div>
    );
}; 