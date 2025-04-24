const { getDb: getRemoveAllDb } = require('../lib/db-commonjs.js');

const removeAllSeedData = async () => {
  try {
    console.log('Connecting to database...');
    const db = await getRemoveAllDb();

    // Delete all documents from the insuranceOptions collection
    const insuranceResult = await db.collection('insuranceOptions').deleteMany({});
    console.log(`Successfully removed ${insuranceResult.deletedCount} insurance options.`);

    // Delete all documents from the claims collection
    const claimsResult = await db.collection('claims').deleteMany({});
    console.log(`Successfully removed ${claimsResult.deletedCount} claims.`);

    // Delete all documents from the policies collection
    const policiesResult = await db.collection('policies').deleteMany({});
    console.log(`Successfully removed ${policiesResult.deletedCount} policies.`);

    console.log('All seed data has been removed successfully.');
  } catch (error) {
    console.error('Error removing seed data:', error);
  }
};

// Run the removal function
removeAllSeedData(); 