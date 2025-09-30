// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title AgriculturalIPNFT
 * @author Kasplex Agricultural IP Team
 * @notice ERC-721 based IP-NFT for tokenizing agricultural biotech intellectual property
 * @dev Implements ERC-2981 for royalty standard with role-based access control
 *
 * This contract enables the tokenization of agricultural biotechnology IP, specifically
 * for bacterial pesticide alternatives. Each NFT represents ownership of unique IP
 * with associated metadata including crop species, bacterial strain information,
 * regulatory approvals, and licensed acreage data.
 *
 * Security Features:
 * - Role-based access control (MINTER_ROLE, LICENSING_ROLE, UPGRADER_ROLE)
 * - Pausable for emergency situations
 * - ReentrancyGuard for external calls
 * - UUPS upgradeable pattern for future improvements
 */
contract AgriculturalIPNFT is
    Initializable,
    ERC721Upgradeable,
    ERC2981Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    /// @dev Role definitions
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant LICENSING_ROLE = keccak256("LICENSING_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @dev Token ID counter
    uint256 private _tokenIdCounter;

    /// @dev Maximum royalty basis points (10% = 1000 bps)
    uint96 public constant MAX_ROYALTY_BPS = 1000;

    /**
     * @dev Metadata structure for agricultural IP
     * @param cropSpecies Target crop for the bacterial pesticide
     * @param bacterialStrain Specific bacterial strain identifier
     * @param regulatoryStatus Current regulatory approval status
     * @param licensedAcres Number of acres currently licensed
     * @param researchInstitution Originating research institution
     * @param approvalDate Timestamp of regulatory approval
     * @param metadataURI IPFS URI for detailed metadata
     */
    struct IPMetadata {
        string cropSpecies;
        string bacterialStrain;
        string regulatoryStatus;
        uint256 licensedAcres;
        string researchInstitution;
        uint256 approvalDate;
        string metadataURI;
    }

    /// @dev Mapping from token ID to IP metadata
    mapping(uint256 => IPMetadata) private _ipMetadata;

    /// @dev Mapping from token ID to fractionalizer contract address
    mapping(uint256 => address) private _fractionalizers;

    /// @dev Mapping to track if a token has been fractionalized
    mapping(uint256 => bool) private _isFramentalized;

    /// @dev Base URI for token metadata
    string private _baseTokenURI;

    /// @notice Emitted when a new IP-NFT is minted
    event IPNFTMinted(
        uint256 indexed tokenId,
        address indexed owner,
        string cropSpecies,
        string bacterialStrain,
        string metadataURI
    );

    /// @notice Emitted when IP metadata is updated
    event MetadataUpdated(uint256 indexed tokenId, string metadataURI);

    /// @notice Emitted when licensed acreage is updated
    event LicensedAcresUpdated(uint256 indexed tokenId, uint256 newAcreage);

    /// @notice Emitted when an IP-NFT is fractionalized
    event IPNFTFractionalized(
        uint256 indexed tokenId, address indexed fractionalizer, address indexed tokenOwner
    );

    /// @notice Emitted when royalty information is updated
    event RoyaltyUpdated(uint256 indexed tokenId, address receiver, uint96 feeNumerator);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _admin Admin address for access control
     * @param baseURI_ Base URI for token metadata
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _admin,
        string memory baseURI_
    )
        public
        initializer
    {
        require(_admin != address(0), "AgriculturalIPNFT: admin is zero address");

        __ERC721_init(_name, _symbol);
        __ERC2981_init();
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _baseTokenURI = baseURI_;

        // Grant roles to admin
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MINTER_ROLE, _admin);
        _grantRole(LICENSING_ROLE, _admin);
        _grantRole(UPGRADER_ROLE, _admin);
    }

    /**
     * @notice Mints a new IP-NFT
     * @param _to Recipient address
     * @param _cropSpecies Target crop species
     * @param _bacterialStrain Bacterial strain identifier
     * @param _regulatoryStatus Regulatory approval status
     * @param _researchInstitution Originating institution
     * @param _metadataURI IPFS URI for metadata
     * @param _royaltyReceiver Address to receive royalties
     * @param _royaltyBps Royalty percentage in basis points
     * @return tokenId The ID of the newly minted token
     */
    function mintIPNFT(
        address _to,
        string memory _cropSpecies,
        string memory _bacterialStrain,
        string memory _regulatoryStatus,
        string memory _researchInstitution,
        string memory _metadataURI,
        address _royaltyReceiver,
        uint96 _royaltyBps
    )
        external
        onlyRole(MINTER_ROLE)
        whenNotPaused
        returns (uint256)
    {
        require(_to != address(0), "AgriculturalIPNFT: mint to zero address");
        require(
            _royaltyReceiver != address(0), "AgriculturalIPNFT: royalty receiver is zero address"
        );
        require(_royaltyBps <= MAX_ROYALTY_BPS, "AgriculturalIPNFT: royalty too high");
        require(bytes(_cropSpecies).length > 0, "AgriculturalIPNFT: crop species required");
        require(bytes(_bacterialStrain).length > 0, "AgriculturalIPNFT: bacterial strain required");

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(_to, tokenId);

        // Set IP metadata
        _ipMetadata[tokenId] = IPMetadata({
            cropSpecies: _cropSpecies,
            bacterialStrain: _bacterialStrain,
            regulatoryStatus: _regulatoryStatus,
            licensedAcres: 0,
            researchInstitution: _researchInstitution,
            approvalDate: block.timestamp,
            metadataURI: _metadataURI
        });

        // Set royalty information
        _setTokenRoyalty(tokenId, _royaltyReceiver, _royaltyBps);

        emit IPNFTMinted(tokenId, _to, _cropSpecies, _bacterialStrain, _metadataURI);

        return tokenId;
    }

    /**
     * @notice Updates the metadata URI for a token
     * @param _tokenId Token ID
     * @param _newMetadataURI New IPFS metadata URI
     */
    function updateMetadataURI(
        uint256 _tokenId,
        string memory _newMetadataURI
    )
        external
        onlyRole(MINTER_ROLE)
    {
        require(ownerOf(_tokenId) != address(0), "AgriculturalIPNFT: token does not exist");
        require(bytes(_newMetadataURI).length > 0, "AgriculturalIPNFT: metadata URI required");

        _ipMetadata[_tokenId].metadataURI = _newMetadataURI;

        emit MetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @notice Updates the licensed acreage for a token
     * @param _tokenId Token ID
     * @param _newAcreage New licensed acreage amount
     */
    function updateLicensedAcres(
        uint256 _tokenId,
        uint256 _newAcreage
    )
        external
        onlyRole(LICENSING_ROLE)
    {
        require(ownerOf(_tokenId) != address(0), "AgriculturalIPNFT: token does not exist");

        _ipMetadata[_tokenId].licensedAcres = _newAcreage;

        emit LicensedAcresUpdated(_tokenId, _newAcreage);
    }

    /**
     * @notice Marks a token as fractionalized and records the fractionalizer contract
     * @param _tokenId Token ID
     * @param _fractionalizer Address of the fractionalizer contract
     */
    function setFractionalized(
        uint256 _tokenId,
        address _fractionalizer
    )
        external
        onlyRole(MINTER_ROLE)
    {
        require(ownerOf(_tokenId) != address(0), "AgriculturalIPNFT: token does not exist");
        require(_fractionalizer != address(0), "AgriculturalIPNFT: fractionalizer is zero address");
        require(!_isFramentalized[_tokenId], "AgriculturalIPNFT: already fractionalized");

        _isFramentalized[_tokenId] = true;
        _fractionalizers[_tokenId] = _fractionalizer;

        emit IPNFTFractionalized(_tokenId, _fractionalizer, ownerOf(_tokenId));
    }

    /**
     * @notice Updates royalty information for a token
     * @param _tokenId Token ID
     * @param _receiver New royalty receiver
     * @param _feeNumerator New royalty fee in basis points
     */
    function updateRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(ownerOf(_tokenId) != address(0), "AgriculturalIPNFT: token does not exist");
        require(_receiver != address(0), "AgriculturalIPNFT: receiver is zero address");
        require(_feeNumerator <= MAX_ROYALTY_BPS, "AgriculturalIPNFT: royalty too high");

        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);

        emit RoyaltyUpdated(_tokenId, _receiver, _feeNumerator);
    }

    /**
     * @notice Returns the metadata for a token
     * @param _tokenId Token ID
     * @return IPMetadata struct containing all metadata
     */
    function getIPMetadata(uint256 _tokenId) external view returns (IPMetadata memory) {
        require(ownerOf(_tokenId) != address(0), "AgriculturalIPNFT: token does not exist");
        return _ipMetadata[_tokenId];
    }

    /**
     * @notice Returns the fractionalizer contract address for a token
     * @param _tokenId Token ID
     * @return Address of the fractionalizer contract
     */
    function getFractionalizer(uint256 _tokenId) external view returns (address) {
        require(ownerOf(_tokenId) != address(0), "AgriculturalIPNFT: token does not exist");
        return _fractionalizers[_tokenId];
    }

    /**
     * @notice Checks if a token has been fractionalized
     * @param _tokenId Token ID
     * @return Boolean indicating fractionalization status
     */
    function isFramentalized(uint256 _tokenId) external view returns (bool) {
        require(ownerOf(_tokenId) != address(0), "AgriculturalIPNFT: token does not exist");
        return _isFramentalized[_tokenId];
    }

    /**
     * @notice Returns the total number of tokens minted
     * @return Total supply of tokens
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @notice Pauses all token transfers
     * @dev Can only be called by admin
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses all token transfers
     * @dev Can only be called by admin
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Sets the base URI for token metadata
     * @param _newBaseURI New base URI
     */
    function setBaseURI(string memory _newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Returns the base URI
     * @return Base URI string
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Hook that is called on token updates (transfer, mint, burn)
     * @dev Implements pause functionality
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        override
        whenNotPaused
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    /**
     * @notice Authorizes contract upgrades
     * @dev Can only be called by upgrader role
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    /**
     * @notice Returns true if this contract implements the interface defined by interfaceId
     * @param interfaceId Interface identifier
     * @return Boolean indicating interface support
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC2981Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
