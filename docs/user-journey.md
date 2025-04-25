# Flare Safeguard - User Journey Document

## Overview
This document outlines the normal user journey for interacting with the Flare Safeguard insurance system. The system provides insurance coverage for tokenized real-world assets (RWAs) with a focus on security, transparency, and efficient claim processing.

## User Journey Flow

### 1. Initial Setup and Policy Creation
1. **User Registration**
   - User connects their wallet to the Flare Safeguard platform
   - System verifies user's wallet address and basic requirements
   - Function calls:
     - `TokenRWA.verifyHolder(bytes32 requestId, bytes calldata proof)` - Verifies user's wallet

2. **Token Evaluation**
   - System evaluates the RWA token the user wants to insure
   - Evaluation includes:
     - Token liquidity analysis
     - Trading volume metrics
     - Historical price volatility
     - Market stability assessment
     - Asset backing verification
   - System assigns a risk score (1-100)
   - Function calls:
     - `InsuranceCore.evaluateRWA(address tokenAddress, uint256 value, uint256 riskScore)` - Records token evaluation
     - `InsuranceCore.getRWAEvaluation(address tokenAddress)` - Retrieves evaluation details

3. **Policy Selection**
   - User views available coverage options based on:
     - Coverage limits
     - Premium rates
     - Duration options
   - System calculates personalized premium based on:
     - Selected coverage amount
     - Policy duration
     - Token's risk score
   - Function calls:
     - `InsuranceCore.getCoverageOption(uint256 optionId)` - Retrieves coverage options
     - `InsuranceCore.calculatePremium(uint256 coverageAmount, uint256 duration, address tokenAddress)` - Calculates premium

4. **Policy Creation**
   - User reviews policy terms and premium calculation
   - User approves and pays premium in BSD tokens
   - System creates insurance policy
   - Policy details are recorded on-chain
   - User receives policy confirmation
   - Function calls:
     - `ClaimProcessor.createPolicy(address tokenAddress, uint256 coverageAmount, uint256 premium, uint256 duration)` - Creates insurance policy
     - `ClaimProcessor.getPolicy(address insured)` - Retrieves policy details

### 2. Policy Management
1. **Policy Monitoring**
   - User can view active policy details:
     - Coverage amount
     - Premium paid
     - Policy duration
     - Coverage status
   - System tracks policy expiration
   - Function calls:
     - `ClaimProcessor.getPolicy(address insured)` - Retrieves policy details
     - `InsuranceAutomation.getInsuranceTasks(address _insuranceContract)` - Checks for scheduled tasks

2. **Policy Renewal**
   - System notifies user before policy expiration
   - User can review and renew policy
   - New premium calculation based on updated risk assessment
   - User approves renewal and pays new premium
   - Function calls:
     - `InsuranceAutomation.createTask(address _insuranceContract, uint256 _dueDate)` - Schedules renewal
     - `InsuranceAutomation.executeTask(bytes32 _taskId)` - Executes renewal task
     - `TokenInsurance.payInsurance()` - Processes renewal payment

### 3. Claim Process
1. **Claim Initiation**
   - User initiates claim through platform
   - System verifies:
     - Active policy status
     - Claim amount within coverage limits
     - Policy validity period
   - Function calls:
     - `ClaimProcessor.getPolicy(address insured)` - Verifies policy status

2. **Claim Submission**
   - User provides:
     - Claim amount
     - Description of loss/incident
     - Supporting documentation
   - System records claim details on-chain
   - Function calls:
     - `ClaimProcessor.submitClaim(uint256 amount, string memory description)` - Submits claim
     - `CrossChainClaimProcessor.submitCrossChainClaim(uint256 _amount, bytes32 _transactionHash, uint256 _chainId, uint16 _requiredConfirmations)` - For cross-chain claims

3. **Claim Verification**
   - System initiates verification process:
     - Automated checks
     - Owner review if required
     - Cross-chain verification for cross-chain claims
   - Verification status updates are recorded
   - Function calls:
     - `ClaimProcessor.reviewClaim(uint256 claimId, bool approved, string memory reason)` - Reviews claim
     - `CrossChainClaimProcessor.verifyCrossChainClaim(uint256 _claimId, bytes calldata _proof)` - Verifies cross-chain claim

4. **Claim Resolution**
   - If approved:
     - System processes payout in USDT
     - User receives claim amount
     - Policy status updated
   - If rejected:
     - User notified with rejection reason
     - Appeal process available if applicable
   - Function calls:
     - `ClaimProcessor.processClaimPayout(uint256 claimId)` - Processes approved claim
     - `Vault.processClaim(bytes32 requestId, bytes calldata proof, uint256 amount)` - Handles claim payout
     - `CrossChainClaimProcessor.processCrossChainClaim(uint256 _claimId)` - Processes cross-chain claim

### 4. Post-Claim
1. **Claim History**
   - User can view:
     - All submitted claims
     - Claim statuses
     - Payout history
     - Policy modifications
   - Function calls:
     - `ClaimProcessor.getUserClaims(address user)` - Retrieves user's claims
     - `ClaimProcessor.getClaimDetails(uint256 claimId)` - Gets claim details

2. **Policy Adjustments**
   - User can:
     - Modify coverage amounts
     - Update policy duration
     - Cancel policy (if allowed)
   - System recalculates premiums for any changes
   - Function calls:
     - `InsuranceCore.calculatePremium(uint256 coverageAmount, uint256 duration, address tokenAddress)` - Recalculates premium
     - `ClaimProcessor.createPolicy(address tokenAddress, uint256 coverageAmount, uint256 premium, uint256 duration)` - Creates new policy

## System Features
- Real-time policy management
- Automated claim processing
- Cross-chain claim support
- Transparent premium calculation
- Secure fund management
- Automated policy renewals
- Comprehensive claim tracking

## Security Measures
- Multi-step verification process
- Ownership-based access control
- Secure fund handling
- Cross-chain security protocols
- Automated risk assessment
- Fraud detection systems

## Support and Assistance
- 24/7 system availability
- Automated notifications
- Policy management assistance
- Claim process guidance
- Technical support access
- Documentation and resources 