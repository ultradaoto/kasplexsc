# Quick Start Guide

Get up and running with Kasplex Agricultural IP in 5 minutes.

## 1. Setup (1 min)

```bash
# Get testnet KAS
# Visit: https://faucet.kasplextest.xyz/

# Configure environment
cp .env.example .env
# Edit .env: Add your PRIVATE_KEY
```

## 2. Install & Compile (1 min)

```bash
npm install
forge build
```

## 3. Deploy (2 min)

```bash
# Deploy core contracts
forge script script/Deploy.s.sol:DeployScript \
    --rpc-url https://rpc.kasplextest.xyz \
    --broadcast \
    -vvvv

# Save addresses from output to .env
```

## 4. Mint Test IP-NFT (1 min)

```bash
cast send $IPNFT_ADDRESS \
    "mintIPNFT(address,string,string,string,string,string,address,uint96)(uint256)" \
    $YOUR_ADDRESS \
    "Corn" \
    "Bacillus thuringiensis" \
    "FDA Approved" \
    "Iowa State University" \
    "ipfs://QmTest" \
    $YOUR_ADDRESS \
    500 \
    --rpc-url https://rpc.kasplextest.xyz \
    --private-key $PRIVATE_KEY
```

## 5. Verify

```bash
# Check total supply
cast call $IPNFT_ADDRESS "totalSupply()(uint256)" \
    --rpc-url https://rpc.kasplextest.xyz

# Start backend
npm run backend:dev
```

## Done! 🎉

Your Agricultural IP tokenization system is now running on Kasplex testnet.

## Next Steps

- Read [DEPLOYMENT.md](DEPLOYMENT.md) for detailed guide
- Explore [README.md](../README.md) for full documentation
- Test fractionalization with IPTokenizer
- Set up royalty distribution

## Common Commands

```bash
# Run tests
forge test

# Deploy
forge script script/Deploy.s.sol:DeployScript --rpc-url $KASPLEX_RPC_URL --broadcast

# Start backend
npm run backend:dev

# Check contract
cast call $IPNFT_ADDRESS "name()(string)" --rpc-url $KASPLEX_RPC_URL
```

## Network Info

- **RPC**: https://rpc.kasplextest.xyz
- **Chain ID**: 167012
- **Faucet**: https://faucet.kasplextest.xyz/
- **Explorer**: https://frontend.kasplextest.xyz

## Support

- Check README.md for detailed docs
- Review test files for usage examples
- See DEPLOYMENT.md for troubleshooting
