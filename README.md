# Kasplex Agricultural IP Tokenization System

A comprehensive IP-NFT tokenization platform for agricultural biotechnology intellectual property, built on Kasplex testnet (Layer 2 zkEVM for Kaspa). This system enables the tokenization of bacterial pesticide alternatives with automated royalty distributions and fractional ownership.

## 🌾 Project Overview

This project implements a MoleculeDAO-inspired architecture for agricultural biotech IP, specifically designed for bacterial pesticide alternatives. It provides:

- **IP-NFT Tokenization**: ERC-721 based NFTs representing agricultural IP with detailed metadata
- **Fractional Ownership**: Convert IP-NFTs into tradeable ERC-20 governance tokens
- **Automated Royalties**: Pull-based payment system for multi-beneficiary distributions
- **Governance**: On-chain voting for IP licensing decisions

## 🏗️ Architecture

### Smart Contracts

1. **AgriculturalIPNFT.sol**
   - ERC-721 NFT with ERC-2981 royalty standard
   - Stores crop species, bacterial strain, regulatory approvals, licensed acreage
   - Role-based access control (MINTER_ROLE, LICENSING_ROLE)
   - Pausable for emergency situations
   - UUPS upgradeable

2. **IPTokenizer.sol**
   - Fractionalizes IP-NFTs into ERC-20 tokens
   - ERC20Votes for governance
   - Revenue distribution to token holders
   - Proposal and voting system
   - Redemption/buyout mechanism

3. **RoyaltyDistributor.sol**
   - Multi-beneficiary royalty splitting
   - Pull-based payments (gas optimized)
   - Compliance tracking
   - Supports up to 50 beneficiaries per IP

### Backend Services

- **Event Monitor**: Real-time blockchain event monitoring
- **REST API**: Contract interaction endpoints
- **Database**: MongoDB for event storage and analytics

## 🚀 Quick Start

### Prerequisites

- **Foundry** (installed automatically in setup)
- **Node.js** >= 18.0.0
- **MongoDB** (optional, for backend)
- **Kasplex Testnet** access

### Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd KasplexSC

# Install Node.js dependencies
npm install

# Create environment file
cp .env.example .env

# Edit .env with your configuration
# IMPORTANT: Add your private key and contract addresses
nano .env
```

### Compile Contracts

```bash
# Compile all contracts
forge build

# Run tests
forge test

# Generate gas report
forge test --gas-report

# Generate coverage report
forge coverage
```

### Deploy to Kasplex Testnet

```bash
# 1. Get testnet KAS from faucet
# Visit: https://faucet.kasplextest.xyz/

# 2. Deploy core contracts
forge script script/Deploy.s.sol:DeployScript \
    --rpc-url $KASPLEX_RPC_URL \
    --broadcast \
    --verify \
    -vvvv

# 3. Save the deployed contract addresses to .env

# 4. Mint an IP-NFT (using cast or frontend)

# 5. Deploy tokenizer for specific IP-NFT
export TOKEN_ID=0
export IPNFT_ADDRESS=<your-ipnft-address>
forge script script/Deploy.s.sol:DeployIPTokenizer \
    --rpc-url $KASPLEX_RPC_URL \
    --broadcast \
    -vvvv
```

### Run Backend

```bash
# Start MongoDB (if using database features)
mongod

# Start backend server
npm run backend:dev

# The API will be available at http://localhost:3000
```

## 🌐 Network Configuration

**Kasplex Testnet**
- RPC URL: `https://rpc.kasplextest.xyz`
- Chain ID: `167012` (0x28C94)
- Currency: KAS
- Block Explorer: `https://frontend.kasplextest.xyz`
- Faucet: `https://faucet.kasplextest.xyz/`

Add to MetaMask:
1. Network Name: Kasplex Testnet
2. RPC URL: https://rpc.kasplextest.xyz
3. Chain ID: 167012
4. Currency Symbol: KAS
5. Block Explorer: https://frontend.kasplextest.xyz

## 📋 Usage Examples

### Mint an IP-NFT

```javascript
// Using ethers.js
const tx = await ipnftContract.mintIPNFT(
    ownerAddress,
    "Corn",                           // Crop species
    "Bacillus thuringiensis",        // Bacterial strain
    "FDA Approved",                  // Regulatory status
    "Iowa State University",         // Research institution
    "ipfs://QmMetadata...",          // Metadata URI
    royaltyReceiverAddress,          // Royalty receiver
    500                              // 5% royalty (in basis points)
);
```

