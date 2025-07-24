# VaultBridge Lending Protocol

[![Clarity](https://img.shields.io/badge/Language-Clarity-blue.svg)](https://clarity-lang.org/)
[![Stacks](https://img.shields.io/badge/Platform-Stacks-orange.svg)](https://stacks.co/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> Revolutionary cross-chain lending infrastructure that transforms idle Bitcoin into productive capital while preserving asset custody and long-term growth potential.

## 🚀 Overview

VaultBridge revolutionizes DeFi lending by creating a seamless bridge between Bitcoin's store-of-value properties and Stacks' smart contract capabilities. Users can unlock liquidity from their Bitcoin holdings without selling, maintaining full exposure to BTC appreciation while accessing STX liquidity.

### Key Features

- **🔒 Non-Custodial**: Maintain full control of your Bitcoin assets
- **⚡ Instant Liquidity**: Access STX loans against BTC collateral
- **📈 Price Appreciation**: Keep exposure to Bitcoin's growth potential
- **🛡️ Risk Management**: Automated liquidation protection
- **🔄 Cross-Chain**: Bridge Bitcoin and Stacks ecosystems
- **📊 Transparent**: On-chain oracle integration for fair pricing

## 🏗️ Architecture

The protocol consists of several core components:

### Smart Contract Structure

```
VaultBridge-Lending.clar
├── Constants & Error Codes
├── Data Variables (Protocol State)
├── Data Maps (Storage)
├── Private Functions (Internal Logic)
├── Public Functions (Core Operations)
└── Read-Only Functions (Data Access)
```

### Core Data Structures

- **Loans Map**: Stores loan details including borrower, collateral, amounts, and status
- **User Loans Map**: Tracks active loans per user (max 10 loans per user)
- **Collateral Prices Map**: Oracle price feed integration for supported assets

## 🔧 Installation & Setup

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development tool
- [Node.js](https://nodejs.org/) (v16+)
- [Git](https://git-scm.com/)

### Clone Repository

```bash
git clone https://github.com/justina-smith/VaultBridge-Lending.git
cd VaultBridge-Lending
```

### Install Dependencies

```bash
npm install
```

### Verify Installation

```bash
clarinet check
```

## 🎯 Usage

### Contract Deployment

1. **Initialize Platform** (Owner Only)

```clarity
(contract-call? .VaultBridge-Lending initialize-platform)
```

2. **Set Price Feeds** (Owner Only)

```clarity
(contract-call? .VaultBridge-Lending update-price-feed "BTC" u50000000000) ;; $50,000 BTC
(contract-call? .VaultBridge-Lending update-price-feed "STX" u2000000)     ;; $2 STX
```

### Core Operations

#### Requesting a Loan

```clarity
;; Deposit 1 BTC as collateral and request 20,000 STX loan
(contract-call? .VaultBridge-Lending request-loan u100000000 u20000000000)
```

#### Repaying a Loan

```clarity
;; Repay loan with ID 1 (amount includes interest)
(contract-call? .VaultBridge-Lending repay-loan u1 u21000000000)
```

#### Checking Loan Details

```clarity
;; Get loan information
(contract-call? .VaultBridge-Lending get-loan-details u1)
```

## 📋 API Reference

### Public Functions

#### Platform Administration

| Function | Description | Parameters | Access |
|----------|-------------|------------|---------|
| `initialize-platform` | Initialize the protocol | None | Owner Only |
| `update-collateral-ratio` | Update minimum collateral ratio | `new-ratio: uint` | Owner Only |
| `update-liquidation-threshold` | Update liquidation threshold | `new-threshold: uint` | Owner Only |
| `update-price-feed` | Update asset price | `asset: string-ascii 3, new-price: uint` | Owner Only |

#### Core Lending Operations

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `deposit-collateral` | Deposit collateral to vault | `amount: uint` | `(response bool uint)` |
| `request-loan` | Request loan against collateral | `collateral: uint, loan-amount: uint` | `(response uint uint)` |
| `repay-loan` | Repay loan with interest | `loan-id: uint, amount: uint` | `(response bool uint)` |

#### Read-Only Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `get-loan-details` | Get specific loan information | `loan-id: uint` | Loan details or none |
| `get-user-loans` | Get user's active loans | `user: principal` | List of loan IDs |
| `get-platform-stats` | Get protocol statistics | None | Platform metrics |
| `get-valid-assets` | Get supported assets | None | List of asset strings |

### Error Codes

| Code | Error | Description |
|------|-------|-------------|
| `u100` | `ERR-NOT-AUTHORIZED` | Caller not authorized for operation |
| `u101` | `ERR-INSUFFICIENT-COLLATERAL` | Collateral insufficient for loan amount |
| `u102` | `ERR-BELOW-MINIMUM` | Amount below minimum threshold |
| `u103` | `ERR-INVALID-AMOUNT` | Invalid amount provided |
| `u104` | `ERR-ALREADY-INITIALIZED` | Platform already initialized |
| `u105` | `ERR-NOT-INITIALIZED` | Platform not yet initialized |
| `u106` | `ERR-INVALID-LIQUIDATION` | Invalid liquidation attempt |
| `u107` | `ERR-LOAN-NOT-FOUND` | Loan ID does not exist |
| `u108` | `ERR-LOAN-NOT-ACTIVE` | Loan is not in active status |
| `u109` | `ERR-INVALID-LOAN-ID` | Loan ID is invalid |
| `u110` | `ERR-INVALID-PRICE` | Price data is invalid |
| `u111` | `ERR-INVALID-ASSET` | Asset not supported |

## 🧪 Testing

### Run Tests

```bash
npm test
```

### Check Contract Syntax

```bash
clarinet check
```

### Run Specific Test

```bash
npx vitest tests/VaultBridge-Lending.test.ts
```

## 🛡️ Risk Management

### Collateral Requirements

- **Minimum Collateral Ratio**: 150% (default)
- **Liquidation Threshold**: 120% (default)
- **Maximum Loans per User**: 10 active loans

### Liquidation Process

1. **Automated Monitoring**: Continuous collateral ratio checking
2. **Liquidation Trigger**: When ratio falls below 120%
3. **Position Closure**: Automatic liquidation of undercollateralized positions
4. **Asset Recovery**: Collateral used to cover outstanding debt

### Supported Assets

- **BTC**: Primary collateral asset
- **STX**: Secondary collateral asset

## 🔄 Interest Calculation

Interest is calculated using a daily compounding model:

```clarity
interest = (principal × rate × blocks) ÷ (100 × 144)
```

Where:

- `principal`: Loan amount
- `rate`: Annual interest rate (default: 5%)
- `blocks`: Number of blocks since last calculation
- `144`: Approximate blocks per day on Stacks

## 🏭 Development

### Project Structure

```
VaultBridge-Lending/
├── contracts/
│   └── VaultBridge-Lending.clar    # Main contract
├── tests/
│   └── VaultBridge-Lending.test.ts # Test suite
├── settings/
│   ├── Devnet.toml                 # Development settings
│   ├── Testnet.toml               # Testnet settings
│   └── Mainnet.toml               # Mainnet settings
├── Clarinet.toml                  # Clarinet configuration
├── package.json                   # Node.js dependencies
├── tsconfig.json                  # TypeScript configuration
└── vitest.config.js              # Test configuration
```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Clarity best practices
- Use clear, descriptive function names
- Include comprehensive comments
- Maintain consistent indentation
- Write thorough tests for new features

## 🚨 Security Considerations

### Access Control

- **Owner Privileges**: Limited to price feeds and parameter updates
- **User Authorization**: Strict borrower verification for loan operations
- **Input Validation**: Comprehensive parameter checking

### Best Practices

- Always verify loan ownership before operations
- Validate collateral ratios before loan issuance
- Implement proper error handling
- Use read-only functions for data queries

## 📊 Monitoring & Analytics

### Platform Metrics

- **Total BTC Locked**: Aggregate collateral in protocol
- **Total Loans Issued**: Cumulative loan counter
- **Active Loan Count**: Current outstanding loans
- **Average Collateral Ratio**: System health indicator

### User Metrics

- **Individual Loan Details**: Per-loan tracking
- **User Loan History**: Complete borrowing history
- **Collateral Utilization**: Asset efficiency metrics

## 🌐 Network Deployment

### Devnet (Development)

```bash
clarinet deploy --network devnet
```

### Testnet

```bash
clarinet deploy --network testnet
```

### Mainnet

```bash
clarinet deploy --network mainnet
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Support

- **Documentation**: [Stacks Documentation](https://docs.stacks.co/)
- **Community**: [Stacks Discord](https://discord.gg/stacks)
- **Issues**: [GitHub Issues](https://github.com/justina-smith/VaultBridge-Lending/issues)

## 🔮 Roadmap

- [ ] Multi-asset collateral support
- [ ] Dynamic interest rates based on utilization
- [ ] Governance token integration
- [ ] Advanced liquidation mechanisms
- [ ] Cross-chain asset bridging
- [ ] Insurance fund implementation
