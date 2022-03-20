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
    uint256 public constant fractionAmount = 10000000000000000;
    
    ///@dev dibbs vault address (Currently using Metamask address)
    // address public constant _msgSender() = 0xAD143E30AD4852c97716ED5b32d45BcCfF7DEa36;

    ///@dev IDibbsERC721Upgradeable instance
    IDibbsERC721Upgradeable public dibbsERC721Upgradeable;

    bytes constant EMPTY = "";

    ///@dev tokenId => owner => balance
    mapping(uint256 => mapping(address => uint256)) ownerBalace;

    ///@dev event
    event Fractionalized(address to, uint256 tokenId);

    event FractionsTransferred(address from, address to, uint256 id, uint256 amount);

    event Burnt(uint256 id);

    constructor(
        IDibbsERC721Upgradeable _dibbsERC721Upgradeable,
        string memory _uri
    ) ERC1155Metadata_URI(_uri) ERC1155(_uri) {
        dibbsERC721Upgradeable = _dibbsERC721Upgradeable;
    }
    /**
     * @dev add amount balace of a owner
     * @param to owner address
     * @param tokenId token id
     * @param amount to be added
     */
    function addFractions(address to, uint256 tokenId, uint256 amount) public override {
        ownerBalace[tokenId][to] += amount;
    }
    
    /**
     * @dev subtract amount balace of a owner
     * @param to owner address
     * @param tokenId token id
     * @param amount to be subtracted
     */
    function subFractions(address to, uint256 tokenId, uint256 amount) public override {
        ownerBalace[tokenId][to] -= amount;
    }

    /**
     * @dev delete a mapping data of owner
     * @param to owner address
     * @param tokenId token id
     */
    function deleteOwnerFraction(address to, uint256 tokenId) public override {
        delete ownerBalace[tokenId][to];
    }

    /**
     * @dev get a current balance of an owner
     * @param to owner address
     * @param tokenId token id
     */
    function getFractions(address to, uint256 tokenId) public view override returns (uint256) {
        return ownerBalace[tokenId][to];
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

        _mint(to, _tokenId, fractionAmount, "");
        _setTokenURI(_tokenId);

        ownerBalace[_tokenId][to] = fractionAmount;

        emit Fractionalized(to, _tokenId);
    }

    function transferFractions(
        uint256 _tokenId,
        uint256 _amount
    ) external nonReentrant {
        require(
           balanceOf(_msgSender(), _tokenId) >= _amount,
            "DibbsERC1155: caller doesn't have the amount of tokens"
        );
        uint256 balanceBefore = balanceOf(_msgSender(), _tokenId);
        safeTransferFrom(_msgSender(), address(this), _tokenId, _amount, EMPTY);
        uint256 balanceafter = balanceOf(_msgSender(), _tokenId);

        require(balanceBefore -  balanceafter == _amount,
            "DibbsERC1155: token transfermation failed"
        );

        subFractions(_msgSender(), _tokenId, _amount);
        addFractions(address(this), _tokenId, _amount);

        if(getFractions(_msgSender(), _tokenId) == 0) {
            deleteOwnerFraction(_msgSender(), _tokenId);
        }

        emit FractionsTransferred(
            _msgSender(),
            address(this),
            _tokenId,
            _amount
        );
    }

    /**
     * @dev burn a token
     * @param _tokenId a token type id
     */
    function burn(
        uint256 _tokenId
    ) public override {
        require(balanceOf(address(this), _tokenId) == fractionAmount,
        "DibbsERC1155: the contract doesn't have enoungh amount of fractions");

        _burn(address(this), _tokenId, fractionAmount);
        emit Burnt(_tokenId);
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
