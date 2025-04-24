db = db.getSiblingDB('safeguard');

// Create collections
db.createCollection('policies');
db.createCollection('claims');
db.createCollection('users');
db.createCollection('tokens');

// Create indexes for policies
db.policies.createIndex({ holder: 1 });
db.policies.createIndex({ status: 1 });
db.policies.createIndex({ startDate: 1 });
db.policies.createIndex({ endDate: 1 });

// Create indexes for claims
db.claims.createIndex({ policyId: 1 });
db.claims.createIndex({ status: 1 });
db.claims.createIndex({ timestamp: 1 });

// Create indexes for users
db.users.createIndex({ address: 1 }, { unique: true });
db.users.createIndex({ policies: 1 });
db.users.createIndex({ claims: 1 });

// Create indexes for tokens
db.tokens.createIndex({ symbol: 1 }, { unique: true });
db.tokens.createIndex({ address: 1 }, { unique: true });
db.tokens.createIndex({ category: 1 });

// Create a user for the application
db.users.insertOne({
  address: '0x0000000000000000000000000000000000000000',
  policies: [],
  claims: [],
  createdAt: new Date(),
  updatedAt: new Date()
}); 