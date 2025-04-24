import { TokenInfo } from '../utils/tokenAddresses';

export const addToken = async (token: TokenInfo): Promise<void> => {
  const response = await fetch('/api/tokens', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(token),
  });

  if (!response.ok) {
    throw new Error('Failed to add token');
  }
};

export const getAllTokens = async (): Promise<TokenInfo[]> => {
  const response = await fetch('/api/tokens');

  if (!response.ok) {
    throw new Error('Failed to fetch tokens');
  }

  return await response.json();
};

export const getTokenByAddress = async (address: string): Promise<TokenInfo | null> => {
  try {
    const response = await fetch(`/api/tokens/${address}`);

    if (response.status === 404) {
      return null;
    }

    if (!response.ok) {
      throw new Error('Failed to fetch token');
    }

    return await response.json();
  } catch (error) {
    console.error('Error fetching token by address:', error);
    return null;
  }
};

export const getTokenBySymbol = async (symbol: string): Promise<TokenInfo | null> => {
  try {
    const response = await fetch(`/api/tokens/${symbol}`);

    if (response.status === 404) {
      return null;
    }

    if (!response.ok) {
      throw new Error('Failed to fetch token');
    }

    return await response.json();
  } catch (error) {
    console.error('Error fetching token by symbol:', error);
    return null;
  }
};

export const isValidTokenAddress = async (address: string): Promise<boolean> => {
  try {
    const response = await fetch(`/api/tokens/${address}`);
    return response.status === 200;
  } catch (error) {
    console.error('Error checking token address:', error);
    return false;
  }
}; 