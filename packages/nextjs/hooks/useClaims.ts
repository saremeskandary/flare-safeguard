import { useState, useEffect } from 'react';
import { Claim } from '~~/types';

export const useClaims = () => {
  const [claims, setClaims] = useState<Claim[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchClaims = async () => {
      try {
        setIsLoading(true);
        const response = await fetch('/api/claims');

        if (!response.ok) {
          throw new Error(`Failed to fetch claims: ${response.statusText}`);
        }

        const data = await response.json();
        setClaims(data);
        setError(null);
      } catch (err) {
        console.error('Error fetching claims:', err);
        setError(err instanceof Error ? err.message : 'Failed to fetch claims');
      } finally {
        setIsLoading(false);
      }
    };

    fetchClaims();
  }, []);

  return { claims, isLoading, error };
}; 