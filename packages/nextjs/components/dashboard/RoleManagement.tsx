"use client";

import { useState } from "react";
import { useScaffoldWriteContract, useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { useAccount } from "wagmi";
import { AddressInput } from "~~/components/scaffold-eth";
import { TOKEN_RWA_FACTORY_ADMIN_ROLE, TOKEN_RWA_FACTORY_DEFAULT_ADMIN_ROLE } from "~~/utils/contractConstants";

export const RoleManagement = () => {
    const [targetAddress, setTargetAddress] = useState("");
    const [error, setError] = useState("");
    const [success, setSuccess] = useState("");
    const { address } = useAccount();

    // Check if the current user has the DEFAULT_ADMIN_ROLE
    const { data: hasDefaultAdminRole } = useScaffoldReadContract({
        contractName: "TokenRWAFactory",
        functionName: "hasRole",
        args: [TOKEN_RWA_FACTORY_DEFAULT_ADMIN_ROLE, address],
    });

    // Use the recommended object parameter version
    const { writeContractAsync } = useScaffoldWriteContract({
        contractName: "TokenRWAFactory",
    });

    const handleGrantRole = async (roleType: "admin" | "defaultAdmin") => {
        setError("");
        setSuccess("");

        if (!targetAddress) {
            setError("Please enter an address");
            return;
        }

        try {
            const role = roleType === "admin" ? TOKEN_RWA_FACTORY_ADMIN_ROLE : TOKEN_RWA_FACTORY_DEFAULT_ADMIN_ROLE;

            // Call the contract with the correct parameters
            const tx = await writeContractAsync({
                functionName: "grantRole",
                args: [role, targetAddress],
            });

            if (tx) {
                // Wait for transaction to be mined
                await new Promise(resolve => setTimeout(resolve, 5000)); // Wait for 5 seconds
                setSuccess(`${roleType === "admin" ? "Admin" : "Default Admin"} role granted successfully!`);
                setTargetAddress("");
            }
        } catch (error) {
            console.error("Error granting role:", error);
            setError("Failed to grant role. Make sure you have the necessary permissions.");
        }
    };

    return (
        <div className="flex flex-col gap-6 p-6 bg-base-200 rounded-lg">
            <h2 className="text-2xl font-bold">Role Management</h2>
            {error && (
                <div className="alert alert-error">
                    <span>{error}</span>
                </div>
            )}
            {success && (
                <div className="alert alert-success">
                    <span>{success}</span>
                </div>
            )}
            {hasDefaultAdminRole === false && (
                <div className="alert alert-warning">
                    <span>You don't have permission to manage roles. You need the DEFAULT_ADMIN_ROLE.</span>
                </div>
            )}
            <div className="form-control">
                <label className="label">
                    <span className="label-text">Target Address</span>
                </label>
                <AddressInput
                    value={targetAddress}
                    onChange={value => setTargetAddress(value)}
                    placeholder="Enter address to grant role to"
                />
            </div>
            <div className="flex gap-4">
                <button
                    className="btn btn-primary flex-1"
                    onClick={() => handleGrantRole("admin")}
                    disabled={!hasDefaultAdminRole}
                >
                    Grant Admin Role
                </button>
                <button
                    className="btn btn-secondary flex-1"
                    onClick={() => handleGrantRole("defaultAdmin")}
                    disabled={!hasDefaultAdminRole}
                >
                    Grant Default Admin Role
                </button>
            </div>
        </div>
    );
}; 