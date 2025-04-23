const { getDb } = require('../lib/db-commonjs.js');

const removeClaims = async () => {
  try {
    console.log('Connecting to database...');
    const db = await getDb();

    // Delete all documents from the claims collection
    const result = await db.collection('claims').deleteMany({});

    console.log(`Successfully removed ${result.deletedCount} claims.`);
  } catch (error) {
    console.error('Error removing claims:', error);
  }
};

// Run the removal function
removeClaims(); 