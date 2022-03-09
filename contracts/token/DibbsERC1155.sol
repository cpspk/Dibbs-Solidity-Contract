pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ERC1155Metadata_URI.sol";
import "./HasContractURI.sol";
import "../interfaces/IDibbsERC1155.sol";

contract DibbsERC1155 is
    IDibbsERC1155,
    ERC1155Metadata_URI,
    HasContractURI,
    ERC1155,
    Ownable
{
    string public name;
    string public symbol;

    using SafeMath for uint256;

    // tokenId => creator
    mapping (uint256 => address) public creators;

    event Fractionalized(address owner, uint256 tokenId, uint256 supply);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory contractURI,
        string memory tokenURIPrefix,
        string memory _uri
    ) HasContractURI(contractURI) ERC1155Metadata_URI(tokenURIPrefix) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
    }

    function fractionalize(
        address owner,
        uint256 _tokenId,
        uint256 _supply,
        string memory _uri
    ) external override {
        require(owner != address(0), "DibbsERC1155: invalid owner address");
        require(creators[_tokenId] == address(0), "DibbsERC1155: already minted");
        require(_supply != 0, "DibbsERC1155: invalid number of supply");
        require(bytes(_uri).length > 0, "DibbsERC1155: invalid uri string");

        creators[_tokenId] = _msgSender();

        _mint(owner, _tokenId, _supply, "");
        _setTokenURI(_tokenId, _uri);

        emit Fractionalized(owner, _tokenId, _supply);

        emit TransferSingle(_msgSender(), address(0), owner, _tokenId, _supply);
        emit URI(_uri, _tokenId);
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

    function _setTokenURI(uint256 _tokenId, string memory _uri) override virtual internal {
        require(creators[_tokenId] != address(0), "DibbsERC1155: token should exist to set token uri");
        super._setTokenURI(_tokenId, _uri);
    }

    function setTokenURIPrefix(string memory _tokenURIPrefix) public onlyOwner {
        _setTokenURIPrefix(_tokenURIPrefix);
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        _setContractURI(_contractURI);
    }

    function uri(uint256 _tokenId) override(ERC1155Metadata_URI, ERC1155) public view virtual returns (string memory)  {
        return _tokenURI(_tokenId);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC165Storage, IERC165)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }
}
