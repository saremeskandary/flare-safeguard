const { getDb: getClaimsDb } = require('../lib/db-commonjs.js');
const { Claim } = require('../types/models.js');

const CLAIMS_USER_ADDRESS = '0x248dcc886995dd097Dc47b8561584D6479cF7772';

const seedClaims = async () => {
  try {
    console.log('Connecting to database...');
    const db = await getClaimsDb();

    // Check if claims collection exists and has data
    const claimsCount = await db.collection('claims').countDocuments();

    if (claimsCount > 0) {
      console.log(`Database already has ${claimsCount} claims. Skipping seed.`);
      return;
    }

    console.log('Seeding claims data...');

    const sampleClaims = [
      new Claim({
        id: 'CLM-001',
        policyId: 'POL-001',
        amount: 60000,
        status: 'approved',
        timestamp: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000), // 15 days ago
        description: 'Default event detected due to significant value drop in real estate project',
        evidence: 'ipfs://QmSampleEvidenceHash1',
        processedBy: USER_ADDRESS,
        processedAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000), // 10 days ago
        createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000),
        updatedAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
      }),
      new Claim({
        id: 'CLM-002',
        policyId: 'POL-002',
        amount: 45000,
        status: 'pending',
        timestamp: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000), // 5 days ago
        description: 'Potential default event detected, under investigation',
        evidence: 'ipfs://QmSampleEvidenceHash2',
        createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
        updatedAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
      }),
      new Claim({
        id: 'CLM-003',
        policyId: 'POL-003',
        amount: 30000,
        status: 'rejected',
        timestamp: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 30 days ago
        description: 'Claim rejected due to insufficient evidence of default event',
        evidence: 'ipfs://QmSampleEvidenceHash3',
        processedBy: USER_ADDRESS,
        processedAt: new Date(Date.now() - 25 * 24 * 60 * 60 * 1000), // 25 days ago
        createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        updatedAt: new Date(Date.now() - 25 * 24 * 60 * 60 * 1000),
      }),
    ];

    const result = await db.collection('claims').insertMany(sampleClaims);

    console.log(`Successfully seeded ${result.insertedCount} claims.`);
  } catch (error) {
    console.error('Error seeding claims:', error);
  }
};

// Run the seed function
seedClaims(); 