### Fractionalize an IP-NFT

```javascript
// Deploy tokenizer for specific IP-NFT
const tokenizerFactory = await ethers.getContractFactory("IPTokenizer");
const tokenizer = await tokenizerFactory.deploy();
await tokenizer.initialize(
    ipnftAddress,
    tokenId,
    ethers.parseEther("1000000"),  // 1M fractional tokens
    "Agricultural IP Token",
    "AGRI-IPT",
    initialOwnerAddress,
    5100                            // 51% quorum
);
```

### Create Governance Proposal

```javascript
// Create a proposal
const tx = await tokenizer.createProposal(
    "Increase licensing fees by 10%",
    7200  // Voting period in blocks (~1 day)
);

// Vote on proposal
await tokenizer.castVote(proposalId, true);  // Vote yes
```

### Distribute Royalties

```javascript
// Create royalty pool
await distributor.createRoyaltyPool(
    tokenId,
    [address1, address2, address3],  // Beneficiaries
    [5000, 3000, 2000]               // Shares in basis points (50%, 30%, 20%)
);

// Send royalties
await distributor.receiveRoyalties(tokenId, { value: ethers.parseEther("10") });

// Beneficiaries withdraw
await distributor.withdrawRoyalties(tokenId);
```

## 🧪 Testing

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test file
forge test --match-path test/AgriculturalIPNFT.t.sol

# Run with gas reporting
forge test --gas-report

# Run coverage
forge coverage

# Fuzz testing (configured for 10,000 runs)
forge test --fuzz-runs 10000
```

## 📊 Gas Optimization

The contracts are optimized for Kasplex L2 with:
- Compiler optimization: 200 runs
- Pull-based payments (vs push)
- Batch operations where possible
- Minimal storage usage
- Event-based data retrieval

## 🔐 Security Features

- **Access Control**: Role-based permissions for sensitive operations
- **Reentrancy Guards**: Protection on all external calls
- **Pausable**: Emergency stop mechanism
- **Upgradeable**: UUPS proxy pattern for bug fixes
- **Input Validation**: Comprehensive checks on all parameters
- **Safe Math**: Solidity 0.8.22+ built-in overflow protection

## 📚 Contract Addresses

After deployment, add your contract addresses here:

```
AgriculturalIPNFT: 0x...
RoyaltyDistributor: 0x...
IPTokenizer (Example): 0x...
```

## 🛠️ Development

### Project Structure

```
KasplexSC/
├── src/                    # Smart contracts
│   ├── AgriculturalIPNFT.sol
│   ├── IPTokenizer.sol
│   └── RoyaltyDistributor.sol
├── test/                   # Test files
│   ├── AgriculturalIPNFT.t.sol
│   └── Integration.t.sol
├── script/                 # Deployment scripts
│   └── Deploy.s.sol
├── backend/                # Node.js backend
│   ├── api/               # REST API routes
│   ├── services/          # Event monitoring
│   └── utils/             # Utilities
├── docs/                   # Documentation
├── foundry.toml           # Foundry configuration
├── package.json           # Node.js dependencies
└── README.md              # This file
```

### Adding New Features

1. Create contract in `src/`
2. Write tests in `test/`
3. Add deployment script in `script/`
4. Update backend event monitoring if needed
5. Run tests and generate gas reports
6. Deploy to testnet
7. Update documentation

## 📖 Additional Documentation

- [Deployment Guide](docs/DEPLOYMENT.md)
- [API Documentation](docs/API.md)
- [Contract Specifications](docs/CONTRACTS.md)

## 🤝 Contributing

This is a testnet project. Contributions welcome!

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📝 License

MIT License - see LICENSE file for details

## ⚠️ Disclaimer

**TESTNET ONLY**: This code is deployed on Kasplex testnet for development and testing purposes. Do not use in production without a professional security audit.

## 📞 Support

- Issues: GitHub Issues
- Network: Kasplex Testnet
- Faucet: https://faucet.kasplextest.xyz/
- Explorer: https://frontend.kasplextest.xyz

## 🙏 Acknowledgments

- MoleculeDAO for IP-NFT inspiration
- OpenZeppelin for smart contract libraries
- Foundry for development framework
- Kasplex team for testnet infrastructure

---

Built with ❤️ for agricultural innovation on Kasplex