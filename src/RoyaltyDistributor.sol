// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title RoyaltyDistributor
 * @author Kasplex Agricultural IP Team
 * @notice Automated royalty distribution system for Agricultural IP-NFTs
 * @dev Implements pull-based payment system with multi-beneficiary support
 *
 * This contract manages automated royalty distributions from agricultural IP licensing.
 * It supports multiple beneficiaries per IP-NFT, tracks all distributions for compliance,
 * and uses a pull-based payment system to optimize gas costs.
 *
 * Key Features:
 * - Multiple beneficiaries with custom share percentages
 * - Pull-based payment to minimize gas costs
 * - Comprehensive distribution tracking for compliance
 * - Emergency pause functionality
 * - UUPS upgradeable pattern
 */
contract RoyaltyDistributor is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using Address for address payable;

    /// @dev Basis points denominator (10000 = 100%)
    uint256 public constant BPS_DENOMINATOR = 10_000;

    /// @dev Maximum number of beneficiaries per IP
    uint256 public constant MAX_BENEFICIARIES = 50;

    /**
     * @dev Beneficiary structure
     * @param beneficiary Address of the beneficiary
     * @param shareBps Share percentage in basis points
     * @param isActive Whether the beneficiary is currently active
     */
    struct Beneficiary {
        address beneficiary;
        uint256 shareBps;
        bool isActive;
    }

    /**
     * @dev Royalty pool structure for each IP-NFT
     * @param ipnftTokenId Associated IP-NFT token ID
     * @param beneficiaries Array of beneficiaries
     * @param totalReceived Total royalties received
     * @param totalDistributed Total royalties distributed
     * @param pendingDistribution Amount pending distribution
     */
    struct RoyaltyPool {
        uint256 ipnftTokenId;
        Beneficiary[] beneficiaries;
        uint256 totalReceived;
        uint256 totalDistributed;
        uint256 pendingDistribution;
    }

    /// @dev Mapping from IP-NFT token ID to royalty pool
    mapping(uint256 => RoyaltyPool) public royaltyPools;

    /// @dev Mapping from token ID to beneficiary address to withdrawn amount
    mapping(uint256 => mapping(address => uint256)) public withdrawnAmount;

    /// @dev Mapping to track which token IDs have been initialized
    mapping(uint256 => bool) public poolExists;

    /// @dev Distribution history for compliance tracking
    struct DistributionRecord {
        uint256 timestamp;
        uint256 amount;
        address beneficiary;
        uint256 ipnftTokenId;
    }

    /// @dev Array of all distribution records
    DistributionRecord[] public distributionHistory;

    /// @dev Mapping from beneficiary to their distribution indices
    mapping(address => uint256[]) public beneficiaryDistributions;

    /// @notice Emitted when a royalty pool is created
    event RoyaltyPoolCreated(uint256 indexed ipnftTokenId, uint256 beneficiaryCount);

    /// @notice Emitted when a beneficiary is added
    event BeneficiaryAdded(
        uint256 indexed ipnftTokenId, address indexed beneficiary, uint256 shareBps
    );

    /// @notice Emitted when a beneficiary is updated
    event BeneficiaryUpdated(
        uint256 indexed ipnftTokenId, address indexed beneficiary, uint256 newShareBps
    );

    /// @notice Emitted when a beneficiary is removed
    event BeneficiaryRemoved(uint256 indexed ipnftTokenId, address indexed beneficiary);

    /// @notice Emitted when royalties are received
    event RoyaltiesReceived(uint256 indexed ipnftTokenId, uint256 amount, address indexed sender);

    /// @notice Emitted when royalties are withdrawn
    event RoyaltiesWithdrawn(
        uint256 indexed ipnftTokenId, address indexed beneficiary, uint256 amount
    );

    /// @notice Emitted when royalties are distributed
    event RoyaltiesDistributed(uint256 indexed ipnftTokenId, uint256 totalAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract
     * @param _owner Owner address
     */
    function initialize(address _owner) public initializer {
        require(_owner != address(0), "RoyaltyDistributor: owner is zero address");

        __Ownable_init(_owner);
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @notice Creates a new royalty pool for an IP-NFT
     * @param _ipnftTokenId Token ID of the IP-NFT
     * @param _beneficiaries Array of beneficiary addresses
     * @param _shareBps Array of share percentages in basis points
     */
    function createRoyaltyPool(
        uint256 _ipnftTokenId,
        address[] calldata _beneficiaries,
        uint256[] calldata _shareBps
    )
        external
        onlyOwner
    {
        require(!poolExists[_ipnftTokenId], "RoyaltyDistributor: pool already exists");
        require(_beneficiaries.length > 0, "RoyaltyDistributor: no beneficiaries");
        require(
            _beneficiaries.length == _shareBps.length, "RoyaltyDistributor: array length mismatch"
        );
        require(
            _beneficiaries.length <= MAX_BENEFICIARIES, "RoyaltyDistributor: too many beneficiaries"
        );

        // Validate shares sum to 100%
        uint256 totalShares = 0;
        for (uint256 i = 0; i < _shareBps.length; i++) {
            require(_beneficiaries[i] != address(0), "RoyaltyDistributor: zero address beneficiary");
            require(_shareBps[i] > 0, "RoyaltyDistributor: share must be positive");
            totalShares += _shareBps[i];
        }
        require(totalShares == BPS_DENOMINATOR, "RoyaltyDistributor: shares must equal 100%");

        poolExists[_ipnftTokenId] = true;
        RoyaltyPool storage pool = royaltyPools[_ipnftTokenId];
        pool.ipnftTokenId = _ipnftTokenId;

        // Add beneficiaries
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            pool.beneficiaries.push(
                Beneficiary({beneficiary: _beneficiaries[i], shareBps: _shareBps[i], isActive: true})
            );

            emit BeneficiaryAdded(_ipnftTokenId, _beneficiaries[i], _shareBps[i]);
        }

        emit RoyaltyPoolCreated(_ipnftTokenId, _beneficiaries.length);
    }

    /**
     * @notice Receives royalty payment for a specific IP-NFT
     * @param _ipnftTokenId Token ID of the IP-NFT
     */
    function receiveRoyalties(uint256 _ipnftTokenId) external payable whenNotPaused {
        require(poolExists[_ipnftTokenId], "RoyaltyDistributor: pool does not exist");
        require(msg.value > 0, "RoyaltyDistributor: no payment sent");

        RoyaltyPool storage pool = royaltyPools[_ipnftTokenId];
        pool.totalReceived += msg.value;
        pool.pendingDistribution += msg.value;

        emit RoyaltiesReceived(_ipnftTokenId, msg.value, msg.sender);
    }

    /**
     * @notice Calculates withdrawable amount for a beneficiary
     * @param _ipnftTokenId Token ID of the IP-NFT
     * @param _beneficiary Address of the beneficiary
     * @return Withdrawable amount
     */
    function withdrawableAmount(
        uint256 _ipnftTokenId,
        address _beneficiary
    )
        public
        view
        returns (uint256)
    {
        require(poolExists[_ipnftTokenId], "RoyaltyDistributor: pool does not exist");

        RoyaltyPool storage pool = royaltyPools[_ipnftTokenId];
        uint256 beneficiaryShare = 0;

        // Find beneficiary and their share
        for (uint256 i = 0; i < pool.beneficiaries.length; i++) {
            if (pool.beneficiaries[i].beneficiary == _beneficiary && pool.beneficiaries[i].isActive)
            {
                beneficiaryShare = pool.beneficiaries[i].shareBps;
                break;
            }
        }

        if (beneficiaryShare == 0) {
            return 0;
        }

        // Calculate total owed
        uint256 totalOwed = (pool.totalReceived * beneficiaryShare) / BPS_DENOMINATOR;

        // Subtract already withdrawn
        uint256 alreadyWithdrawn = withdrawnAmount[_ipnftTokenId][_beneficiary];

        return totalOwed > alreadyWithdrawn ? totalOwed - alreadyWithdrawn : 0;
    }

    /**
     * @notice Allows beneficiary to withdraw their share
     * @param _ipnftTokenId Token ID of the IP-NFT
     */
    function withdrawRoyalties(uint256 _ipnftTokenId) external nonReentrant whenNotPaused {
        uint256 amount = withdrawableAmount(_ipnftTokenId, msg.sender);
        require(amount > 0, "RoyaltyDistributor: no royalties to withdraw");

        RoyaltyPool storage pool = royaltyPools[_ipnftTokenId];

        withdrawnAmount[_ipnftTokenId][msg.sender] += amount;
        pool.totalDistributed += amount;
        pool.pendingDistribution -= amount;

        // Record distribution for compliance
        distributionHistory.push(
            DistributionRecord({
                timestamp: block.timestamp,
                amount: amount,
                beneficiary: msg.sender,
                ipnftTokenId: _ipnftTokenId
            })
        );

        beneficiaryDistributions[msg.sender].push(distributionHistory.length - 1);

        // Transfer funds
        payable(msg.sender).sendValue(amount);

        emit RoyaltiesWithdrawn(_ipnftTokenId, msg.sender, amount);
    }

    /**
     * @notice Batch withdraw for multiple IP-NFTs
     * @param _ipnftTokenIds Array of IP-NFT token IDs
     */
    function batchWithdrawRoyalties(uint256[] calldata _ipnftTokenIds)
        external
        nonReentrant
        whenNotPaused
    {
        require(_ipnftTokenIds.length > 0, "RoyaltyDistributor: no token IDs provided");
        require(_ipnftTokenIds.length <= 20, "RoyaltyDistributor: too many token IDs");

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < _ipnftTokenIds.length; i++) {
            uint256 amount = withdrawableAmount(_ipnftTokenIds[i], msg.sender);

            if (amount > 0) {
                RoyaltyPool storage pool = royaltyPools[_ipnftTokenIds[i]];

                withdrawnAmount[_ipnftTokenIds[i]][msg.sender] += amount;
                pool.totalDistributed += amount;
                pool.pendingDistribution -= amount;

                // Record distribution
                distributionHistory.push(
                    DistributionRecord({
                        timestamp: block.timestamp,
                        amount: amount,
                        beneficiary: msg.sender,
                        ipnftTokenId: _ipnftTokenIds[i]
                    })
                );

                beneficiaryDistributions[msg.sender].push(distributionHistory.length - 1);

                totalAmount += amount;

                emit RoyaltiesWithdrawn(_ipnftTokenIds[i], msg.sender, amount);
            }
        }

        require(totalAmount > 0, "RoyaltyDistributor: no royalties to withdraw");

        // Transfer total funds
        payable(msg.sender).sendValue(totalAmount);
    }

    /**
     * @notice Updates a beneficiary's share
     * @param _ipnftTokenId Token ID of the IP-NFT
     * @param _beneficiary Address of the beneficiary
     * @param _newShareBps New share in basis points
     */
    function updateBeneficiary(
        uint256 _ipnftTokenId,
        address _beneficiary,
        uint256 _newShareBps
    )
        external
        onlyOwner
    {
        require(poolExists[_ipnftTokenId], "RoyaltyDistributor: pool does not exist");
        require(_beneficiary != address(0), "RoyaltyDistributor: zero address beneficiary");

        RoyaltyPool storage pool = royaltyPools[_ipnftTokenId];
        bool found = false;
        uint256 totalShares = 0;

        for (uint256 i = 0; i < pool.beneficiaries.length; i++) {
            if (pool.beneficiaries[i].beneficiary == _beneficiary) {
                pool.beneficiaries[i].shareBps = _newShareBps;
                found = true;
            }
            if (pool.beneficiaries[i].isActive) {
                totalShares += pool.beneficiaries[i].shareBps;
            }
        }

        require(found, "RoyaltyDistributor: beneficiary not found");
        require(totalShares == BPS_DENOMINATOR, "RoyaltyDistributor: shares must equal 100%");

        emit BeneficiaryUpdated(_ipnftTokenId, _beneficiary, _newShareBps);
    }

    /**
     * @notice Removes a beneficiary
     * @param _ipnftTokenId Token ID of the IP-NFT
     * @param _beneficiary Address of the beneficiary to remove
     */
    function removeBeneficiary(uint256 _ipnftTokenId, address _beneficiary) external onlyOwner {
        require(poolExists[_ipnftTokenId], "RoyaltyDistributor: pool does not exist");

        RoyaltyPool storage pool = royaltyPools[_ipnftTokenId];

        for (uint256 i = 0; i < pool.beneficiaries.length; i++) {
            if (pool.beneficiaries[i].beneficiary == _beneficiary) {
                pool.beneficiaries[i].isActive = false;
                emit BeneficiaryRemoved(_ipnftTokenId, _beneficiary);
                return;
            }
        }

        revert("RoyaltyDistributor: beneficiary not found");
    }

    /**
     * @notice Returns all beneficiaries for an IP-NFT
     * @param _ipnftTokenId Token ID of the IP-NFT
     * @return Array of beneficiary addresses and their shares
     */
    function getBeneficiaries(uint256 _ipnftTokenId)
        external
        view
        returns (address[] memory, uint256[] memory, bool[] memory)
    {
        require(poolExists[_ipnftTokenId], "RoyaltyDistributor: pool does not exist");

        RoyaltyPool storage pool = royaltyPools[_ipnftTokenId];
        uint256 length = pool.beneficiaries.length;

        address[] memory addresses = new address[](length);
        uint256[] memory shares = new uint256[](length);
        bool[] memory activeStatus = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            addresses[i] = pool.beneficiaries[i].beneficiary;
            shares[i] = pool.beneficiaries[i].shareBps;
            activeStatus[i] = pool.beneficiaries[i].isActive;
        }

        return (addresses, shares, activeStatus);
    }

    /**
     * @notice Returns pool information
     * @param _ipnftTokenId Token ID of the IP-NFT
     * @return totalReceived Total royalties received
     * @return totalDistributed Total royalties distributed
     * @return pendingDistribution Amount pending distribution
     */
    function getPoolInfo(uint256 _ipnftTokenId)
        external
        view
        returns (uint256 totalReceived, uint256 totalDistributed, uint256 pendingDistribution)
    {
        require(poolExists[_ipnftTokenId], "RoyaltyDistributor: pool does not exist");

        RoyaltyPool storage pool = royaltyPools[_ipnftTokenId];
        return (pool.totalReceived, pool.totalDistributed, pool.pendingDistribution);
    }

    /**
     * @notice Returns distribution history for a beneficiary
     * @param _beneficiary Address of the beneficiary
     * @return Array of distribution record indices
     */
    function getDistributionHistory(address _beneficiary)
        external
        view
        returns (uint256[] memory)
    {
        return beneficiaryDistributions[_beneficiary];
    }

    /**
     * @notice Returns total number of distribution records
     * @return Total distribution records
     */
    function getDistributionCount() external view returns (uint256) {
        return distributionHistory.length;
    }

    /**
     * @notice Pauses the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Authorizes contract upgrades
     * @dev Can only be called by owner
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Allows contract to receive ETH
     */
    receive() external payable {
        revert("RoyaltyDistributor: use receiveRoyalties function");
    }
}
