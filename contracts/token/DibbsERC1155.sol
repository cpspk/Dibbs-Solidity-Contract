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

    ///@dev IDibbsERC721Upgradeable instance
    IDibbsERC721Upgradeable dibbsERC721Upgradeable;

    event Fractionalized(address to, uint256 tokenId);

    constructor(
        IDibbsERC721Upgradeable _dibbsERC721Upgradeable,
        string memory _uri
    ) ERC1155Metadata_URI(_uri) ERC1155(_uri) {
        dibbsERC721Upgradeable = _dibbsERC721Upgradeable;
    }

    function fractionalize(
        address to,
        uint256 _tokenId
    ) external override {
        require(to != address(0), "DibbsERC1155: invalid to address");
        require(!dibbsERC721Upgradeable.getFractionStatus(_tokenId), "DibbsERC1155: this token is already fractionalized");
        //TODO only contract owned tokens can be fractionalized
        dibbsERC721Upgradeable.setCardFractionalized(_tokenId);

        _mint(to, _tokenId, fractionAmount, "");
        _setTokenURI(_tokenId);

        emit Fractionalized(to, _tokenId);
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
