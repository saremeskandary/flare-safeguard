"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";

type JourneyStep = {
    title: string;
    content: string[];
    details: {
        description: string[];
        functionCalls?: {
            name: string;
            description: string;
        }[];
        notes?: string[];
    };
};

const slides: JourneyStep[] = [
    {
        title: "Token Creation and Setup",
        content: [
            "Create RWA Token",
            "Token Verification Setup",
            "Enable Token Transfers"
        ],
        details: {
            description: [
                "Developer/issuer creates a new Real World Asset (RWA) token",
                "Token represents a real-world asset on the blockchain"
            ],
            functionCalls: [
                {
                    name: "TokenRWA constructor",
                    description: "Creates the token with name, symbol, and data verification address"
                }
            ],
            notes: [
                "This token represents a real-world asset on the blockchain"
            ]
        }
    },
    {
        title: "Insurance System Setup",
        content: [
            "Deploy Insurance Contracts",
            "Configure Coverage Options"
        ],
        details: {
            description: [
                "System administrator deploys the core insurance contracts",
                "Sets up available insurance coverage options"
            ],
            functionCalls: [
                {
                    name: "InsuranceCore.addCoverageOption",
                    description: "Creates coverage options with specified limits, rates, and durations"
                }
            ]
        }
    },
    {
        title: "Getting Insurance",
        content: [
            "User Registration",
            "Token Evaluation",
            "Policy Selection",
            "Policy Creation",
            "Policy Activation"
        ],
        details: {
            description: [
                "User connects their wallet and verifies identity",
                "System evaluates the RWA token for insurance",
                "User selects coverage and pays premium"
            ],
            functionCalls: [
                {
                    name: "TokenRWA.verifyHolder",
                    description: "Verifies user's wallet and identity"
                },
                {
                    name: "InsuranceCore.evaluateRWA",
                    description: "Records token evaluation with risk score"
                },
                {
                    name: "ClaimProcessor.createPolicy",
                    description: "Creates insurance policy with selected coverage"
                }
            ]
        }
    },
    {
        title: "Policy Management",
        content: [
            "Policy Monitoring",
            "Policy Renewal"
        ],
        details: {
            description: [
                "User monitors active policy status",
                "System handles policy renewals automatically"
            ],
            functionCalls: [
                {
                    name: "ClaimProcessor.getPolicy",
                    description: "Retrieves policy details and status"
                },
                {
                    name: "InsuranceAutomation.createTask",
                    description: "Schedules policy renewal tasks"
                }
            ]
        }
    },
    {
        title: "Incident and Claims",
        content: [
            "Loss or Damage Documentation",
            "Claim Initiation",
            "Claim Submission"
        ],
        details: {
            description: [
                "User documents loss or damage to their RWA token",
                "Initiates claim through the platform",
                "Submits claim with evidence"
            ],
            functionCalls: [
                {
                    name: "ClaimProcessor.submitClaim",
                    description: "Submits claim with amount and description"
                },
                {
                    name: "CrossChainClaimProcessor.submitCrossChainClaim",
                    description: "Handles cross-chain claim submissions"
                }
            ]
        }
    },
    {
        title: "Claim Processing",
        content: [
            "Initial Review",
            "Evidence Verification",
            "Claim Decision"
        ],
        details: {
            description: [
                "System performs automated checks",
                "Verifiers review claim details",
                "System makes decision on claim"
            ],
            functionCalls: [
                {
                    name: "ClaimProcessor.reviewClaim",
                    description: "Reviews and processes claim with approval status"
                },
                {
                    name: "CrossChainClaimProcessor.verifyCrossChainClaim",
                    description: "Verifies cross-chain claim evidence"
                }
            ]
        }
    },
    {
        title: "Claim Resolution",
        content: [
            "Payout Processing",
            "Claim Completion"
        ],
        details: {
            description: [
                "System processes approved claim payout",
                "User receives payout in USDT",
                "Claim is marked as completed"
            ],
            functionCalls: [
                {
                    name: "ClaimProcessor.processClaimPayout",
                    description: "Processes approved claim payout"
                },
                {
                    name: "Vault.processClaim",
                    description: "Handles claim payout from insurance reserves"
                }
            ]
        }
    }
];

