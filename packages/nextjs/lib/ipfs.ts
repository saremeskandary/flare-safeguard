import { Web3Storage } from 'web3.storage';

if (!process.env.WEB3_STORAGE_TOKEN) {
  throw new Error('Please add your Web3.Storage token to .env.local');
}

const client = new Web3Storage({ token: process.env.WEB3_STORAGE_TOKEN });

export async function storePolicy(policyData: any) {
  try {
    const blob = new Blob([JSON.stringify(policyData)], { type: 'application/json' });
    const file = new File([blob], `policy-${Date.now()}.json`, { type: 'application/json' });
    const cid = await client.put([file]);
    return cid;
  } catch (error) {
    console.error('Error storing policy on IPFS:', error);
    throw error;
  }
}

export async function retrievePolicy(cid: string) {
  try {
    const res = await client.get(cid);
    if (!res?.ok) {
      throw new Error(`Failed to get ${cid}`);
    }
    const data = await res.json();
    return data;
  } catch (error) {
    console.error('Error retrieving policy from IPFS:', error);
    throw error;
  }
} 