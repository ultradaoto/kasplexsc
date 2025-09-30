// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/AgriculturalIPNFT.sol";
import "../src/IPTokenizer.sol";
import "../src/RoyaltyDistributor.sol";

/**
 * @title IntegrationTest
 * @notice Integration tests for the full IP tokenization system
 */
contract IntegrationTest is Test {
    AgriculturalIPNFT public ipnft;
    IPTokenizer public tokenizer;
    RoyaltyDistributor public distributor;

    address public admin;
    address public user1;
    address public user2;
    address public user3;

    uint256 public tokenId;

    function setUp() public {
        admin = makeAddr("admin");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        // Deploy IP-NFT
        AgriculturalIPNFT ipnftImpl = new AgriculturalIPNFT();
        bytes memory ipnftInitData = abi.encodeWithSelector(
            AgriculturalIPNFT.initialize.selector,
            "Agricultural IP-NFT",
            "AGRI-IP",
            admin,
            "ipfs://base/"
        );
        ERC1967Proxy ipnftProxy = new ERC1967Proxy(address(ipnftImpl), ipnftInitData);
        ipnft = AgriculturalIPNFT(address(ipnftProxy));

        // Deploy RoyaltyDistributor
        RoyaltyDistributor distImpl = new RoyaltyDistributor();
        bytes memory distInitData =
            abi.encodeWithSelector(RoyaltyDistributor.initialize.selector, admin);
        ERC1967Proxy distProxy = new ERC1967Proxy(address(distImpl), distInitData);
        distributor = RoyaltyDistributor(payable(address(distProxy)));

        // Mint an IP-NFT
        vm.prank(admin);
        tokenId = ipnft.mintIPNFT(
            user1,
            "Corn",
            "Bacillus thuringiensis",
            "FDA Approved",
            "Iowa State University",
            "ipfs://metadata",
            address(distributor),
            500 // 5% royalty
        );
    }

    function testFullTokenizationFlow() public {
        // 1. Deploy tokenizer implementation
        IPTokenizer tokenizerImpl = new IPTokenizer();

        // 2. Transfer NFT from user1 to user1 (just approve)
        vm.startPrank(user1);
        ipnft.setApprovalForAll(address(this), true);
        vm.stopPrank();

        bytes memory tokenizerInitData = abi.encodeWithSelector(
            IPTokenizer.initialize.selector,
            address(ipnft),
            tokenId,
            1_000_000 * 10 ** 18,
            "Agricultural IP Token",
            "AGRI-IPT",
            user1,
            5100 // 51% quorum
        );

        ERC1967Proxy tokenizerProxy = new ERC1967Proxy(address(tokenizerImpl), tokenizerInitData);
        tokenizer = IPTokenizer(payable(address(tokenizerProxy)));

        // 3. Verify fractionalization
        assertTrue(ipnft.isFramentalized(tokenId));
        assertEq(tokenizer.balanceOf(user1), 1_000_000 * 10 ** 18);
        assertEq(ipnft.ownerOf(tokenId), address(tokenizer));

        // 4. Transfer some tokens to user2
        vm.prank(user1);
        tokenizer.transfer(user2, 200_000 * 10 ** 18);

        assertEq(tokenizer.balanceOf(user2), 200_000 * 10 ** 18);

        // 5. Add revenue
        vm.deal(user3, 10 ether);
        vm.prank(user3);
        tokenizer.addRevenue{value: 5 ether}();

        assertEq(tokenizer.totalRevenue(), 5 ether);

        // 6. Claim revenue
        uint256 user2BalanceBefore = user2.balance;
        vm.prank(user2);
        tokenizer.claimRevenue();

        // User2 should have received 20% of 5 ether = 1 ether
        assertEq(user2.balance - user2BalanceBefore, 1 ether);
    }

    function testRoyaltyDistribution() public {
        // Create royalty pool with multiple beneficiaries
        address[] memory beneficiaries = new address[](3);
        beneficiaries[0] = user1;
        beneficiaries[1] = user2;
        beneficiaries[2] = user3;

        uint256[] memory shares = new uint256[](3);
        shares[0] = 5000; // 50%
        shares[1] = 3000; // 30%
        shares[2] = 2000; // 20%

        vm.prank(admin);
        distributor.createRoyaltyPool(tokenId, beneficiaries, shares);

        // Send royalties
        vm.deal(address(this), 10 ether);
        distributor.receiveRoyalties{value: 10 ether}(tokenId);

        // Check withdrawable amounts
        assertEq(distributor.withdrawableAmount(tokenId, user1), 5 ether);
        assertEq(distributor.withdrawableAmount(tokenId, user2), 3 ether);
        assertEq(distributor.withdrawableAmount(tokenId, user3), 2 ether);

        // Withdraw
        uint256 user1BalanceBefore = user1.balance;
        vm.prank(user1);
        distributor.withdrawRoyalties(tokenId);

        assertEq(user1.balance - user1BalanceBefore, 5 ether);
        assertEq(distributor.withdrawableAmount(tokenId, user1), 0);
    }

    function testGovernanceProposal() public {
        // Setup tokenizer first
        vm.startPrank(user1);
        ipnft.setApprovalForAll(address(this), true);
        vm.stopPrank();

        IPTokenizer tokenizerImpl = new IPTokenizer();
        bytes memory tokenizerInitData = abi.encodeWithSelector(
            IPTokenizer.initialize.selector,
            address(ipnft),
            tokenId,
            1_000_000 * 10 ** 18,
            "Agricultural IP Token",
            "AGRI-IPT",
            user1,
            5100
        );

        ERC1967Proxy tokenizerProxy = new ERC1967Proxy(address(tokenizerImpl), tokenizerInitData);
        tokenizer = IPTokenizer(payable(address(tokenizerProxy)));

        // Delegate voting power
        vm.prank(user1);
        tokenizer.delegate(user1);

        // Create proposal
        vm.prank(user1);
        uint256 proposalId = tokenizer.createProposal("Increase licensing fees", 7200);

        // Transfer some tokens to user2
        vm.prank(user1);
        tokenizer.transfer(user2, 300_000 * 10 ** 18);

        vm.prank(user2);
        tokenizer.delegate(user2);

        // Vote on proposal
        vm.roll(block.number + 1);

        vm.prank(user1);
        tokenizer.castVote(proposalId, true);

        vm.prank(user2);
        tokenizer.castVote(proposalId, false);

        // Check if proposal passed
        vm.roll(block.number + 7201);
        assertTrue(tokenizer.hasQuorum(proposalId));
        assertTrue(tokenizer.proposalPassed(proposalId));
    }

    receive() external payable {}
}
