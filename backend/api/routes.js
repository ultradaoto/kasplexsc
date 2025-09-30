/**
 * API Routes
 * RESTful API endpoints for contract interaction
 */

const express = require('express');
const { ethers } = require('ethers');
const eventMonitor = require('../services/eventMonitor');
const logger = require('../utils/logger');

const router = express.Router();

// Get monitoring status
router.get('/status', (req, res) => {
    res.json(eventMonitor.getStatus());
});

// Get network info
router.get('/network', async (req, res) => {
    try {
        const provider = new ethers.JsonRpcProvider(
            process.env.KASPLEX_RPC_URL || 'https://rpc.kasplextest.xyz'
        );
        
        const network = await provider.getNetwork();
        const blockNumber = await provider.getBlockNumber();
        
        res.json({
            chainId: network.chainId.toString(),
            blockNumber,
            rpcUrl: process.env.KASPLEX_RPC_URL,
            name: 'Kasplex Testnet'
        });
    } catch (error) {
        logger.error('Network info error:', error);
        res.status(500).json({ error: 'Failed to fetch network info' });
    }
});

// Get contract addresses
router.get('/contracts', (req, res) => {
    res.json({
        ipnft: process.env.IPNFT_ADDRESS || null,
        royaltyDistributor: process.env.ROYALTY_DISTRIBUTOR_ADDRESS || null,
        tokenizer: process.env.TOKENIZER_ADDRESS || null
    });
});

// Example: Get IP-NFT metadata
router.get('/ipnft/:tokenId', async (req, res) => {
    try {
        if (!process.env.IPNFT_ADDRESS) {
            return res.status(400).json({ error: 'IP-NFT contract not configured' });
        }

        const { tokenId } = req.params;
        
        // Add actual contract call here
        res.json({
            tokenId,
            message: 'IP-NFT metadata endpoint - implement contract call'
        });
    } catch (error) {
        logger.error('Get IP-NFT error:', error);
        res.status(500).json({ error: 'Failed to fetch IP-NFT data' });
    }
});

// Example: Get royalty distribution info
router.get('/royalties/:tokenId', async (req, res) => {
    try {
        if (!process.env.ROYALTY_DISTRIBUTOR_ADDRESS) {
            return res.status(400).json({ error: 'Royalty distributor not configured' });
        }

        const { tokenId } = req.params;
        
        // Add actual contract call here
        res.json({
            tokenId,
            message: 'Royalty distribution endpoint - implement contract call'
        });
    } catch (error) {
        logger.error('Get royalties error:', error);
        res.status(500).json({ error: 'Failed to fetch royalty data' });
    }
});

module.exports = router;
