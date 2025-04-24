import { NextApiRequest, NextApiResponse } from 'next';
import { getDb } from '../../../lib/db-commonjs.js';
import { TokenInfo } from '../../../utils/tokenAddresses';

interface TokenDocument extends TokenInfo {
  createdAt: Date;
  updatedAt: Date;
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  try {
    const { identifier } = req.query;
    const db = await getDb();

    // Check if identifier is an address (starts with 0x) or a symbol
    const isAddress = typeof identifier === 'string' && identifier.startsWith('0x');
    const query = isAddress
      ? { address: { $regex: new RegExp(`^${identifier}$`, 'i') } }
      : { symbol: { $regex: new RegExp(`^${identifier}$`, 'i') } };

    const token = await db.collection('tokens').findOne(query) as TokenDocument | null;

    if (!token) {
      return res.status(404).json({ error: 'Token not found' });
    }

    const { createdAt, updatedAt, ...tokenInfo } = token;
    return res.status(200).json(tokenInfo);
  } catch (error) {
    console.error('Error in token API:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
} 