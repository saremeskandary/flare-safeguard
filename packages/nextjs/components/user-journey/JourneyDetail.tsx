import { motion } from "framer-motion";

type JourneyStep = {
    title: string;
    description: string[];
    functionCalls?: {
        name: string;
        description: string;
    }[];
    notes?: string[];
};

type JourneyDetailProps = {
    step: JourneyStep;
    onClose: () => void;
};

export const JourneyDetail = ({ step, onClose }: JourneyDetailProps) => {
    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 20 }}
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
            onClick={onClose}
        >
            <div
                className="bg-base-100 rounded-lg shadow-xl max-w-2xl w-full p-6"
                onClick={e => e.stopPropagation()}
            >
                <div className="flex justify-between items-start mb-4">
                    <h3 className="text-2xl font-bold text-primary">{step.title}</h3>
                    <button onClick={onClose} className="btn btn-ghost btn-sm btn-circle">
                        ✕
                    </button>
                </div>

                <div className="space-y-6">
                    {/* Description */}
                    <div>
                        <h4 className="text-lg font-semibold mb-2">Description</h4>
                        <ul className="list-disc list-inside space-y-2">
                            {step.description.map((desc, index) => (
                                <li key={index} className="text-base-content/90">{desc}</li>
                            ))}
                        </ul>
                    </div>

                    {/* Function Calls */}
                    {step.functionCalls && (
                        <div>
                            <h4 className="text-lg font-semibold mb-2">Function Calls</h4>
                            <div className="space-y-3">
                                {step.functionCalls.map((func, index) => (
                                    <div key={index} className="bg-base-200 p-3 rounded-lg">
                                        <code className="text-primary font-mono">{func.name}</code>
                                        <p className="mt-1 text-base-content/90">{func.description}</p>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Additional Notes */}
                    {step.notes && (
                        <div>
                            <h4 className="text-lg font-semibold mb-2">Additional Notes</h4>
                            <ul className="list-disc list-inside space-y-2">
                                {step.notes.map((note, index) => (
                                    <li key={index} className="text-base-content/90">{note}</li>
                                ))}
                            </ul>
                        </div>
                    )}
                </div>
            </div>
        </motion.div>
    );
}; 