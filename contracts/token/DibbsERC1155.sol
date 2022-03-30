pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol"; 
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ERC1155Metadata_URI.sol";
import "../interfaces/IDibbsERC1155.sol";
import "../interfaces/IDibbsERC721Upgradeable.sol";

contract DibbsERC1155 is
    IDibbsERC1155,
    ERC1155Metadata_URI,
    ERC1155,
    IERC1155Receiver,
    ReentrancyGuard,
    Ownable
{
    using SafeMath for uint256;

    ///@dev Fraction amount
    uint256 public constant FRACTION_AMOUNT = 10000000000000000;

    ///@dev IDibbsERC721Upgradeable instance
    IDibbsERC721Upgradeable public dibbsERC721Upgradeable;

    bytes constant EMPTY = "";

    ///@dev owner => token id => balance
    mapping(address => mapping(uint256 => uint256)) internal ownerBalace;

    ///@dev defractionalier => token type id => bool
    mapping(address => mapping(uint256 => bool)) internal isDefractionalizer;

    ///@dev events
    event Fractionalized(address to, uint256 tokenId);

    event Defractionalized(address to, uint256 tokenId);

    event DefractionalizedNFTWithdrawn(address to, uint256 tokenId);

    event FractionsTransferred(address from, address to, uint256 id, uint256 amount);

    event FractionsBurnt(uint256 id);

    constructor(
        IDibbsERC721Upgradeable _dibbsERC721Upgradeable,
        string memory _uri
    ) ERC1155Metadata_URI(_uri) ERC1155(_uri) {
        dibbsERC721Upgradeable = _dibbsERC721Upgradeable;
    }

    /**
     * @dev set new upgradeable contract address
     * @param newAddr new upgradeable contract address
     */
    function setContractAddress(address newAddr) external override onlyOwner {
        dibbsERC721Upgradeable = IDibbsERC721Upgradeable(newAddr);
    }

    /**
     * @dev add amount balace of a owner
     * @param to owner address
     * @param tokenId token id
     * @param amount to be added
     */
    function addFractions(address to, uint256 tokenId, uint256 amount) public override {
        ownerBalace[to][tokenId] = ownerBalace[to][tokenId].add(amount);
    }
    
    /**
     * @dev subtract amount balace of a owner
     * @param to owner address
     * @param tokenId token id
     * @param amount to be subtracted
     */
    function subFractions(address to, uint256 tokenId, uint256 amount) public override {
        ownerBalace[to][tokenId] = ownerBalace[to][tokenId].sub(amount);
    }

    /**
     * @dev fractionalize to a certain user
     * @param to owner address
     * @param _tokenId token id
     */
    function fractionalize(
        address to,
        uint256 _tokenId
    ) external override onlyOwner {
        require(to != address(0), "DibbsERC1155: invalid to address");
        require(!dibbsERC721Upgradeable.getFractionStatus(_tokenId), "DibbsERC1155: this token is already fractionalized");
        require(dibbsERC721Upgradeable.isTokenLocked(_tokenId), "DibbsERC1155: this token is not locked in contract");

        dibbsERC721Upgradeable.setCardFractionalized(_tokenId);

        _mint(to, _tokenId, FRACTION_AMOUNT, "");
        _setTokenURI(_tokenId);

        ownerBalace[to][_tokenId] = FRACTION_AMOUNT;

        emit Fractionalized(to, _tokenId);
    }

    /**
     * @notice defractionalize fractions
     * @dev if a user has 1.0 tokens, he/she can defractionalize them. If all the fractions are sent, it will be burnt and contract sends a NFT related to the fractions.
     * @param _tokenId token type id
     */
    function defractionalize(uint256 _tokenId) external override {
        require(balanceOf(msg.sender, _tokenId) == FRACTION_AMOUNT, "DibbsERC1155: insufficient fraction balance");

        isDefractionalizer[msg.sender][_tokenId] = true;
        
        safeTransferFrom(msg.sender, address(this), _tokenId, FRACTION_AMOUNT, '');
        require(balanceOf(msg.sender, _tokenId) == 0, "DibbsERC1155: transferring fractions didn't work properly.");

        ownerBalace[msg.sender][_tokenId] = 0;

        burnFractions(_tokenId);

        emit Defractionalized(msg.sender, _tokenId);
    }

    /**
     * @dev withdraw the NFT after defractionalzing.
     * @param _tokenId defractionalized token id.
     */
    function withdrawNFTAfterDefractionalizing(uint256 _tokenId) external override {
        require(
            isDefractionalizer[msg.sender][_tokenId],
            "DibbsERC1155: caller is not defractionalizer or tokend id is not the defractionalized one's."
        );
        isDefractionalizer[msg.sender][_tokenId] = false;

        dibbsERC721Upgradeable.safeTransferFrom(address(this), msg.sender, _tokenId);
        dibbsERC721Upgradeable.setNewTokenOwner(msg.sender, _tokenId);

        emit DefractionalizedNFTWithdrawn(msg.sender, _tokenId);
    }

    /**
     * @dev transfer fractions to a certain address
     * @param to owner address
     * @param _tokenId token id
     * @param _amount fraction amount
     */
    function transferFractions(
        address to,
        uint256 _tokenId,
        uint256 _amount
    ) external nonReentrant override {
        require(
           balanceOf(msg.sender, _tokenId) >= _amount,
            "DibbsERC1155: caller doesn't have the amount of tokens"
        );
        uint256 balanceBefore = balanceOf(msg.sender, _tokenId);
        safeTransferFrom(msg.sender, to, _tokenId, _amount, EMPTY);
        uint256 balanceafter = balanceOf(msg.sender, _tokenId);

        require(balanceBefore -  balanceafter == _amount,
            "DibbsERC1155: transferring fractions didn't work properly."
        );

        subFractions(msg.sender, _tokenId, _amount);
        addFractions(to, _tokenId, _amount);

        emit FractionsTransferred(
            msg.sender,
            to,
            _tokenId,
            _amount
        );
    }

    /**
     * @dev burn a token
     * @param _tokenId a token type id
     */
    function burnFractions(
        uint256 _tokenId
    ) public override {
        require(balanceOf(address(this), _tokenId) == FRACTION_AMOUNT,
        "DibbsERC1155: the contract doesn't have enoungh amount of fractions");

        _burn(address(this), _tokenId, FRACTION_AMOUNT);
        emit FractionsBurnt(_tokenId);
    }

    function _setTokenURI(uint256 _tokenId) override virtual internal {
        super._setTokenURI(_tokenId);
    }

    function setTokenURIPrefix(string memory _tokenURIPrefix) public onlyOwner {
        _setTokenURIPrefix(_tokenURIPrefix);
    }

    function uri(uint256 _tokenId) override(ERC1155Metadata_URI, ERC1155) public view virtual returns (string memory)  {
        return _tokenURI(_tokenId);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
