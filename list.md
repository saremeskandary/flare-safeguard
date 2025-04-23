# Failed Tests

## ClaimProcessor.t.sol
- [FAIL: log != expected log] testProcessPayout() (gas: 456998)
- [FAIL: Error != expected error: ReentrancyGuardReentrantCall() != Claim not approved] test_RevertWhen_ProcessPayoutForUnapprovedClaim() (gas: 16857)

## CrossChainClaimProcessor.t.sol
- [FAIL: EvmError: Revert] testProcessCrossChainClaim() (gas: 519369)
- [FAIL: log != expected log] testVerifyCrossChainClaim() (gas: 521509)

## SafeguardMessageReceiver.t.sol
- [FAIL] testFailProcessNonExistentMessage() (gas: 15581)
- [FAIL: revert: Message does not exist] testProcessClaimSubmissionMessage() (gas: 326494)
- [FAIL: log != expected log] testProcessPolicyCreationMessage() (gas: 328705)
- [FAIL: log != expected log] testReceiveMessage() (gas: 301969)
- [FAIL: log != expected log] testReceiveMessageWithInvalidData() (gas: 214144)
- [FAIL: log != expected log] testReceiveMessageWithInvalidEncodedData() (gas: 301871)
- [FAIL: log != expected log] testReceiveMessageWithInvalidSender() (gas: 23556)
- [FAIL: log != expected log] testReceiveMessageWithInvalidTargetChain() (gas: 26408)

Total: 12 failed tests, 92 tests succeeded 