/**
 * Routes (MVC View Layer for API)
 * Defines all API endpoints and maps them to controllers
 */

const express = require('express');
const ContractController = require('../controllers/ContractController');

const router = express.Router();

// ============================================
// Contract Routes
// ============================================

/**
 * GET /api/network
 * Get Kasplex network information
 */
router.get('/network', ContractController.getNetworkInfo);

/**
 * GET /api/contracts
 * Get deployed contract addresses
 */
router.get('/contracts', ContractController.getContractAddresses);

/**
 * GET /api/status
 * Get event monitoring status
 */
router.get('/status', ContractController.getMonitoringStatus);

/**
 * GET /api/ipnfts
 * Get all IP-NFTs
 */
router.get('/ipnfts', ContractController.getAllIPNFTs);

/**
 * GET /api/ipnft/:tokenId
 * Get specific IP-NFT metadata
 */
router.get('/ipnft/:tokenId', ContractController.getIPNFTMetadata);

/**
 * GET /api/royalties/:tokenId
 * Get royalty distribution info for specific IP-NFT
 */
router.get('/royalties/:tokenId', ContractController.getRoyaltyInfo);

// ============================================
// Health & Info Routes
// ============================================

/**
 * GET /api/
 * API welcome message
 */
router.get('/', (req, res) => {
    res.json({
        message: 'Kasplex Agricultural IP Tokenization API',
        version: '1.0.0',
        network: 'Kasplex Testnet',
        endpoints: {
            network: '/api/network',
            contracts: '/api/contracts',
            status: '/api/status',
            allIPNFTs: '/api/ipnfts',
            ipnft: '/api/ipnft/:tokenId',
            royalties: '/api/royalties/:tokenId'
        },
        documentation: 'See README.md for full API documentation'
    });
});

module.exports = router;
