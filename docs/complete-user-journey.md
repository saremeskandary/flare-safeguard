# Flare Safeguard - Complete User Journey

## Overview
This document outlines the complete user journey for the Flare Safeguard insurance system, from the initial token creation to the final claim resolution. It provides a step-by-step guide of what happens in the process, in chronological order.

## Complete Journey Flow

### 1. Token Creation and Setup
1. **Create RWA Token**
   - Owner creates a new Real World Asset (RWA) token
   - Function calls:
     - `TokenRWA` constructor - Creates the token with name, symbol, and data verification address
   - This token represents a real-world asset on the blockchain

2. **Token Verification Setup**
   - Token owner sets up verification mechanisms
   - Function calls:
     - `TokenRWA.verifyHolder(bytes32 requestId, bytes calldata proof)` - Verifies token holders
   - This ensures only verified entities can hold the token

3. **Enable Token Transfers**
   - Token owner enables transfers after initial setup
   - Function calls:
     - `TokenRWA` internal functions to enable transfers
   - Token becomes available for trading and insurance

### 2. Insurance System Setup
1. **Deploy Insurance Contracts**
   - System owner deploys the core insurance contracts:
     - `InsuranceCore` - For risk assessment and premium calculation
     - `ClaimProcessor` - For handling claims
     - `Vault` - For managing insurance reserves
     - `TokenInsurance` - For insurance token functionality
     - `CrossChainClaimProcessor` - For cross-chain operations

2. **Configure Coverage Options**
   - Owner sets up available insurance coverage options
   - Function calls:
     - `InsuranceCore.addCoverageOption(uint256 coverageLimit, uint256 premiumRate, uint256 minDuration, uint256 maxDuration)` - Creates coverage options
   - These options define the insurance products available to users

### 3. User Journey - Getting Insurance
1. **User Registration**
   - User connects their wallet to the Flare Safeguard platform
   - User verifies their identity
   - Function calls:
     - `TokenRWA.verifyHolder(bytes32 requestId, bytes calldata proof)` - Verifies user's wallet

2. **Token Evaluation**
   - System evaluates the RWA token the user wants to insure
   - Evaluation includes liquidity, volume, volatility, and market stability
   - System assigns a risk score (1-100)
   - Function calls:
     - `InsuranceCore.evaluateRWA(address tokenAddress, uint256 value, uint256 riskScore)` - Records token evaluation
     - `InsuranceCore.getRWAEvaluation(address tokenAddress)` - Retrieves evaluation details

3. **Policy Selection**
   - User views available coverage options
   - System calculates personalized premium
   - Function calls:
     - `InsuranceCore.getCoverageOption(uint256 optionId)` - Retrieves coverage options
     - `InsuranceCore.calculatePremium(uint256 coverageAmount, uint256 duration, address tokenAddress)` - Calculates premium

4. **Policy Creation**
   - User reviews policy terms and premium
   - User approves and pays premium in BSD tokens
   - System creates insurance policy
   - Function calls:
     - `ClaimProcessor.createPolicy(address tokenAddress, uint256 coverageAmount, uint256 premium, uint256 duration)` - Creates insurance policy
     - `ClaimProcessor.getPolicy(address insured)` - Retrieves policy details

5. **Policy Activation**
   - System activates the policy
   - User receives confirmation
   - Policy details are recorded on-chain
   - Coverage period begins

### 4. Policy Management
1. **Policy Monitoring**
   - User monitors active policy
   - System tracks policy expiration
   - Function calls:
     - `ClaimProcessor.getPolicy(address insured)` - Retrieves policy details
     - `InsuranceAutomation.getInsuranceTasks(address _insuranceContract)` - Checks for scheduled tasks

2. **Policy Renewal**
   - System notifies user before expiration
   - User reviews and renews policy
   - New premium calculation based on updated risk assessment
   - Function calls:
     - `InsuranceAutomation.createTask(address _insuranceContract, uint256 _dueDate)` - Schedules renewal
     - `InsuranceAutomation.executeTask(bytes32 _taskId)` - Executes renewal task
     - `TokenInsurance.payInsurance()` - Processes renewal payment

### 5. Incident Occurs
1. **Loss or Damage**
   - User experiences loss or damage to their RWA token
   - User documents the incident
   - User prepares evidence for claim

2. **Claim Initiation**
   - User initiates claim through platform
   - System verifies policy status
   - Function calls:
     - `ClaimProcessor.getPolicy(address insured)` - Verifies policy status

3. **Claim Submission**
   - User provides claim details and evidence
   - System records claim on-chain
   - Function calls:
     - `ClaimProcessor.submitClaim(uint256 amount, string memory description)` - Submits claim
     - `CrossChainClaimProcessor.submitCrossChainClaim(uint256 _amount, bytes32 _transactionHash, uint256 _chainId, uint16 _requiredConfirmations)` - For cross-chain claims

### 6. Claim Processing
1. **Initial Review**
   - System performs automated checks
   - Owner reviews claim details
   - Function calls:
     - `ClaimProcessor.reviewClaim(uint256 claimId, bool approved, string memory reason)` - Reviews claim

2. **Evidence Verification**
   - System verifies submitted evidence
   - For cross-chain claims, additional verification is performed
   - Function calls:
     - `CrossChainClaimProcessor.verifyCrossChainClaim(uint256 _claimId, bytes calldata _proof)` - Verifies cross-chain claim

3. **Claim Decision**
   - System makes decision on claim
   - User is notified of decision
   - If approved, claim moves to payout
   - If rejected, user receives rejection reason

### 7. Claim Resolution
1. **Payout Processing**
   - For approved claims, system processes payout
   - Payout is made in USDT for stability
   - Function calls:
     - `ClaimProcessor.processClaimPayout(uint256 claimId)` - Processes approved claim
     - `Vault.processClaim(bytes32 requestId, bytes calldata proof, uint256 amount)` - Handles claim payout
     - `CrossChainClaimProcessor.processCrossChainClaim(uint256 _claimId)` - Processes cross-chain claim

2. **Claim Completion**
   - User receives payout
   - Policy status is updated
   - Claim is marked as completed

### 8. Post-Claim
1. **Claim History**
   - User can view claim history
   - Function calls:
     - `ClaimProcessor.getUserClaims(address user)` - Retrieves user's claims
     - `ClaimProcessor.getClaimDetails(uint256 claimId)` - Gets claim details

2. **Policy Adjustments**
   - User can modify or cancel policy
   - System recalculates premiums
   - Function calls:
     - `InsuranceCore.calculatePremium(uint256 coverageAmount, uint256 duration, address tokenAddress)` - Recalculates premium
     - `ClaimProcessor.createPolicy(address tokenAddress, uint256 coverageAmount, uint256 premium, uint256 duration)` - Creates new policy

## System Components and Their Roles
- **TokenRWA**: Represents the real-world asset token
- **InsuranceCore**: Handles risk assessment and premium calculation
- **ClaimProcessor**: Manages insurance policies and claims
- **Vault**: Secures insurance reserves and processes payouts
- **TokenInsurance**: Provides insurance token functionality
- **CrossChainClaimProcessor**: Handles cross-chain insurance operations
- **InsuranceAutomation**: Automates policy renewals and other tasks
- **SafeguardMessageReceiver**: Manages cross-chain communication

## Key Events in the Journey
1. Token creation and verification
2. Insurance system setup and configuration
3. User registration and verification
4. Policy creation and activation
5. Policy management and renewal
6. Incident occurrence and documentation
7. Claim submission and verification
8. Claim resolution and payout
9. Post-claim activities and policy adjustments 