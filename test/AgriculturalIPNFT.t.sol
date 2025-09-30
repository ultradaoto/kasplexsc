// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/AgriculturalIPNFT.sol";

/**
 * @title AgriculturalIPNFTTest
 * @notice Comprehensive test suite for Agricultural IP-NFT contract
 */
contract AgriculturalIPNFTTest is Test {
    AgriculturalIPNFT public ipnft;
    address public admin;
    address public minter;
    address public user1;
    address public user2;

    // Events to test
    event IPNFTMinted(
        uint256 indexed tokenId,
        address indexed owner,
        string cropSpecies,
        string bacterialStrain,
        string metadataURI
    );

    function setUp() public {
        admin = makeAddr("admin");
        minter = makeAddr("minter");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy implementation
        AgriculturalIPNFT implementation = new AgriculturalIPNFT();

        // Deploy proxy
        bytes memory initData = abi.encodeWithSelector(
            AgriculturalIPNFT.initialize.selector,
            "Agricultural IP-NFT",
            "AGRI-IP",
            admin,
            "ipfs://base/"
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        ipnft = AgriculturalIPNFT(address(proxy));

        // Grant minter role
        vm.startPrank(admin);
        ipnft.grantRole(ipnft.MINTER_ROLE(), minter);
        vm.stopPrank();
    }

    function testInitialization() public view {
        assertEq(ipnft.name(), "Agricultural IP-NFT");
        assertEq(ipnft.symbol(), "AGRI-IP");
        assertTrue(ipnft.hasRole(ipnft.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(ipnft.hasRole(ipnft.MINTER_ROLE(), admin));
        assertTrue(ipnft.hasRole(ipnft.MINTER_ROLE(), minter));
    }

    function testMintIPNFT() public {
        vm.prank(minter);

        vm.expectEmit(true, true, false, true);
        emit IPNFTMinted(0, user1, "Corn", "Bacillus thuringiensis", "ipfs://metadata");

        uint256 tokenId = ipnft.mintIPNFT(
            user1,
            "Corn",
            "Bacillus thuringiensis",
            "FDA Approved",
            "Iowa State University",
            "ipfs://metadata",
            user1,
            500 // 5% royalty
        );

        assertEq(tokenId, 0);
        assertEq(ipnft.ownerOf(0), user1);
        assertEq(ipnft.totalSupply(), 1);

        AgriculturalIPNFT.IPMetadata memory metadata = ipnft.getIPMetadata(0);
        assertEq(metadata.cropSpecies, "Corn");
        assertEq(metadata.bacterialStrain, "Bacillus thuringiensis");
        assertEq(metadata.regulatoryStatus, "FDA Approved");
        assertEq(metadata.researchInstitution, "Iowa State University");
    }

    function testCannotMintWithoutRole() public {
        vm.prank(user1);
        vm.expectRevert();
        ipnft.mintIPNFT(
            user1,
            "Corn",
            "Bacillus thuringiensis",
            "FDA Approved",
            "Iowa State University",
            "ipfs://metadata",
            user1,
            500
        );
    }

    function testCannotMintToZeroAddress() public {
        vm.prank(minter);
        vm.expectRevert("AgriculturalIPNFT: mint to zero address");
        ipnft.mintIPNFT(
            address(0),
            "Corn",
            "Bacillus thuringiensis",
            "FDA Approved",
            "Iowa State University",
            "ipfs://metadata",
            user1,
            500
        );
    }

    function testCannotMintWithRoyaltyTooHigh() public {
        vm.prank(minter);
        vm.expectRevert("AgriculturalIPNFT: royalty too high");
        ipnft.mintIPNFT(
            user1,
            "Corn",
            "Bacillus thuringiensis",
            "FDA Approved",
            "Iowa State University",
            "ipfs://metadata",
            user1,
            1001 // Over 10%
        );
    }

    function testUpdateLicensedAcres() public {
        // First mint a token
        vm.prank(minter);
        uint256 tokenId = ipnft.mintIPNFT(
            user1,
            "Corn",
            "Bacillus thuringiensis",
            "FDA Approved",
            "Iowa State University",
            "ipfs://metadata",
            user1,
            500
        );

        // Grant licensing role to admin
        vm.startPrank(admin);
        ipnft.grantRole(ipnft.LICENSING_ROLE(), admin);
        vm.stopPrank();

        // Update licensed acres
        vm.prank(admin);
        ipnft.updateLicensedAcres(tokenId, 10_000);

        AgriculturalIPNFT.IPMetadata memory metadata = ipnft.getIPMetadata(tokenId);
        assertEq(metadata.licensedAcres, 10_000);
    }

    function testUpdateMetadataURI() public {
        // Mint token
        vm.prank(minter);
        uint256 tokenId = ipnft.mintIPNFT(
            user1,
            "Corn",
            "Bacillus thuringiensis",
            "FDA Approved",
            "Iowa State University",
            "ipfs://old-metadata",
            user1,
            500
        );

        // Update metadata URI
        vm.prank(minter);
        ipnft.updateMetadataURI(tokenId, "ipfs://new-metadata");

        AgriculturalIPNFT.IPMetadata memory metadata = ipnft.getIPMetadata(tokenId);
        assertEq(metadata.metadataURI, "ipfs://new-metadata");
    }

    function testPauseUnpause() public {
        // Mint a token first
        vm.prank(minter);
        uint256 tokenId = ipnft.mintIPNFT(
            user1,
            "Corn",
            "Bacillus thuringiensis",
            "FDA Approved",
            "Iowa State University",
            "ipfs://metadata",
            user1,
            500
        );

        // Pause contract
        vm.prank(admin);
        ipnft.pause();

        // Try to transfer - should fail
        vm.prank(user1);
        vm.expectRevert();
        ipnft.transferFrom(user1, user2, tokenId);

        // Unpause
        vm.prank(admin);
        ipnft.unpause();

        // Transfer should work now
        vm.prank(user1);
        ipnft.transferFrom(user1, user2, tokenId);
        assertEq(ipnft.ownerOf(tokenId), user2);
    }

    function testRoyaltyInfo() public {
        // Mint token with 5% royalty
        vm.prank(minter);
        uint256 tokenId = ipnft.mintIPNFT(
            user1,
            "Corn",
            "Bacillus thuringiensis",
            "FDA Approved",
            "Iowa State University",
            "ipfs://metadata",
            user1,
            500
        );

        // Check royalty info
        (address receiver, uint256 royaltyAmount) = ipnft.royaltyInfo(tokenId, 10_000);
        assertEq(receiver, user1);
        assertEq(royaltyAmount, 500); // 5% of 10000
    }

    function testSetFractionalized() public {
        // Mint token
        vm.prank(minter);
        uint256 tokenId = ipnft.mintIPNFT(
            user1,
            "Corn",
            "Bacillus thuringiensis",
            "FDA Approved",
            "Iowa State University",
            "ipfs://metadata",
            user1,
            500
        );

        address fractionalizer = makeAddr("fractionalizer");

        // Mark as fractionalized
        vm.prank(minter);
        ipnft.setFractionalized(tokenId, fractionalizer);

        assertTrue(ipnft.isFramentalized(tokenId));
        assertEq(ipnft.getFractionalizer(tokenId), fractionalizer);
    }

    function testFuzzMintIPNFT(address _to, uint96 _royaltyBps) public {
        vm.assume(_to != address(0));
        vm.assume(_royaltyBps <= 1000);
        vm.assume(_to.code.length == 0); // Only EOAs, not contracts

        vm.prank(minter);
        uint256 tokenId = ipnft.mintIPNFT(
            _to,
            "Corn",
            "Bacillus thuringiensis",
            "FDA Approved",
            "Iowa State University",
            "ipfs://metadata",
            _to,
            _royaltyBps
        );

        assertEq(ipnft.ownerOf(tokenId), _to);

        (address receiver,) = ipnft.royaltyInfo(tokenId, 10_000);
        assertEq(receiver, _to);
    }
}
