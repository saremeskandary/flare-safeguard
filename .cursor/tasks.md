# Dashboard Enhancement Tasks

## 1. Cross-Chain Claim Management
- [ ] Create new `CrossChainClaim.tsx` component
  - Add transaction hash input field
  - Add chain ID selection
  - Add claim amount input
  - Add required confirmations field
  - Implement claim submission logic
  - Add verification status tracking

- [ ] Update `ClaimHistory.tsx`
  - Add chain ID display
  - Add transaction hash display
  - Add verification status indicators
  - Add claim verification interface for verifiers
  - Add claim processing interface for admins

## 2. Policy Management Enhancements
- [ ] Update `CreatePolicy.tsx`
  - Add duration field (in days)
  - Add token selection dropdown
  - Add policy expiration date display
  - Add coverage amount validation
  - Add premium calculation based on duration

- [ ] Update `PolicyDetails.tsx`
  - Add policy status indicators
  - Add expiration date display
  - Add remaining coverage amount
  - Add policy renewal interface
  - Add policy cancellation interface

## 3. Role-Based Access Control
- [ ] Add role management in `Dashboard.tsx`
  - Add verifier role check
  - Add admin role check
  - Add role-specific navigation items
  - Add role-based component rendering

- [ ] Create new `ClaimVerification.tsx` component
  - Add verification interface for verifiers
  - Add proof submission
  - Add verification status tracking
  - Add rejection reason input

## 4. Token Management
- [ ] Create new `TokenSelector.tsx` component
  - Add supported tokens list
  - Add token balance display
  - Add token selection interface
  - Add token approval interface

- [ ] Update `InsuranceOptions.tsx`
  - Add token-specific insurance options
  - Add token price display
  - Add coverage calculator
  - Add premium calculator

## 5. UI/UX Improvements
- [ ] Add loading states for all async operations
- [ ] Add error handling and display
- [ ] Add success notifications
- [ ] Add confirmation dialogs for important actions
- [ ] Add tooltips for complex features
- [ ] Improve mobile responsiveness

## 6. Testing
- [ ] Add unit tests for new components
- [ ] Add integration tests for cross-chain functionality
- [ ] Add role-based access control tests
- [ ] Add token management tests
- [ ] Add end-to-end tests for claim workflow
