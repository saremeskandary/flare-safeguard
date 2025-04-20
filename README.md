# Safeguard - RWA Insurance Platform

## Vision

In the rapidly evolving world of blockchain and cryptocurrency, we believe the potential for growth and innovation is limitless. However, the volatility and risk of scams have created a barrier to mass adoption, hindering the widespread acceptance of cryptoassets.

At Safeguard, we're committed to bridging this gap by harnessing the power of insurance and banking expertise to create innovative solutions that reduce these risks. Our goal is to empower individuals and institutions to confidently invest in the crypto-asset market, knowing that their assets are protected and have the proper transparency assured.

## Overview

Safeguard provides peace of mind for RWA (Real World Asset) crypto-asset holders by:
- Safeguarding investments against credit risk related to default events
- Ensuring market integrity through transparent insurance coverage
- Leveraging Flare Network's robust infrastructure for cross-chain operations
- Providing real-time monitoring and automated claim processing

## Core Components

### 1. Insurance Platform
- List of evaluated RWA tokens with insurance coverage options
- Real-time monitoring of insured assets
- Automated claim processing and payout system
- Transparent fee structure and coverage details

### 2. Smart Contracts

#### Vault Contract
- Built on Flare Smart Contracts Library
- Manages insurance reserves
- Handles fee collection and distribution
- Processes claim payouts
- Maintains BSD token backing

#### TokenRWA Contract
- Implemented using Flare Asset Library (FAL)
- Issues insured RWA tokens
- Manages coverage limits
- Handles token transfers and balances
- Integrates with Flare State Connector for cross-chain operations

#### Data Verification
- Uses Flare Data Connector (FDC) for external data verification
- Implements Merkle tree verification
- Handles attestation requests and responses
- Provides secure data verification

### 3. Token System
- BSD token implemented using Flare Asset Library (FAL)
- Governance handled by Flare Governance system
- BSD/USDT liquidity pool using FAL
- Multi-chain support via Flare State Connector

## Technical Architecture

### Frontend
- Next.js and ethers.js
- Web3 wallet integration
- Real-time asset monitoring
- Intuitive insurance purchase flow

### Backend
- Spring Boot APIs
- MongoDB for metadata storage
- Flare Network integration
- Automated monitoring system

### Smart Contracts
- Built on Flare Smart Contracts Library
- FAL for token implementations
- FDC for data verification
- FTSO for price feeds
- State Connector for cross-chain operations

## Insurance Flow

1. **Purchase**
   - Customer connects wallet
   - Selects RWA token for insurance
   - Pays coverage fee in USDT
   - Receives insured RWA token

2. **Monitoring**
   - FDC monitors RWA token status
   - Automated status checks
   - Real-time default detection
   - Cross-chain verification via State Connector

3. **Claim Processing**
   - Automated claim initiation
   - Verification through FDC attestations
   - Vault payout processing
   - Token holder compensation

## Setup and Deployment

### Prerequisites
- Flare Network access
- Flare wallet with FLR tokens
- Development environment setup
- Access to Flare components (FDC, FTSO, State Connector)

### Deployment Steps
1. Deploy Vault contract (using Flare Smart Contracts Library)
2. Configure TokenRWA contract (using FAL)
3. Set up FDC integration
4. Deploy TokenInsurance system
5. Initialize BSD token and liquidity pool (using FAL)

## Security Features

- Built on audited Flare components
- Multi-signature requirements for critical operations
- Automated monitoring and verification
- Transparent fee structure
- Secure cross-chain messaging
- Regular security audits

## Development Roadmap

1. **Phase 1: Core Infrastructure**
   - Smart contract deployment using Flare components
   - Basic insurance operations
   - Initial token system using FAL

2. **Phase 2: Enhanced Features**
   - Advanced monitoring capabilities
   - Improved user experience
   - Additional RWA token support

3. **Phase 3: Expansion**
   - Multi-chain integration via State Connector
   - Advanced risk assessment
   - Institutional features

## Contributing

We welcome contributions to Safeguard! Please follow these steps:
1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT

## Contact

For more information about Safeguard, please visit our website or reach out to our team.


-------------------

# 🏗 Scaffold-ETH 2

<h4 align="center">
  <a href="https://docs.scaffoldeth.io">Documentation</a> |
  <a href="https://scaffoldeth.io">Website</a>
</h4>

🧪 An open-source, up-to-date toolkit for building decentralized applications (dapps) on the Ethereum blockchain. It's designed to make it easier for developers to create and deploy smart contracts and build user interfaces that interact with those contracts.

⚙️ Built using NextJS, RainbowKit, Foundry, Wagmi, Viem, and Typescript.

- ✅ **Contract Hot Reload**: Your frontend auto-adapts to your smart contract as you edit it.
- 🪝 **[Custom hooks](https://docs.scaffoldeth.io/hooks/)**: Collection of React hooks wrapper around [wagmi](https://wagmi.sh/) to simplify interactions with smart contracts with typescript autocompletion.
- 🧱 [**Components**](https://docs.scaffoldeth.io/components/): Collection of common web3 components to quickly build your frontend.
- 🔥 **Burner Wallet & Local Faucet**: Quickly test your application with a burner wallet and local faucet.
- 🔐 **Integration with Wallet Providers**: Connect to different wallet providers and interact with the Ethereum network.

![Debug Contracts tab](https://github.com/scaffold-eth/scaffold-eth-2/assets/55535804/b237af0c-5027-4849-a5c1-2e31495cccb1)

## Requirements

Before you begin, you need to install the following tools:

- [Node (>= v20.18.3)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

## Quickstart

To get started with Scaffold-ETH 2, follow the steps below:

1. Install dependencies if it was skipped in CLI:

```
cd my-dapp-example
yarn install
```

2. Run a local network in the first terminal:

```
yarn chain
```

This command starts a local Ethereum network using Foundry. The network runs on your local machine and can be used for testing and development. You can customize the network configuration in `packages/foundry/foundry.toml`.

3. On a second terminal, deploy the test contract:

```
yarn deploy
```

This command deploys a test smart contract to the local network. The contract is located in `packages/foundry/contracts` and can be modified to suit your needs. The `yarn deploy` command uses the deploy script located in `packages/foundry/script` to deploy the contract to the network. You can also customize the deploy script.

4. On a third terminal, start your NextJS app:

```
yarn start
```

Visit your app on: `http://localhost:3000`. You can interact with your smart contract using the `Debug Contracts` page. You can tweak the app config in `packages/nextjs/scaffold.config.ts`.

Run smart contract test with `yarn foundry:test`

- Edit your smart contracts in `packages/foundry/contracts`
- Edit your frontend homepage at `packages/nextjs/app/page.tsx`. For guidance on [routing](https://nextjs.org/docs/app/building-your-application/routing/defining-routes) and configuring [pages/layouts](https://nextjs.org/docs/app/building-your-application/routing/pages-and-layouts) checkout the Next.js documentation.
- Edit your deployment scripts in `packages/foundry/script`


## Documentation

Visit our [docs](https://docs.scaffoldeth.io) to learn how to start building with Scaffold-ETH 2.

To know more about its features, check out our [website](https://scaffoldeth.io).

## Contributing to Scaffold-ETH 2

We welcome contributions to Scaffold-ETH 2!

Please see [CONTRIBUTING.MD](https://github.com/scaffold-eth/scaffold-eth-2/blob/main/CONTRIBUTING.md) for more information and guidelines for contributing to Scaffold-ETH 2.