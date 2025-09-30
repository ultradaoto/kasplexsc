/**
 * Event Monitor Service
 * Monitors blockchain events from Agricultural IP contracts
 */

const { ethers } = require('ethers');
const logger = require('../utils/logger');

// Contract ABIs (simplified - add full ABIs after deployment)
const IPNFT_ABI = [
    "event IPNFTMinted(uint256 indexed tokenId, address indexed owner, string cropSpecies, string bacterialStrain, string metadataURI)",
    "event MetadataUpdated(uint256 indexed tokenId, string metadataURI)",
    "event LicensedAcresUpdated(uint256 indexed tokenId, uint256 newAcreage)",
    "event IPNFTFractionalized(uint256 indexed tokenId, address indexed fractionalizer, address indexed tokenOwner)"
];

const TOKENIZER_ABI = [
    "event RevenueAdded(uint256 amount, uint256 totalRevenue)",
    "event RevenueClaimed(address indexed holder, uint256 amount)",
    "event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 startBlock, uint256 endBlock)",
    "event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight)"
];

const DISTRIBUTOR_ABI = [
    "event RoyaltiesReceived(uint256 indexed ipnftTokenId, uint256 amount, address indexed sender)",
    "event RoyaltiesWithdrawn(uint256 indexed ipnftTokenId, address indexed beneficiary, uint256 amount)"
];

class EventMonitor {
    constructor() {
        this.provider = null;
        this.ipnftContract = null;
        this.distributorContract = null;
        this.isMonitoring = false;
    }

    async start() {
        try {
            // Initialize provider
            this.provider = new ethers.JsonRpcProvider(
                process.env.KASPLEX_RPC_URL || 'https://rpc.kasplextest.xyz'
            );

            // Initialize contracts
            if (process.env.IPNFT_ADDRESS) {
                this.ipnftContract = new ethers.Contract(
                    process.env.IPNFT_ADDRESS,
                    IPNFT_ABI,
                    this.provider
                );
                this.setupIPNFTListeners();
            }

            if (process.env.ROYALTY_DISTRIBUTOR_ADDRESS) {
                this.distributorContract = new ethers.Contract(
                    process.env.ROYALTY_DISTRIBUTOR_ADDRESS,
                    DISTRIBUTOR_ABI,
                    this.provider
                );
                this.setupDistributorListeners();
            }

            this.isMonitoring = true;
            logger.info('Event monitoring started successfully');
        } catch (error) {
            logger.error('Failed to start event monitoring:', error);
            throw error;
        }
    }

    setupIPNFTListeners() {
        this.ipnftContract.on('IPNFTMinted', (tokenId, owner, cropSpecies, bacterialStrain, metadataURI, event) => {
            logger.info('IPNFTMinted event:', {
                tokenId: tokenId.toString(),
                owner,
                cropSpecies,
                bacterialStrain,
                metadataURI,
                blockNumber: event.log.blockNumber
            });
            // Store in database or trigger notifications
        });

        this.ipnftContract.on('MetadataUpdated', (tokenId, metadataURI, event) => {
            logger.info('MetadataUpdated event:', {
                tokenId: tokenId.toString(),
                metadataURI,
                blockNumber: event.log.blockNumber
            });
        });

        this.ipnftContract.on('LicensedAcresUpdated', (tokenId, newAcreage, event) => {
            logger.info('LicensedAcresUpdated event:', {
                tokenId: tokenId.toString(),
                newAcreage: newAcreage.toString(),
                blockNumber: event.log.blockNumber
            });
        });

        this.ipnftContract.on('IPNFTFractionalized', (tokenId, fractionalizer, tokenOwner, event) => {
            logger.info('IPNFTFractionalized event:', {
                tokenId: tokenId.toString(),
                fractionalizer,
                tokenOwner,
                blockNumber: event.log.blockNumber
            });
        });

        logger.info('IP-NFT event listeners configured');
    }

    setupDistributorListeners() {
        this.distributorContract.on('RoyaltiesReceived', (ipnftTokenId, amount, sender, event) => {
            logger.info('RoyaltiesReceived event:', {
                ipnftTokenId: ipnftTokenId.toString(),
                amount: ethers.formatEther(amount),
                sender,
                blockNumber: event.log.blockNumber
            });
        });

        this.distributorContract.on('RoyaltiesWithdrawn', (ipnftTokenId, beneficiary, amount, event) => {
            logger.info('RoyaltiesWithdrawn event:', {
                ipnftTokenId: ipnftTokenId.toString(),
                beneficiary,
                amount: ethers.formatEther(amount),
                blockNumber: event.log.blockNumber
            });
        });

        logger.info('Royalty Distributor event listeners configured');
    }

    stop() {
        if (this.ipnftContract) {
            this.ipnftContract.removeAllListeners();
        }
        if (this.distributorContract) {
            this.distributorContract.removeAllListeners();
        }
        this.isMonitoring = false;
        logger.info('Event monitoring stopped');
    }

    getStatus() {
        return {
            isMonitoring: this.isMonitoring,
            contracts: {
                ipnft: process.env.IPNFT_ADDRESS || 'Not configured',
                distributor: process.env.ROYALTY_DISTRIBUTOR_ADDRESS || 'Not configured'
            }
        };
    }
}

module.exports = new EventMonitor();