export const UserJourneySlides = () => {
    const [currentSlide, setCurrentSlide] = useState(0);

    const nextSlide = () => {
        setCurrentSlide((prev) => (prev + 1) % slides.length);
    };

    const prevSlide = () => {
        setCurrentSlide((prev) => (prev - 1 + slides.length) % slides.length);
    };

    return (
        <div className="w-full max-w-4xl mx-auto p-4">
            <div className="rounded-lg overflow-hidden p-8 bg-base-200">
                <AnimatePresence mode="wait">
                    <motion.div
                        key={currentSlide}
                        initial={{ opacity: 0, x: 100 }}
                        animate={{ opacity: 1, x: 0 }}
                        exit={{ opacity: 0, x: -100 }}
                        transition={{ duration: 0.5 }}
                    >
                        <h2 className="text-4xl font-bold mb-8 text-primary">{slides[currentSlide].title}</h2>

                        {/* Description Section */}
                        <div className="mb-6 text-base-content/90">
                            {slides[currentSlide].details.description.map((desc, idx) => (
                                <p key={idx} className="mb-2">{desc}</p>
                            ))}
                        </div>

                        {/* Function Calls Section */}
                        {slides[currentSlide].details.functionCalls && (
                            <div className="mb-6">
                                <h3 className="text-xl font-semibold mb-4 text-base-content">Function Calls</h3>
                                <div className="space-y-3">
                                    {slides[currentSlide].details.functionCalls.map((func, idx) => (
                                        <div key={idx} className="bg-base-300/10 p-4 rounded-lg">
                                            <code className="text-primary font-mono text-lg">{func.name}</code>
                                            <p className="mt-2 text-base-content/80">{func.description}</p>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        )}

                        {/* Additional Notes Section */}
                        {slides[currentSlide].details.notes && (
                            <div className="mb-6">
                                <h3 className="text-xl font-semibold mb-4 text-base-content">Additional Notes</h3>
                                <ul className="list-disc list-inside space-y-2">
                                    {slides[currentSlide].details.notes.map((note, idx) => (
                                        <li key={idx} className="text-base-content/80">{note}</li>
                                    ))}
                                </ul>
                            </div>
                        )}

                        {/* Steps with Collapse */}
                        <div className="space-y-2">
                            {slides[currentSlide].content.map((item, index) => (
                                <div key={index} className="collapse bg-black border border-base-300/20">
                                    <input type="checkbox" className="peer" />
                                    <div className="collapse-title text-xl font-medium text-base-content/90 hover:text-primary transition-colors peer-checked:text-primary">
                                        {item}
                                    </div>
                                    <div className="collapse-content text-base-content/80">
                                        <div className="pt-4">
                                            <p>{slides[currentSlide].details.description[0]}</p>
                                            {slides[currentSlide].details.functionCalls && (
                                                <div className="mt-4 bg-base-300/10 p-3 rounded">
                                                    <code className="text-primary">{slides[currentSlide].details.functionCalls[0].name}</code>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </motion.div>
                </AnimatePresence>
            </div>

            {/* Navigation Section */}
            <div className="mt-8 flex flex-col items-center gap-4">
                {/* Slide Indicators */}
                <div className="flex space-x-2 mb-4">
                    {slides.map((_, index) => (
                        <button
                            key={index}
                            onClick={() => setCurrentSlide(index)}
                            className={`w-2 h-2 rounded-full transition-colors ${currentSlide === index ? "bg-primary" : "bg-base-300"
                                }`}
                        />
                    ))}
                </div>

                {/* Navigation Buttons */}
                <div className="flex justify-center space-x-4">
                    <button
                        onClick={prevSlide}
                        className="btn btn-circle btn-primary"
                    >
                        ←
                    </button>
                    <button
                        onClick={nextSlide}
                        className="btn btn-circle btn-primary"
                    >
                        →
                    </button>
                </div>
            </div>
        </div>
    );
}; 