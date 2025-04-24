import { getDb } from '../lib/db-commonjs.js';

const removeTokens = async () => {
  try {
    console.log('Connecting to database...');
    const db = await getDb();

    // Delete all documents from the tokens collection
    const result = await db.collection('tokens').deleteMany({});

    console.log(`Successfully removed ${result.deletedCount} tokens.`);
  } catch (error) {
    console.error('Error removing tokens:', error);
  }
};

removeTokens(); 