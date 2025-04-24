import { createHeliaHTTP } from '@helia/http';
import { json } from '@helia/json';
import { CID } from 'multiformats/cid';

// Create a Helia instance with HTTP transport
const heliaPromise = createHeliaHTTP();

export async function storePolicy(policyData: any) {
  try {
    const helia = await heliaPromise;
    const j = json(helia);
    // Convert policy data to JSON and add it to IPFS
    const cid = await j.add(policyData);
    return cid.toString();
  } catch (error) {
    console.error('Error storing policy on IPFS:', error);
    throw error;
  }
}

export async function retrievePolicy(cid: string) {
  try {
    const helia = await heliaPromise;
    const j = json(helia);
    // Retrieve and parse the JSON data from IPFS
    const data = await j.get(CID.parse(cid));
    return data;
  } catch (error) {
    console.error('Error retrieving policy from IPFS:', error);
    throw error;
  }
} 