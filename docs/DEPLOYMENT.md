# Deployment Guide - Kasplex Agricultural IP

Complete step-by-step guide for deploying the Agricultural IP tokenization system to Kasplex testnet.

## Prerequisites Checklist

- [ ] Foundry installed and working (`forge --version`)
- [ ] Node.js 18+ installed (`node --version`)
- [ ] MetaMask or compatible wallet configured
- [ ] Kasplex testnet added to wallet
- [ ] Testnet KAS tokens in wallet
- [ ] Environment variables configured

## Step 1: Get Testnet Tokens

1. Visit the Kasplex testnet faucet: https://faucet.kasplextest.xyz/
2. Enter your wallet address
3. Request testnet KAS tokens
4. Wait for confirmation (usually 1-2 minutes)
5. Verify balance in MetaMask

## Step 2: Configure Environment

Create a `.env` file from the template:

```bash
cp .env.example .env
```

Edit `.env` with your details:

```bash
# Required for deployment
PRIVATE_KEY=your_private_key_here_without_0x
KASPLEX_RPC_URL=https://rpc.kasplextest.xyz
CHAIN_ID=167012

# Optional for backend
PORT=3000
NODE_ENV=development
```

**⚠️ SECURITY WARNING**: Never commit your `.env` file or share your private key!

## Step 3: Compile Contracts

```bash
# Clean previous builds
forge clean

# Compile contracts
forge build

# Verify compilation successful
# You should see: "Compiler run successful!"
```

Expected output:
```
[⠊] Compiling...
[⠒] Compiling 48 files with Solc 0.8.22
[⠢] Solc 0.8.22 finished in X.XXs
Compiler run successful!
```

## Step 4: Run Tests (Recommended)

Before deploying, verify everything works:

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Expected: Most tests should pass
```

## Step 5: Deploy Core Contracts

Deploy AgriculturalIPNFT and RoyaltyDistributor:

```bash
forge script script/Deploy.s.sol:DeployScript \
    --rpc-url $KASPLEX_RPC_URL \
    --broadcast \
    --verify \
    -vvvv
```

**What happens:**
1. Deploys AgriculturalIPNFT implementation
2. Deploys AgriculturalIPNFT proxy
3. Initializes IP-NFT contract
4. Deploys RoyaltyDistributor implementation
5. Deploys RoyaltyDistributor proxy
6. Initializes RoyaltyDistributor

**Expected output:**
```
========================================
Kasplex Agricultural IP Deployment
========================================
Deployer: 0x...
Chain ID: 167012
========================================

1. Deploying AgriculturalIPNFT...
   Implementation: 0x...
   Proxy: 0x...

2. Deploying RoyaltyDistributor...
   Implementation: 0x...
   Proxy: 0x...

========================================
Deployment Summary
========================================
Network: Kasplex Testnet
AgriculturalIPNFT Proxy: 0x...
RoyaltyDistributor Proxy: 0x...
Admin: 0x...
========================================
```

## Step 6: Save Contract Addresses

Update your `.env` file with deployed addresses:

```bash
IPNFT_ADDRESS=0x...  # From deployment output
ROYALTY_DISTRIBUTOR_ADDRESS=0x...  # From deployment output
```

## Step 7: Verify Deployment

### Method 1: Using Cast (Foundry)

```bash
# Check IP-NFT name
cast call $IPNFT_ADDRESS "name()(string)" --rpc-url $KASPLEX_RPC_URL

# Expected: "Agricultural IP-NFT"

# Check admin role
cast call $IPNFT_ADDRESS "hasRole(bytes32,address)(bool)" \
    0x0000000000000000000000000000000000000000000000000000000000000000 \
    $DEPLOYER_ADDRESS \
    --rpc-url $KASPLEX_RPC_URL

# Expected: true
```

### Method 2: Using Block Explorer

1. Visit: https://frontend.kasplextest.xyz
2. Search for your contract address
3. Verify contract creation transaction
4. Check contract code is verified

## Step 8: Mint Test IP-NFT

```bash
# Mint your first IP-NFT
cast send $IPNFT_ADDRESS \
    "mintIPNFT(address,string,string,string,string,string,address,uint96)(uint256)" \
    $YOUR_ADDRESS \
    "Corn" \
    "Bacillus thuringiensis" \
    "FDA Approved" \
    "Iowa State University" \
    "ipfs://QmTest..." \
    $YOUR_ADDRESS \
    500 \
    --rpc-url $KASPLEX_RPC_URL \
    --private-key $PRIVATE_KEY

# Check token was minted
cast call $IPNFT_ADDRESS "totalSupply()(uint256)" --rpc-url $KASPLEX_RPC_URL
# Expected: 1
```

## Step 9: (Optional) Fractionalize IP-NFT

To create fractional ownership of an IP-NFT:

```bash
# Set environment variables
export TOKEN_ID=0  # Token ID from minting
export FRACTIONAL_SUPPLY=1000000000000000000000000  # 1M tokens
export QUORUM_BPS=5100  # 51% quorum

