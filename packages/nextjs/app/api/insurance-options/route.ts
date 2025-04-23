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

export async function POST(request: Request) {
  try {
    const db = await getDb();
    const data = await request.json();

    // Validate required fields
    const requiredFields = ['id', 'name', 'value', 'premiumRate', 'description'];
    for (const field of requiredFields) {
      if (!data[field]) {
        return NextResponse.json(
          { error: `Missing required field: ${field}` },
          { status: 400 }
        );
      }
    }

    // Check if option with same ID already exists
    const existingOption = await db.collection('insuranceOptions').findOne({ id: data.id });
    if (existingOption) {
      return NextResponse.json(
        { error: 'Insurance option with this ID already exists' },
        { status: 409 }
      );
    }

    // Add timestamps
    const newOption = {
      ...data,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await db.collection('insuranceOptions').insertOne(newOption);
    return NextResponse.json(newOption, { status: 201 });
  } catch (error) {
    console.error('Error creating insurance option:', error);
    return NextResponse.json(
      { error: 'Failed to create insurance option' },
      { status: 500 }
    );
  }
} 