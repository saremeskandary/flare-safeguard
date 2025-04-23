# Tasklist for Flare Integration in BSD Insurance Protocol

## 1. FdcTransferEventListener Integration
- [x] Create an interface for FdcTransferEventListener to standardize its usage
- [x] Modify FdcTransferEventListener to support multiple tokens and networks
- [x] Create a configurable token registry in FdcTransferEventListener
- [x] Add events for important transfer events in FdcTransferEventListener
- [x] Create a CrossChainClaimProcessor that inherits from ClaimProcessor
- [x] Integrate FdcTransferEventListener with CrossChainClaimProcessor
- [x] Implement claim verification logic using verified transfer data
- [x] Add tests for cross-chain claim verification

## 2. SafeguardMessageReceiver Integration
- [x] Create an interface for SafeguardMessageReceiver to standardize its usage
- [x] Modify SafeguardMessageReceiver to support multiple message types
- [x] Add events for important message events in SafeguardMessageReceiver
- [x] Integrate SafeguardMessageReceiver with CrossChainClaimProcessor
- [x] Implement message processing logic for different message types
- [x] Add tests for cross-chain message handling

## 3. FtsoV2FeedConsumer Integration
- [x] Create an interface for FtsoV2FeedConsumer
- [x] Expand FtsoV2FeedConsumer to support multiple price feeds
- [x] Create a price feed registry in FtsoV2FeedConsumer
- [x] Integrate FtsoV2FeedConsumer with InsuranceCore
- [x] Modify InsuranceCore to use FTSO price data for token valuation
- [x] Update risk assessment to incorporate real-time price data
- [x] Update premium calculation to use current market prices
- [x] Add tests for price feed integration