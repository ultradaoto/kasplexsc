// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./AgriculturalIPNFT.sol";

/**
 * @title IPTokenizer
 * @author Kasplex Agricultural IP Team
 * @notice Fractionalizes IP-NFTs into fungible ERC-20 governance tokens (IPTs)
 * @dev Implements ERC20Votes for on-chain governance and revenue distribution
 *
 * This contract enables fractionalization of Agricultural IP-NFTs into tradeable
 * governance tokens. Token holders can vote on IP licensing decisions and receive
 * proportional revenue distributions from licensing fees.
 *
 * Key Features:
 * - Lock IP-NFT and mint fractional tokens
 * - Governance voting rights via ERC20Votes
 * - Revenue distribution to token holders
 * - Redemption mechanism (buyout with majority approval)
 * - UUPS upgradeable for future enhancements
 */
contract IPTokenizer is
    Initializable,
    ERC20Upgradeable,
    ERC20VotesUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    /// @dev Reference to the Agricultural IP-NFT contract
    AgriculturalIPNFT public ipnftContract;

    /// @dev Token ID of the fractionalized IP-NFT
    uint256 public ipnftTokenId;

    /// @dev Total supply of fractional tokens (fixed at initialization)
    uint256 private _totalFractionalSupply;

    /// @dev Minimum voting period for proposals (in blocks)
    uint256 public constant MIN_VOTING_PERIOD = 7200; // ~1 day at 12s blocks

    /// @dev Quorum threshold (percentage in basis points, e.g., 5100 = 51%)
    uint256 public quorumBps;

    /// @dev Flag indicating if NFT has been redeemed
    bool public isRedeemed;

    /// @dev Revenue distribution tracking
    uint256 public totalRevenue;
    uint256 public totalDistributed;
    mapping(address => uint256) public lastClaimedRevenue;

    /// @dev Proposal structure for governance
    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startBlock;
        uint256 endBlock;
        bool executed;
        bool canceled;
        mapping(address => bool) hasVoted;
        mapping(address => uint256) voteWeight;
    }

    /// @dev Mapping of proposal ID to proposal
    mapping(uint256 => Proposal) public proposals;

    /// @dev Proposal counter
    uint256 public proposalCount;

    /// @notice Emitted when IP-NFT is fractionalized
    event IPNFTFractionalized(
        uint256 indexed tokenId, address indexed owner, uint256 fractionalSupply
    );

    /// @notice Emitted when revenue is added for distribution
    event RevenueAdded(uint256 amount, uint256 totalRevenue);

    /// @notice Emitted when a token holder claims their revenue share
    event RevenueClaimed(address indexed holder, uint256 amount);

    /// @notice Emitted when a new proposal is created
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string description,
        uint256 startBlock,
        uint256 endBlock
    );

    /// @notice Emitted when a vote is cast
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);

    /// @notice Emitted when a proposal is executed
    event ProposalExecuted(uint256 indexed proposalId);

    /// @notice Emitted when IP-NFT is redeemed (buyout)
    event IPNFTRedeemed(address indexed redeemer, uint256 redemptionPrice);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the fractionalizer with an IP-NFT
     * @param _ipnftContract Address of the Agricultural IP-NFT contract
     * @param _ipnftTokenId Token ID to fractionalize
     * @param _fractionalSupply Total supply of fractional tokens to mint
     * @param _tokenName Name of the fractional token
     * @param _tokenSymbol Symbol of the fractional token
     * @param _initialOwner Owner who will receive initial token supply
     * @param _quorumBps Quorum threshold in basis points
     */
    function initialize(
        address _ipnftContract,
        uint256 _ipnftTokenId,
        uint256 _fractionalSupply,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _initialOwner,
        uint256 _quorumBps
    )
        public
        initializer
    {
        require(_ipnftContract != address(0), "IPTokenizer: IPNFT contract is zero address");
        require(_fractionalSupply > 0, "IPTokenizer: fractional supply must be positive");
        require(_initialOwner != address(0), "IPTokenizer: initial owner is zero address");
        require(_quorumBps > 0 && _quorumBps <= 10_000, "IPTokenizer: invalid quorum");

        __ERC20_init(_tokenName, _tokenSymbol);
        __ERC20Votes_init();
        __Ownable_init(_initialOwner);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        ipnftContract = AgriculturalIPNFT(_ipnftContract);
        ipnftTokenId = _ipnftTokenId;
        _totalFractionalSupply = _fractionalSupply;
        quorumBps = _quorumBps;
        isRedeemed = false;

        // Transfer NFT from owner to this contract
        IERC721(_ipnftContract).transferFrom(_initialOwner, address(this), _ipnftTokenId);

        // Mark NFT as fractionalized in the IPNFT contract
        ipnftContract.setFractionalized(_ipnftTokenId, address(this));

        // Mint fractional tokens to initial owner
        _mint(_initialOwner, _fractionalSupply);

        emit IPNFTFractionalized(_ipnftTokenId, _initialOwner, _fractionalSupply);
    }

    /**
     * @notice Adds revenue to be distributed among token holders
     * @dev Revenue is distributed proportionally based on token holdings
     */
    function addRevenue() external payable nonReentrant {
        require(msg.value > 0, "IPTokenizer: no revenue sent");
        require(!isRedeemed, "IPTokenizer: NFT has been redeemed");

        totalRevenue += msg.value;

        emit RevenueAdded(msg.value, totalRevenue);
    }

    /**
     * @notice Calculates claimable revenue for a token holder
     * @param _holder Address of the token holder
     * @return Claimable revenue amount
     */
    function claimableRevenue(address _holder) public view returns (uint256) {
        if (totalRevenue == 0 || balanceOf(_holder) == 0) {
            return 0;
        }

        uint256 holderShare = (totalRevenue * balanceOf(_holder)) / totalSupply();
        uint256 alreadyClaimed = lastClaimedRevenue[_holder];

        return holderShare > alreadyClaimed ? holderShare - alreadyClaimed : 0;
    }

    /**
     * @notice Allows token holders to claim their share of revenue
     */
    function claimRevenue() external nonReentrant {
        uint256 claimable = claimableRevenue(msg.sender);
        require(claimable > 0, "IPTokenizer: no revenue to claim");

        lastClaimedRevenue[msg.sender] += claimable;
        totalDistributed += claimable;

        (bool success,) = msg.sender.call{value: claimable}("");
        require(success, "IPTokenizer: revenue transfer failed");

        emit RevenueClaimed(msg.sender, claimable);
    }

    /**
     * @notice Creates a governance proposal
     * @param _description Description of the proposal
     * @param _votingPeriod Duration of voting in blocks
     * @return proposalId ID of the created proposal
     */
    function createProposal(
        string memory _description,
        uint256 _votingPeriod
    )
        external
        returns (uint256)
    {
        require(balanceOf(msg.sender) > 0, "IPTokenizer: must hold tokens to propose");
        require(_votingPeriod >= MIN_VOTING_PERIOD, "IPTokenizer: voting period too short");
        require(!isRedeemed, "IPTokenizer: NFT has been redeemed");

        proposalCount++;
        uint256 proposalId = proposalCount;

        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.description = _description;
        proposal.proposer = msg.sender;
        proposal.startBlock = block.number;
        proposal.endBlock = block.number + _votingPeriod;
        proposal.executed = false;
        proposal.canceled = false;

        emit ProposalCreated(
            proposalId, msg.sender, _description, proposal.startBlock, proposal.endBlock
        );

        return proposalId;
    }

    /**
     * @notice Casts a vote on a proposal
     * @param _proposalId ID of the proposal
     * @param _support True for yes, false for no
     */
    function castVote(uint256 _proposalId, bool _support) external {
        require(_proposalId > 0 && _proposalId <= proposalCount, "IPTokenizer: invalid proposal");
        Proposal storage proposal = proposals[_proposalId];

        require(block.number >= proposal.startBlock, "IPTokenizer: voting not started");
        require(block.number <= proposal.endBlock, "IPTokenizer: voting ended");
        require(!proposal.executed, "IPTokenizer: proposal already executed");
        require(!proposal.canceled, "IPTokenizer: proposal canceled");
        require(!proposal.hasVoted[msg.sender], "IPTokenizer: already voted");

        uint256 weight = getVotes(msg.sender);
        require(weight > 0, "IPTokenizer: no voting power");

        proposal.hasVoted[msg.sender] = true;
        proposal.voteWeight[msg.sender] = weight;

        if (_support) {
            proposal.forVotes += weight;
        } else {
            proposal.againstVotes += weight;
        }

        emit VoteCast(_proposalId, msg.sender, _support, weight);
    }

    /**
     * @notice Checks if a proposal has reached quorum
     * @param _proposalId ID of the proposal
     * @return Boolean indicating if quorum is reached
     */
    function hasQuorum(uint256 _proposalId) public view returns (bool) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "IPTokenizer: invalid proposal");
        Proposal storage proposal = proposals[_proposalId];

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        uint256 quorumRequired = (totalSupply() * quorumBps) / 10_000;

        return totalVotes >= quorumRequired;
    }

    /**
     * @notice Checks if a proposal has passed
     * @param _proposalId ID of the proposal
     * @return Boolean indicating if proposal passed
     */
    function proposalPassed(uint256 _proposalId) public view returns (bool) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "IPTokenizer: invalid proposal");
        Proposal storage proposal = proposals[_proposalId];

        return hasQuorum(_proposalId) && proposal.forVotes > proposal.againstVotes;
    }

    /**
     * @notice Executes a passed proposal
     * @param _proposalId ID of the proposal to execute
     */
    function executeProposal(uint256 _proposalId) external {
        require(_proposalId > 0 && _proposalId <= proposalCount, "IPTokenizer: invalid proposal");
        Proposal storage proposal = proposals[_proposalId];

        require(block.number > proposal.endBlock, "IPTokenizer: voting not ended");
        require(!proposal.executed, "IPTokenizer: already executed");
        require(!proposal.canceled, "IPTokenizer: proposal canceled");
        require(proposalPassed(_proposalId), "IPTokenizer: proposal did not pass");

        proposal.executed = true;

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Redeems the IP-NFT through a buyout mechanism
     * @dev Requires sending enough ETH to buy out all token holders
     */
    function redeemIPNFT() external payable nonReentrant {
        require(!isRedeemed, "IPTokenizer: already redeemed");
        require(msg.value >= _totalFractionalSupply, "IPTokenizer: insufficient redemption price");

        isRedeemed = true;

        // Add redemption payment to revenue pool for token holders to claim
        totalRevenue += msg.value;

        // Transfer NFT to redeemer
        IERC721(address(ipnftContract)).transferFrom(address(this), msg.sender, ipnftTokenId);

        emit IPNFTRedeemed(msg.sender, msg.value);
    }

    /**
     * @notice Hook called on token updates (transfer, mint, burn)
     * @dev Updates voting power tracking
     */
    function _update(
        address from,
        address to,
        uint256 value
    )
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._update(from, to, value);
    }

    /**
     * @notice Authorizes contract upgrades
     * @dev Can only be called by owner
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Returns the current block number
     * @dev Used by ERC20Votes for checkpoint tracking
     */
    function clock() public view override returns (uint48) {
        return uint48(block.number);
    }

    /**
     * @notice Returns the clock mode
     * @dev Used by ERC20Votes
     */
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=blocknumber&from=default";
    }

    /**
     * @notice Allows contract to receive ETH
     */
    receive() external payable {
        totalRevenue += msg.value;
        emit RevenueAdded(msg.value, totalRevenue);
    }
}
