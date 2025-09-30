// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/AgriculturalIPNFT.sol";
import "../src/IPTokenizer.sol";
import "../src/RoyaltyDistributor.sol";

/**
 * @title DeployScript
 * @notice Deployment script for Agricultural IP tokenization system on Kasplex testnet
 * @dev Deploys upgradeable contracts using UUPS proxy pattern
 */
contract DeployScript is Script {
    // Deployment addresses (will be set during deployment)
    address public admin;
    address public ipnftProxy;
    address public royaltyDistributorProxy;

    function setUp() public {}

    /**
     * @notice Main deployment function
     * @dev Deploys all three core contracts with proxy pattern
     */
    function run() public {
        // Get deployer from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        admin = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("Kasplex Agricultural IP Deployment");
        console.log("========================================");
        console.log("Deployer:", admin);
        console.log("Chain ID:", block.chainid);
        console.log("========================================");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Agricultural IP-NFT
        console.log("\n1. Deploying AgriculturalIPNFT...");
        address ipnftImpl = address(new AgriculturalIPNFT());
        console.log("   Implementation:", ipnftImpl);

        bytes memory ipnftInitData = abi.encodeWithSelector(
            AgriculturalIPNFT.initialize.selector,
            "Agricultural IP-NFT", // name
            "AGRI-IP", // symbol
            admin, // admin
            "ipfs://" // base URI
        );

        ipnftProxy = address(new ERC1967Proxy(ipnftImpl, ipnftInitData));
        console.log("   Proxy:", ipnftProxy);

        // Deploy RoyaltyDistributor
        console.log("\n2. Deploying RoyaltyDistributor...");
        address royaltyImpl = address(new RoyaltyDistributor());
        console.log("   Implementation:", royaltyImpl);

        bytes memory royaltyInitData = abi.encodeWithSelector(
            RoyaltyDistributor.initialize.selector,
            admin // owner
        );

        royaltyDistributorProxy = address(new ERC1967Proxy(royaltyImpl, royaltyInitData));
        console.log("   Proxy:", royaltyDistributorProxy);

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n========================================");
        console.log("Deployment Summary");
        console.log("========================================");
        console.log("Network: Kasplex Testnet");
        console.log("AgriculturalIPNFT Proxy:", ipnftProxy);
        console.log("RoyaltyDistributor Proxy:", royaltyDistributorProxy);
        console.log("Admin:", admin);
        console.log("========================================");
        console.log("\nSave these addresses for frontend integration!");
        console.log("========================================\n");
    }
}

/**
 * @title DeployIPTokenizer
 * @notice Deployment script for fractionalizing an IP-NFT
 * @dev This script should be run after an IP-NFT has been minted
 */
contract DeployIPTokenizer is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Get parameters from environment
        address ipnftAddress = vm.envAddress("IPNFT_ADDRESS");
        uint256 tokenId = vm.envUint("TOKEN_ID");
        uint256 fractionalSupply = vm.envOr("FRACTIONAL_SUPPLY", uint256(1_000_000 * 10**18));
        uint256 quorumBps = vm.envOr("QUORUM_BPS", uint256(5100)); // 51% default

        console.log("========================================");
        console.log("IPTokenizer Deployment");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("IP-NFT Address:", ipnftAddress);
        console.log("Token ID:", tokenId);
        console.log("Fractional Supply:", fractionalSupply);
        console.log("Quorum:", quorumBps, "bps");
        console.log("========================================");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy IPTokenizer
        console.log("\nDeploying IPTokenizer...");
        address tokenizerImpl = address(new IPTokenizer());
        console.log("   Implementation:", tokenizerImpl);

        bytes memory tokenizerInitData = abi.encodeWithSelector(
            IPTokenizer.initialize.selector,
            ipnftAddress,
            tokenId,
            fractionalSupply,
            "Agricultural IP Token", // token name
            "AGRI-IPT", // token symbol
            deployer, // initial owner
            quorumBps
        );

        address tokenizerProxy = address(new ERC1967Proxy(tokenizerImpl, tokenizerInitData));
        console.log("   Proxy:", tokenizerProxy);

        vm.stopBroadcast();

        console.log("\n========================================");
        console.log("IPTokenizer Proxy:", tokenizerProxy);
        console.log("Token fractionalized successfully!");
        console.log("========================================\n");
    }
}
