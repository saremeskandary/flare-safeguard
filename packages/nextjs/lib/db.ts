import { MongoClient } from 'mongodb';

const uri = process.env.MONGODB_URI || 'mongodb://admin:password@localhost:27017/safeguard?authSource=admin';
const options = {};

let client: MongoClient;
let clientPromise: Promise<MongoClient>;

interface GlobalWithMongo {
  _mongoClientPromise?: Promise<MongoClient>;
}

if (process.env.NODE_ENV === 'development') {
  // In development mode, use a global variable so that the value
  // is preserved across module reloads caused by HMR (Hot Module Replacement).
  let globalWithMongo = global as unknown as GlobalWithMongo;

  if (!globalWithMongo._mongoClientPromise) {
    client = new MongoClient(uri, options);
    globalWithMongo._mongoClientPromise = client.connect();
  }
  clientPromise = globalWithMongo._mongoClientPromise!;
} else {
  // In production mode, it's best to not use a global variable.
  client = new MongoClient(uri, options);
  clientPromise = client.connect();
}

// Export a module-scoped MongoClient promise. By doing this in a
// separate module, the client can be shared across functions.
export const getDb = async () => {
  const client = await clientPromise;
  return client.db('safeguard');
}; 