import { NextResponse } from 'next/server';
import { getDb } from '~~/lib/db';
import { storePolicy } from '~~/lib/ipfs';
import { Claim } from '~~/types';

export async function GET() {
  try {
    const db = await getDb();
    const claims = await db.collection('claims').find().toArray();
    return NextResponse.json(claims);
  } catch (error) {
    console.error('Error fetching claims:', error);
    return NextResponse.json({ error: 'Failed to fetch claims' }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const data = await req.json();
    const db = await getDb();

    // Store evidence on IPFS if provided
    let evidenceHash;
    if (data.evidence) {
      evidenceHash = await storePolicy(data.evidence);
    }

    // Create claim with metadata
    const claim: Claim = {
      ...data,
      evidence: evidenceHash,
      status: 'pending',
      timestamp: new Date(),
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const result = await db.collection('claims').insertOne(claim);

    // Update policy status if needed
    if (data.policyId) {
      await db.collection('policies').updateOne(
        { _id: data.policyId },
        { $set: { status: 'claimed', updatedAt: new Date() } }
      );
    }

    return NextResponse.json({
      success: true,
      claimId: result.insertedId,
      evidenceHash
    });
  } catch (error) {
    console.error('Error creating claim:', error);
    return NextResponse.json({ error: 'Failed to create claim' }, { status: 500 });
  }
} 