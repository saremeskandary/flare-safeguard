import { NextApiRequest, NextApiResponse } from 'next';
import { getDb } from '../../../lib/db-commonjs.js';
import { TokenInfo } from '../../../utils/tokenAddresses';

interface TokenDocument extends TokenInfo {
  createdAt: Date;
  updatedAt: Date;
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  try {
    const db = await getDb();

    switch (req.method) {
      case 'GET':
        // Get all tokens
        const tokens = await db.collection('tokens').find({}).toArray() as TokenDocument[];
        const formattedTokens = tokens.map(({ createdAt, updatedAt, ...token }) => token);
        return res.status(200).json(formattedTokens);

      case 'POST':
        // Add a new token
        const newToken: TokenInfo = req.body;
        await db.collection('tokens').insertOne({
          ...newToken,
          createdAt: new Date(),
          updatedAt: new Date()
        });
        return res.status(201).json({ message: 'Token added successfully' });

      default:
        res.setHeader('Allow', ['GET', 'POST']);
        return res.status(405).end(`Method ${req.method} Not Allowed`);
    }
  } catch (error) {
    console.error('Error in tokens API:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
} 