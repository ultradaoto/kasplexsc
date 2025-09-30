# PROJECT CONTEXT: Agricultural IP Tokenization on Kasplex

## 🎯 Project Mission
Building a decentralized IP tokenization platform for agricultural biotechnology, specifically for licensing and royalty distribution of beneficial bacterial strains used as organic pesticide alternatives. This system enables researchers, institutions, and investors to share in the commercial success of agricultural innovations.

## 🌐 Network Configuration (TESTNET ONLY)
**⚠️ IMPORTANT: This project operates EXCLUSIVELY on Kasplex Testnet until production readiness**

```yaml
Network: Kasplex zkEVM Layer 2 (Kaspa Ecosystem)
Environment: TESTNET
Chain ID: 167012 (0x28C94)
RPC Endpoint: https://rpc.kasplextest.xyz
Explorer: https://frontend.kasplextest.xyz
Faucet: https://faucet.kasplextest.xyz/
Gas Token: KAS (bridged from L1)
Status: Active Development
```

**Production Network (DO NOT USE YET):**
- Chain ID: 202555 (0x317BB)
- RPC: https://evmrpc.kasplex.org
- Explorer: https://explorer.kasplex.org

## 📋 Core Requirements

### Business Logic
1. **IP Asset**: Beneficial bacteria for organic farming (non-chemical pesticide)
2. **Revenue Model**: Licensing fees from agricultural operations
3. **Distribution**: Automated royalty payments to token holders
4. **Governance**: Token holders vote on licensing terms and usage rights
5. **Compliance**: Track all distributions for agricultural regulatory requirements

### Technical Architecture
Following MoleculeDAO's proven IP-NFT framework:

```
┌─────────────────┐
│   IP-NFT (721)  │ ← Represents ownership of bacterial strain IP
└────────┬────────┘
         │
    ┌────▼────┐
    │Tokenizer│ ← Fractionalizes into governance tokens (IPT)
    └────┬────┘
         │
┌────────▼────────┐
│ Royalty Splitter│ ← Distributes licensing revenues
└─────────────────┘
```

### Smart Contract Components

1. **AgriculturalIPNFT.sol**
   - ERC-721 + ERC-2981 (royalty standard)
   - Stores bacterial strain metadata
   - Manages licensing permissions
   - Tracks regulatory approvals

2. **IPTokenizer.sol**
   - Converts IP-NFT → ERC-20 tokens (IPTs)
   - Manages fractional ownership
   - Implements governance voting
   - Controls revenue rights

3. **RoyaltyDistributor.sol**
   - PaymentSplitter implementation
   - Pull-based payment system
   - Multi-beneficiary support
   - Compliance reporting events

## 🛠 Development Stack

### Required Tools
- **Framework**: Foundry (NOT Hardhat)
- **Language**: Solidity ^0.8.19
- **Libraries**: OpenZeppelin Contracts 4.9+
- **Backend**: Node.js 18+ with Ethers.js v6
- **Testing**: Foundry's forge test with fuzzing
- **IDE**: Cursor with Claude integration

### Development Principles
1. **Security First**: All code must be audit-ready
2. **Gas Optimization**: Critical for L2 economics
3. **Test Coverage**: Minimum 90% with extensive fuzzing
4. **Documentation**: Comprehensive NatSpec comments
5. **Upgradeability**: Use proxy patterns where appropriate

## 📁 Project Structure
```
kasplex-ip-tokenization/
├── contracts/
│   ├── core/
│   │   ├── AgriculturalIPNFT.sol
│   │   ├── IPTokenizer.sol
│   │   └── RoyaltyDistributor.sol
│   ├── interfaces/
│   └── libraries/
├── test/
│   ├── unit/
│   ├── integration/
│   └── fuzzing/
├── script/
│   ├── Deploy.s.sol
│   └── Upgrade.s.sol
├── backend/
│   ├── monitor.js
│   ├── api.js
│   └── services/
├── docs/
├── .env.example
├── foundry.toml
├── package.json
└── PROJECT-CONTEXT.md (this file)
```

## 🔒 Security Considerations

### Known Risks
1. **Bridge Security**: L1↔L2 bridge vulnerabilities
2. **Royalty Calculations**: Integer overflow in payment distributions
3. **Access Control**: Role management for licensing permissions
4. **Upgradeability**: Proxy implementation risks
5. **Cross-chain**: Future multi-chain licensing considerations

### Mitigation Strategies
- Comprehensive test coverage (unit + fuzz + integration)
- Regular security audits (Slither, Mythril)
- Multi-sig deployment and admin controls
- Emergency pause mechanisms
- Time-locks on critical functions

## 🚀 Development Phases

### Phase 1: Core Contracts (Current)
- [x] Research MoleculeDAO architecture
- [ ] Implement basic IP-NFT contract
- [ ] Add tokenization mechanism
- [ ] Create royalty distribution system
- [ ] Write comprehensive tests

### Phase 2: Enhanced Features
- [ ] Metadata standardization for agricultural IP
- [ ] Regulatory compliance tracking
- [ ] Multi-jurisdiction support
- [ ] Advanced governance mechanisms

### Phase 3: Integration
- [ ] Backend monitoring system
- [ ] API for third-party integration
- [ ] IPFS metadata storage
- [ ] Frontend dashboard (separate project)

### Phase 4: Mainnet Preparation
- [ ] Security audit
- [ ] Gas optimization
- [ ] Deployment rehearsal
- [ ] Documentation completion
- [ ] Community testing

## 📊 Success Metrics
- Gas cost per transaction < 0.001 KAS
- Test coverage > 90%
- All high/critical issues resolved
- Successful testnet deployment
- 1000+ testnet transactions processed

## 🔗 Important Links
- [Kasplex Documentation](https://docs.kasplex.org)
- [MoleculeDAO IP-NFT](https://github.com/moleculeprotocol/IPNFT)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/4.x/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Kaspa Ecosystem](https://kaspa.org)

## ⚠️ Critical Reminders
1. **NEVER deploy to mainnet without thorough testing**
2. **ALWAYS use testnet for development**
3. **NEVER commit private keys or sensitive data**
4. **ALWAYS verify contracts on block explorer**
5. **DOCUMENT every design decision**

## 📝 Notes for AI Assistants
When working on this project:
- Prioritize security over features
- Optimize for gas efficiency given L2 architecture
- Follow MoleculeDAO patterns for proven architecture
- Maintain comprehensive test coverage
- Document all assumptions and decisions
- Keep all network interactions on TESTNET
- Use environment variables for all sensitive configuration

---
*Last Updated: September 2025*
*Version: 1.0.0*
*Status: Active Development on Testnet*