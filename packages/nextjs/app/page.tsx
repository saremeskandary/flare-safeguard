import { UserJourneySlides } from "~~/components/user-journey/UserJourneySlides";
import Link from "next/link";

export default function Home() {
  return (
    <div className="min-h-screen bg-base-200">
      {/* Hero Section */}
      <div className="hero min-h-[60vh] bg-base-100">
        <div className="hero-content text-center">
          <div className="max-w-3xl">
            <h1 className="text-5xl font-bold text-primary mb-8">Welcome to Flare Safeguard</h1>
            <p className="text-xl mb-8 text-base-content">
              Your trusted insurance solution for Real World Assets on the Flare Network.
              Secure, transparent, and reliable protection for your digital assets.
            </p>
            <div className="flex gap-4 justify-center">
              <Link href="/dashboard" className="btn btn-primary btn-lg">
                Go to Dashboard
              </Link>
              <a href="#journey" className="btn btn-secondary btn-lg">
                Learn More
              </a>
            </div>
          </div>
        </div>
      </div>

      {/* Features Section */}
      <div className="py-16 bg-base-200">
        <div className="container mx-auto px-4">
          <h2 className="text-3xl font-bold text-center mb-12 text-base-content">Why Choose Flare Safeguard?</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="card bg-base-100 shadow-xl">
              <div className="card-body">
                <h3 className="card-title text-primary">Secure & Transparent</h3>
                <p>Built on blockchain technology ensuring complete transparency and security for all insurance operations.</p>
              </div>
            </div>
            <div className="card bg-base-100 shadow-xl">
              <div className="card-body">
                <h3 className="card-title text-primary">Real World Asset Protection</h3>
                <p>Comprehensive insurance coverage for your real-world assets tokenized on the blockchain.</p>
              </div>
            </div>
            <div className="card bg-base-100 shadow-xl">
              <div className="card-body">
                <h3 className="card-title text-primary">Cross-Chain Compatibility</h3>
                <p>Seamless cross-chain operations for claims and verifications across different blockchain networks.</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* User Journey Section */}
      <div id="journey" className="py-16 bg-base-100">
        <div className="container mx-auto px-4">
          <h2 className="text-3xl font-bold text-center mb-4 text-base-content">Complete User Journey</h2>
          <p className="text-center mb-12 text-base-content/80 max-w-2xl mx-auto">
            Experience our comprehensive insurance process from token creation to claim resolution.
            Each step is designed to provide you with the best possible protection for your assets.
          </p>
          <UserJourneySlides />
        </div>
      </div>
    </div>
  );
}
