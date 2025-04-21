export interface Policy {
  id: string;
  holder: string;
  coverageAmount: number;
  premium: number;
  startDate: Date;
  endDate: Date;
  status: 'active' | 'claimed' | 'expired';
  ipfsHash?: string;
  description?: string;
  type: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Claim {
  id: string;
  policyId: string;
  amount: number;
  status: 'pending' | 'approved' | 'rejected';
  timestamp: Date;
  description: string;
  evidence?: string; // IPFS hash for evidence documents
  processedBy?: string;
  processedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface User {
  id: string;
  address: string;
  policies: string[]; // Array of policy IDs
  claims: string[]; // Array of claim IDs
  createdAt: Date;
  updatedAt: Date;
}

module.exports = {
  Policy,
  Claim,
  User
}; 