import { NextResponse } from "next/server";

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const contractName = searchParams.get("contract");
    const functionName = searchParams.get("function");
    const args = searchParams.get("args");

    if (!contractName || !functionName) {
      return NextResponse.json({ error: "Missing required parameters" }, { status: 400 });
    }

    // We'll need to implement a server-side contract getter
    // For now, we'll return a mock response
    return NextResponse.json({
      data: {
        success: true,
        message: `Read ${functionName} from ${contractName}`,
        args: args ? JSON.parse(args) : []
      }
    });
  } catch (error) {
    console.error("API Error:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { contractName, functionName, args } = body;

    if (!contractName || !functionName) {
      return NextResponse.json({ error: "Missing required parameters" }, { status: 400 });
    }

    // We'll need to implement a server-side contract getter
    // For now, we'll return a mock response
    return NextResponse.json({
      data: {
        success: true,
        message: `Executed ${functionName} on ${contractName}`,
        args: args || []
      }
    });
  } catch (error) {
    console.error("API Error:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
} 