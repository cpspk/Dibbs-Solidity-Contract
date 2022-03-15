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

    address public constant tokenVaultAddr = 0xAD143E30AD4852c97716ED5b32d45BcCfF7DEa36;


    ///@dev IDibbsERC721Upgradeable instance
    IDibbsERC721Upgradeable dibbsERC721Upgradeable;

    ///@dev tokenId => owner => balance
    mapping(uint256 => mapping(address => uint256)) ownerBalace;

    event Fractionalized(address to, uint256 tokenId);

    constructor(
        IDibbsERC721Upgradeable _dibbsERC721Upgradeable,
        string memory _uri
    ) ERC1155Metadata_URI(_uri) ERC1155(_uri) {
        dibbsERC721Upgradeable = _dibbsERC721Upgradeable;
    }

    function addFractions(address to, uint256 tokenId, uint256 amount) external override {
        ownerBalace[tokenId][to] += amount;
    }

    function subFractions(address to, uint256 tokenId, uint256 amount) external override {
        ownerBalace[tokenId][to] -= amount;
    }

    function deleteOwnerFraction(address to, uint256 tokenId) external override {
        delete ownerBalace[tokenId][to];
    }

    function getFractions(address to, uint256 tokenId) external view override returns (uint256) {
        return ownerBalace[tokenId][to];
    }

    function getPrice(uint256 tokenId, uint256 amount) external override returns (uint256) {
        uint256 tokenPrice = dibbsERC721Upgradeable.getCardPrice(tokenId);
        return amount/fractionAmount * tokenPrice;
    }

    function fractionalizeToUser(
        address to,
        uint256 _tokenId
    ) external override {
        require(to != address(0), "DibbsERC1155: invalid to address");
        require(!dibbsERC721Upgradeable.getFractionStatus(_tokenId), "DibbsERC1155: this token is already fractionalized");
        //TODO only contract owned tokens can be fractionalized
        dibbsERC721Upgradeable.setCardFractionalized(_tokenId);

        _mint(to, _tokenId, fractionAmount, "");
        _setTokenURI(_tokenId);

        ownerBalace[_tokenId][to] = fractionAmount;

        emit Fractionalized(to, _tokenId);
    }

    function fractionalizeToDibbs(
        uint256 _tokenId
    ) external {
        require(!dibbsERC721Upgradeable.getFractionStatus(_tokenId), "DibbsERC1155: this token is already fractionalized");
        dibbsERC721Upgradeable.setCardFractionalized(_tokenId);

        _mint(tokenVaultAddr, _tokenId, fractionAmount, "");
        _setTokenURI(_tokenId);

        ownerBalace[_tokenId][tokenVaultAddr] = fractionAmount;

        emit Fractionalized(tokenVaultAddr, _tokenId);
    }

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
