import { useState, useEffect } from 'react';

interface InsuranceOption {
  id: string;
  name: string;
  value: number;
  premiumRate: number;
  description: string;
  createdAt: Date;
  updatedAt: Date;
}

export const useInsuranceOptions = () => {
  const [options, setOptions] = useState<InsuranceOption[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchOptions = async () => {
      try {
        setIsLoading(true);
        const response = await fetch('/api/insurance-options');

        if (!response.ok) {
          throw new Error(`Error fetching insurance options: ${response.statusText}`);
        }

        const data = await response.json();
        setOptions(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An unknown error occurred');
        console.error('Error fetching insurance options:', err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchOptions();
  }, []);

  return { options, isLoading, error };
}; 