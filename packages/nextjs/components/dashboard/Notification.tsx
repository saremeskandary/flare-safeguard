"use client";
import { useEffect, useState } from "react";

interface NotificationProps {
    error: string | null;
    successMessage: string | null;
}

export const Notification = ({ error, successMessage }: NotificationProps) => {
    const [isVisible, setIsVisible] = useState(false);

    useEffect(() => {
        if (error || successMessage) {
            setIsVisible(true);
        } else {
            setIsVisible(false);
        }
    }, [error, successMessage]);

    if (!isVisible) return null;

    return (
        <div className="fixed top-4 right-4 z-50 max-w-md">
            {error && (
                <div className="mb-2 p-4 rounded-lg bg-error/10 border border-error/20 text-error shadow-lg">
                    <div className="flex items-center">
                        <svg className="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                        </svg>
                        <p>{error}</p>
                    </div>
                </div>
            )}
            {successMessage && (
                <div className="mb-2 p-4 rounded-lg bg-success/10 border border-success/20 text-success shadow-lg">
                    <div className="flex items-center">
                        <svg className="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                        </svg>
                        <p>{successMessage}</p>
                    </div>
                </div>
            )}
        </div>
    );
}; 