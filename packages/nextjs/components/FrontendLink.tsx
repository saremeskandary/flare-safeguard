import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";

const FrontendLink = () => {
    return (
        <a
            href="https://safeguard.sarem.online/"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-primary bg-base-200 rounded-lg hover:bg-base-300 transition-colors duration-200"
        >
            <span>Safeguard Frontend</span>
            <ArrowTopRightOnSquareIcon className="w-4 h-4" />
        </a>
    );
};

export default FrontendLink; 