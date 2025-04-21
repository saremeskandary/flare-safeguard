const { getDb: getInsuranceDb } = require('../lib/db-commonjs.js');

const seedInsuranceOptions = async () => {
  try {
    console.log('Connecting to database...');
    const db = await getInsuranceDb();

    // Check if insurance options collection exists and has data
    const optionsCount = await db.collection('insuranceOptions').countDocuments();

    if (optionsCount > 0) {
      console.log(`Database already has ${optionsCount} insurance options. Skipping seed.`);
      return;
    }

    console.log('Seeding insurance options data...');

    const insuranceOptions = [
      {
        id: "REAL-ESTATE-001",
        name: "Real Estate Project 001",
        value: 100000,
        premiumRate: 2.5,
        description: "A real estate project token representing a commercial property in New York.",
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        id: "REAL-ESTATE-002",
        name: "Real Estate Project 002",
        value: 150000,
        premiumRate: 3.0,
        description: "A real estate project token representing a residential complex in London.",
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        id: "REAL-ESTATE-003",
        name: "Real Estate Project 003",
        value: 200000,
        premiumRate: 2.8,
        description: "A real estate project token representing a mixed-use development in Singapore.",
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ];

    const result = await db.collection('insuranceOptions').insertMany(insuranceOptions);

    console.log(`Successfully seeded ${result.insertedCount} insurance options.`);
  } catch (error) {
    console.error('Error seeding insurance options:', error);
  }
};

// Run the seed function
seedInsuranceOptions(); 