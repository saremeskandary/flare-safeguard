import { useState, useEffect } from 'react';

interface Policy {
  id: string;
  holder: string;
  tokenId: string;
  tokenName: string;
  coverageAmount: number;
  premiumAmount: number;
  startDate: Date;
  endDate: Date;
  status: string;
  createdAt: Date;
  updatedAt: Date;
}

export const usePolicies = () => {
  const [policies, setPolicies] = useState<Policy[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchPolicies = async () => {
      try {
        setIsLoading(true);
        const response = await fetch('/api/policies');

        if (!response.ok) {
          throw new Error(`Error fetching policies: ${response.statusText}`);
        }

        const data = await response.json();
        setPolicies(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An unknown error occurred');
        console.error('Error fetching policies:', err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchPolicies();
  }, []);

  return { policies, isLoading, error };
}; 