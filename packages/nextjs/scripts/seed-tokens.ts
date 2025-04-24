import { getDb } from '../lib/db-commonjs.js';
import { FLARE_TESTNET_TOKENS } from '../utils/tokenAddresses';

const seedTokens = async () => {
  try {
    console.log('Connecting to database...');
    const db = await getDb();

    // Check if tokens collection exists and has data
    const tokensCount = await db.collection('tokens').countDocuments();

    if (tokensCount > 0) {
      console.log(`Database already has ${tokensCount} tokens. Skipping seed.`);
      return;
    }

    console.log('Seeding tokens data...');

    const tokens = FLARE_TESTNET_TOKENS.map(token => ({
      ...token,
      createdAt: new Date(),
      updatedAt: new Date()
    }));

    const result = await db.collection('tokens').insertMany(tokens);

    console.log(`Successfully seeded ${result.insertedCount} tokens.`);
  } catch (error) {
    console.error('Error seeding tokens:', error);
  }
};

seedTokens(); 