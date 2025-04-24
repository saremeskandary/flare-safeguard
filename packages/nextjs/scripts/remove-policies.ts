const { getDb: getRemovePoliciesDb } = require('../lib/db-commonjs.js');

const removePolicies = async () => {
  try {
    console.log('Connecting to database...');
    const db = await getRemovePoliciesDb();

    // Delete all documents from the policies collection
    const result = await db.collection('policies').deleteMany({});

    console.log(`Successfully removed ${result.deletedCount} policies.`);
  } catch (error) {
    console.error('Error removing policies:', error);
  }
};

// Run the removal function
removePolicies(); 