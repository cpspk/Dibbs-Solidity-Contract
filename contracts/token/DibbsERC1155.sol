pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ERC1155Metadata_URI.sol";
import "../interfaces/IDibbsERC1155.sol";
import "../interfaces/IDibbsERC721Upgradeable.sol";

contract DibbsERC1155 is
    IDibbsERC1155,
    ERC1155Metadata_URI,
    ERC1155,
    Ownable
{
    using SafeMath for uint256;

    ///@dev Fraction amount
    uint256 public constant fractionAmount = 10000000000000000;
    
    ///@dev dibbs vault address (Currently using Metamask address)
    // address public constant _msgSender() = 0xAD143E30AD4852c97716ED5b32d45BcCfF7DEa36;

    ///@dev IDibbsERC721Upgradeable instance
    IDibbsERC721Upgradeable public dibbsERC721Upgradeable;

    ///@dev tokenId => owner => balance
    mapping(uint256 => mapping(address => uint256)) ownerBalace;

    ///@dev event
    event Fractionalized(address to, uint256 tokenId);

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
    function addFractions(address to, uint256 tokenId, uint256 amount) external override {
        ownerBalace[tokenId][to] += amount;
    }
    
    /**
     * @dev subtract amount balace of a owner
     * @param to owner address
     * @param tokenId token id
     * @param amount to be subtracted
     */
    function subFractions(address to, uint256 tokenId, uint256 amount) external override {
        ownerBalace[tokenId][to] -= amount;
    }

    /**
     * @dev delete a mapping data of owner
     * @param to owner address
     * @param tokenId token id
     */
    function deleteOwnerFraction(address to, uint256 tokenId) external override {
        delete ownerBalace[tokenId][to];
    }

    /**
     * @dev get a current balance of an owner
     * @param to owner address
     * @param tokenId token id
     */
    function getFractions(address to, uint256 tokenId) external view override returns (uint256) {
        return ownerBalace[tokenId][to];
    }

    /**
     * @dev get price corresponding to the amount
     * @param tokenId token id
     * @param amount amount
     */
    function getPrice(uint256 tokenId, uint256 amount) external override returns (uint256) {
        uint256 tokenPrice = dibbsERC721Upgradeable.getCardPrice(tokenId);
        return amount.mul(tokenPrice).div(fractionAmount);
    }

    /**
     * @dev fractionalize to dibbs
     * @param _tokenId token id
     */
    function fractionalizeToDibbs(
        uint256 _tokenId
    ) external payable override onlyOwner {
        require(!dibbsERC721Upgradeable.getFractionStatus(_tokenId), "DibbsERC1155: this token is already fractionalized");
        dibbsERC721Upgradeable.setCardFractionalized(_tokenId);

        _mint(_msgSender(), _tokenId, fractionAmount, "");
        _setTokenURI(_tokenId);

        ownerBalace[_tokenId][_msgSender()] = fractionAmount;

        emit Fractionalized(_msgSender(), _tokenId);
    }

    /**
     * @dev fractionalize to a certain user
     * @param to owner address
     * @param _tokenId token id
     */
    function fractionalizeToUser(
        address to,
        uint256 _tokenId
    ) external override onlyOwner {
        require(to != address(0), "DibbsERC1155: invalid to address");
        require(!dibbsERC721Upgradeable.getFractionStatus(_tokenId), "DibbsERC1155: this token is already fractionalized");
        //TODO only contract owned tokens can be fractionalized
        dibbsERC721Upgradeable.setCardFractionalized(_tokenId);

        _mint(to, _tokenId, fractionAmount, "");
        _setTokenURI(_tokenId);

        ownerBalace[_tokenId][to] = fractionAmount;

        emit Fractionalized(to, _tokenId);
    }

    /**
     * @dev burn a token
     * @param _owner owner address
     * @param _tokenId a token type id
     * @param _amount amount tokens
     */
    function burn(
        address _owner,
        uint256 _tokenId,
        uint256 _amount
    ) external override {
        require(_owner == _msgSender() || isApprovedForAll(_owner, _msgSender()) == true,
        "DibbsERC1155: need operator approval for 3rd party burns.");

        _burn(_owner, _tokenId, _amount);
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
}
