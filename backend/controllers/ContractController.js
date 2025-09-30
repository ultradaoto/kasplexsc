/**
 * Contract Controller
 * Handles all contract-related business logic (MVC Controller)
 */

const ContractModel = require('../models/ContractModel');
const logger = require('../utils/logger');

class ContractController {
    /**
     * Get network information
     */
    static async getNetworkInfo(req, res) {
        try {
            const networkInfo = await ContractModel.getNetworkInfo();
            res.json(networkInfo);
        } catch (error) {
            logger.error('Error fetching network info:', error);
            res.status(500).json({ error: 'Failed to fetch network information' });
        }
    }

    /**
     * Get contract addresses
     */
    static async getContractAddresses(req, res) {
        try {
            const addresses = ContractModel.getContractAddresses();
            res.json(addresses);
        } catch (error) {
            logger.error('Error fetching contract addresses:', error);
            res.status(500).json({ error: 'Failed to fetch contract addresses' });
        }
    }

    /**
     * Get IP-NFT metadata by token ID
     */
    static async getIPNFTMetadata(req, res) {
        try {
            const { tokenId } = req.params;
            
            if (!process.env.IPNFT_ADDRESS) {
                return res.status(400).json({ 
                    error: 'IP-NFT contract not configured',
                    message: 'Please deploy contracts and add IPNFT_ADDRESS to .env'
                });
            }

            const metadata = await ContractModel.getIPNFTMetadata(tokenId);
            res.json(metadata);
        } catch (error) {
            logger.error('Error fetching IP-NFT metadata:', error);
            res.status(500).json({ error: error.message });
        }
    }

    /**
     * Get all IP-NFTs
     */
    static async getAllIPNFTs(req, res) {
        try {
            if (!process.env.IPNFT_ADDRESS) {
                return res.status(400).json({ 
                    error: 'IP-NFT contract not configured' 
                });
            }

            const ipnfts = await ContractModel.getAllIPNFTs();
            res.json(ipnfts);
        } catch (error) {
            logger.error('Error fetching IP-NFTs:', error);
            res.status(500).json({ error: error.message });
        }
    }

    /**
     * Get royalty distribution info
     */
    static async getRoyaltyInfo(req, res) {
        try {
            const { tokenId } = req.params;
            
            if (!process.env.ROYALTY_DISTRIBUTOR_ADDRESS) {
                return res.status(400).json({ 
                    error: 'Royalty distributor not configured' 
                });
            }

            const royaltyInfo = await ContractModel.getRoyaltyInfo(tokenId);
            res.json(royaltyInfo);
        } catch (error) {
            logger.error('Error fetching royalty info:', error);
            res.status(500).json({ error: error.message });
        }
    }

    /**
     * Get monitoring status
     */
    static getMonitoringStatus(req, res) {
        try {
            const eventMonitor = require('../services/eventMonitor');
            const status = eventMonitor.getStatus();
            res.json(status);
        } catch (error) {
            logger.error('Error fetching monitoring status:', error);
            res.status(500).json({ error: 'Failed to fetch monitoring status' });
        }
    }
}

module.exports = ContractController;
