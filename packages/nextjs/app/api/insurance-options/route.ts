import { NextResponse } from 'next/server';
import { getDb } from '~~/lib/db-commonjs.js';

export async function GET() {
  try {
    const db = await getDb();
    const options = await db.collection('insuranceOptions').find().toArray();
    return NextResponse.json(options);
  } catch (error) {
    console.error('Error fetching insurance options:', error);
    return NextResponse.json({ error: 'Failed to fetch insurance options' }, { status: 500 });
  }
} 