# Deploy tokenizer
forge script script/Deploy.s.sol:DeployIPTokenizer \
    --rpc-url $KASPLEX_RPC_URL \
    --broadcast \
    -vvvv

# Save tokenizer address
export TOKENIZER_ADDRESS=0x...  # From output
```

Update `.env`:
```bash
TOKENIZER_ADDRESS=0x...
```

## Step 10: Setup Royalty Distribution

Create a royalty pool for your IP-NFT:

```bash
# Example: 3 beneficiaries with 50%, 30%, 20% shares
cast send $ROYALTY_DISTRIBUTOR_ADDRESS \
    "createRoyaltyPool(uint256,address[],uint256[])" \
    0 \
    "[0xBeneficiary1,0xBeneficiary2,0xBeneficiary3]" \
    "[5000,3000,2000]" \
    --rpc-url $KASPLEX_RPC_URL \
    --private-key $PRIVATE_KEY
```

## Step 11: Deploy Backend (Optional)

```bash
# Install dependencies
npm install

# Create logs directory
mkdir -p logs

# Start MongoDB (if using database)
mongod --dbpath ./data/db

# Start backend
npm run backend:dev
```

Verify backend is running:
```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2025-09-30T...",
  "network": "Kasplex Testnet",
  "chainId": "167012"
}
```

## Step 12: Test Full System

### Test IP-NFT Functionality

```bash
# Get IP metadata
cast call $IPNFT_ADDRESS \
    "getIPMetadata(uint256)((string,string,string,uint256,string,uint256,string))" \
    0 \
    --rpc-url $KASPLEX_RPC_URL

# Update licensed acres (requires LICENSING_ROLE)
cast send $IPNFT_ADDRESS \
    "updateLicensedAcres(uint256,uint256)" \
    0 \
    10000 \
    --rpc-url $KASPLEX_RPC_URL \
    --private-key $PRIVATE_KEY
```

### Test Royalty Distribution

```bash
# Send test royalties
cast send $ROYALTY_DISTRIBUTOR_ADDRESS \
    "receiveRoyalties(uint256)" \
    0 \
    --value 1ether \
    --rpc-url $KASPLEX_RPC_URL \
    --private-key $PRIVATE_KEY

# Check withdrawable amount
cast call $ROYALTY_DISTRIBUTOR_ADDRESS \
    "withdrawableAmount(uint256,address)(uint256)" \
    0 \
    $YOUR_ADDRESS \
    --rpc-url $KASPLEX_RPC_URL

# Withdraw royalties
cast send $ROYALTY_DISTRIBUTOR_ADDRESS \
    "withdrawRoyalties(uint256)" \
    0 \
    --rpc-url $KASPLEX_RPC_URL \
    --private-key $PRIVATE_KEY
```

## Troubleshooting

### Issue: "Insufficient funds"
**Solution**: Get more testnet KAS from faucet

### Issue: "Nonce too low"
**Solution**: Wait a few blocks or reset MetaMask nonce

### Issue: "Contract deployment failed"
**Solution**: Check gas settings and RPC URL

### Issue: "Failed to verify contract"
**Solution**: Contract verification on testnet explorers may be limited. Deploy with `--verify` flag or verify manually.

### Issue: Backend can't connect
**Solution**: Verify MongoDB is running and .env has correct contract addresses

## Post-Deployment Checklist

- [ ] Contract addresses saved to `.env`
- [ ] Contracts verified on block explorer
- [ ] Test IP-NFT minted successfully
- [ ] Royalty pool created and tested
- [ ] Backend running and responding
- [ ] All contract addresses documented
- [ ] Test transactions successful

## Security Recommendations

1. **Use a dedicated deployment wallet** for testnet
2. **Never use mainnet private keys** on testnet
3. **Keep .env file secure** and in .gitignore
4. **Use hardware wallet** for production deployments
5. **Get professional audit** before mainnet deployment
6. **Test all functionality** thoroughly on testnet
7. **Document all contract addresses** securely

## Upgrading Contracts

The contracts use UUPS upgradeable pattern:

```bash
# Deploy new implementation
NEW_IMPL=$(forge create src/AgriculturalIPNFT.sol:AgriculturalIPNFT --rpc-url $KASPLEX_RPC_URL --private-key $PRIVATE_KEY)

# Upgrade proxy (requires UPGRADER_ROLE)
cast send $IPNFT_ADDRESS \
    "upgradeTo(address)" \
    $NEW_IMPL \
    --rpc-url $KASPLEX_RPC_URL \
    --private-key $PRIVATE_KEY
```

## Next Steps

1. **Integrate Frontend**: Build web3 interface for users
2. **Add More IP-NFTs**: Mint additional agricultural IP
3. **Test Governance**: Create and vote on proposals
4. **Monitor Events**: Use backend to track all contract activity
5. **Prepare Documentation**: For users and stakeholders
6. **Security Audit**: Before any mainnet deployment

## Support

- **Kasplex Discord**: [Join for support]
- **Documentation**: Check README.md for more details
- **Issues**: Report bugs on GitHub

---

**Remember**: This is a testnet deployment. Always test thoroughly before considering mainnet deployment, and get a professional security audit.
