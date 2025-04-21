import { NextResponse } from 'next/server';
import { storePolicy } from '~~/lib/ipfs';
import { Policy } from '~~/types';
import { getDb } from '~~/lib/db-commonjs.js';

export async function GET() {
  try {
    const db = await getDb();
    const policies = await db.collection('policies').find().toArray();
    return NextResponse.json(policies);
  } catch (error) {
    console.error('Error fetching policies:', error);
    return NextResponse.json({ error: 'Failed to fetch policies' }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const data = await req.json();
    const db = await getDb();

    // Store policy data on IPFS
    const ipfsHash = await storePolicy(data);

    // Add metadata to policy
    const policy: Policy = {
      ...data,
      ipfsHash,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const result = await db.collection('policies').insertOne(policy);

    return NextResponse.json({
      success: true,
      policyId: result.insertedId,
      ipfsHash
    });
  } catch (error) {
    console.error('Error creating policy:', error);
    return NextResponse.json({ error: 'Failed to create policy' }, { status: 500 });
  }
} 