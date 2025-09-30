/**
 * Contract Model
 * Handles data and contract interactions (MVC Model)
 */

const { ethers } = require('ethers');
const logger = require('../utils/logger');

// Simplified ABIs for reading contract data
const IPNFT_ABI = [
    "function name() view returns (string)",
    "function symbol() view returns (string)",
    "function totalSupply() view returns (uint256)",
    "function ownerOf(uint256) view returns (address)",
    "function getIPMetadata(uint256) view returns (tuple(string cropSpecies, string bacterialStrain, string regulatoryStatus, uint256 licensedAcres, string researchInstitution, uint256 approvalDate, string metadataURI))"
];

const DISTRIBUTOR_ABI = [
    "function getPoolInfo(uint256) view returns (uint256 totalReceived, uint256 totalDistributed, uint256 pendingDistribution)",
    "function withdrawableAmount(uint256, address) view returns (uint256)",
    "function getBeneficiaries(uint256) view returns (address[], uint256[], bool[])"
];

class ContractModel {
    static provider = null;

    /**
     * Get or create provider instance
     */
    static getProvider() {
        if (!this.provider) {
            this.provider = new ethers.JsonRpcProvider(
                process.env.KASPLEX_RPC_URL || 'https://rpc.kasplextest.xyz'
            );
        }
        return this.provider;
    }

    /**
     * Get network information
     */
    static async getNetworkInfo() {
        const provider = this.getProvider();
        const network = await provider.getNetwork();
        const blockNumber = await provider.getBlockNumber();

        return {
            chainId: network.chainId.toString(),
            blockNumber,
            rpcUrl: process.env.KASPLEX_RPC_URL || 'https://rpc.kasplextest.xyz',
            name: 'Kasplex Testnet'
        };
    }

    /**
     * Get configured contract addresses
     */
    static getContractAddresses() {
        return {
            ipnft: process.env.IPNFT_ADDRESS || null,
            royaltyDistributor: process.env.ROYALTY_DISTRIBUTOR_ADDRESS || null,
            tokenizer: process.env.TOKENIZER_ADDRESS || null
        };
    }

    /**
     * Get IP-NFT metadata for a specific token
     */
    static async getIPNFTMetadata(tokenId) {
        if (!process.env.IPNFT_ADDRESS) {
            throw new Error('IP-NFT contract address not configured');
        }

        const provider = this.getProvider();
        const contract = new ethers.Contract(
            process.env.IPNFT_ADDRESS,
            IPNFT_ABI,
            provider
        );

        try {
            const [metadata, owner] = await Promise.all([
                contract.getIPMetadata(tokenId),
                contract.ownerOf(tokenId)
            ]);

            return {
                tokenId: tokenId.toString(),
                owner,
                cropSpecies: metadata[0],
                bacterialStrain: metadata[1],
                regulatoryStatus: metadata[2],
                licensedAcres: metadata[3].toString(),
                researchInstitution: metadata[4],
                approvalDate: new Date(Number(metadata[5]) * 1000).toISOString(),
                metadataURI: metadata[6]
            };
        } catch (error) {
            logger.error('Error fetching IP-NFT metadata:', error);
            throw new Error(`Failed to fetch metadata for token ${tokenId}`);
        }
    }

    /**
     * Get all IP-NFTs (up to total supply)
     */
    static async getAllIPNFTs() {
        if (!process.env.IPNFT_ADDRESS) {
            throw new Error('IP-NFT contract address not configured');
        }

        const provider = this.getProvider();
        const contract = new ethers.Contract(
            process.env.IPNFT_ADDRESS,
            IPNFT_ABI,
            provider
        );

        try {
            const totalSupply = await contract.totalSupply();
            const supply = Number(totalSupply);

            // Limit to first 100 tokens for performance
            const limit = Math.min(supply, 100);
            const ipnfts = [];

            for (let i = 0; i < limit; i++) {
                try {
                    const metadata = await this.getIPNFTMetadata(i);
                    ipnfts.push(metadata);
                } catch (error) {
                    logger.warn(`Skipping token ${i}:`, error.message);
                }
            }

            return {
                totalSupply: supply,
                tokens: ipnfts,
                showing: ipnfts.length
            };
        } catch (error) {
            logger.error('Error fetching all IP-NFTs:', error);
            throw new Error('Failed to fetch IP-NFT collection');
        }
    }

    /**
     * Get royalty distribution information
     */
    static async getRoyaltyInfo(tokenId) {
        if (!process.env.ROYALTY_DISTRIBUTOR_ADDRESS) {
            throw new Error('Royalty distributor address not configured');
        }

        const provider = this.getProvider();
        const contract = new ethers.Contract(
            process.env.ROYALTY_DISTRIBUTOR_ADDRESS,
            DISTRIBUTOR_ABI,
            provider
        );

        try {
            const [poolInfo, beneficiaries] = await Promise.all([
                contract.getPoolInfo(tokenId),
                contract.getBeneficiaries(tokenId)
            ]);

            return {
                tokenId: tokenId.toString(),
                totalReceived: ethers.formatEther(poolInfo[0]),
                totalDistributed: ethers.formatEther(poolInfo[1]),
                pendingDistribution: ethers.formatEther(poolInfo[2]),
                beneficiaries: beneficiaries[0].map((address, index) => ({
                    address,
                    shareBps: beneficiaries[1][index].toString(),
                    sharePercentage: (Number(beneficiaries[1][index]) / 100).toFixed(2) + '%',
                    isActive: beneficiaries[2][index]
                }))
            };
        } catch (error) {
            logger.error('Error fetching royalty info:', error);
            throw new Error(`Failed to fetch royalty info for token ${tokenId}`);
        }
    }
}

module.exports = ContractModel;
