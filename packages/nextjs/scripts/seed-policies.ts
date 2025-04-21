const { getDb: getPoliciesDb } = require('../lib/db-commonjs.js');
const { Policy } = require('../types/models.js');

const USER_ADDRESS = '0x248dcc886995dd097Dc47b8561584D6479cF7772';

const seedPolicies = async () => {
  try {
    console.log('Connecting to database...');
    const db = await getPoliciesDb();

    // Check if policies collection exists and has data
    const policiesCount = await db.collection('policies').countDocuments();

    if (policiesCount > 0) {
      console.log(`Database already has ${policiesCount} policies. Skipping seed.`);
      return;
    }

    console.log('Seeding policies data...');

    const samplePolicies = [
      new Policy({
        id: 'POL-001',
        holder: USER_ADDRESS,
        tokenId: 'REAL-ESTATE-001',
        tokenName: 'Real Estate Project 001',
        coverageAmount: 75000,
        premiumAmount: 1875,
        startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 30 days ago
        endDate: new Date(Date.now() + 335 * 24 * 60 * 60 * 1000), // 335 days from now
        status: 'active',
        createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        updatedAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
      }),
      new Policy({
        id: 'POL-002',
        holder: USER_ADDRESS,
        tokenId: 'REAL-ESTATE-002',
        tokenName: 'Real Estate Project 002',
        coverageAmount: 112500,
        premiumAmount: 3375,
        startDate: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000), // 60 days ago
        endDate: new Date(Date.now() + 305 * 24 * 60 * 60 * 1000), // 305 days from now
        status: 'active',
        createdAt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000),
        updatedAt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000),
      }),
      new Policy({
        id: 'POL-003',
        holder: USER_ADDRESS,
        tokenId: 'REAL-ESTATE-003',
        tokenName: 'Real Estate Project 003',
        coverageAmount: 150000,
        premiumAmount: 3500,
        startDate: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000), // 15 days ago
        endDate: new Date(Date.now() + 350 * 24 * 60 * 60 * 1000), // 350 days from now
        status: 'active',
        createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000),
        updatedAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000),
      }),
    ];

    const result = await db.collection('policies').insertMany(samplePolicies);

    console.log(`Successfully seeded ${result.insertedCount} policies.`);
  } catch (error) {
    console.error('Error seeding policies:', error);
  }
};

// Run the seed function
seedPolicies(); 