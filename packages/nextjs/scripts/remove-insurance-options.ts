const { getDb: getRemoveInsuranceDb } = require('../lib/db-commonjs.js');

const removeInsuranceOptions = async () => {
  try {
    console.log('Connecting to database...');
    const db = await getRemoveInsuranceDb();

    // Delete all documents from the insuranceOptions collection
    const result = await db.collection('insuranceOptions').deleteMany({});

    console.log(`Successfully removed ${result.deletedCount} insurance options.`);
  } catch (error) {
    console.error('Error removing insurance options:', error);
  }
};

// Run the removal function
removeInsuranceOptions(); 