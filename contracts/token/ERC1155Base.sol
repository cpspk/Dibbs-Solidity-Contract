pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ERC1155Metadata_URI.sol";
import "./HasContractURI.sol";

abstract contract ERC1155Base is
    ERC1155Metadata_URI,
    HasContractURI,
    ERC1155,
    Ownable
{
    using SafeMath for uint256;

    // tokenId => creator
    mapping (uint256 => address) public creators;

    event Minted(uint256 tokenId, uint256 supply);

    constructor(
        string memory contractURI,
        string memory tokenURIPrefix,
        string memory uri
    ) HasContractURI(contractURI) ERC1155Metadata_URI(tokenURIPrefix) ERC1155(_uri) {
        
    }

    function _mint(
        uint256 _tokenId,
        uint256 _supply,
        string memory _uri
    ) internal {
        require(creators[_tokenId] == address(0), "ERC1155Base: already minted");
        require(_supply != 0, "ERC1155Base: invalid number of supply");
        require(bytes(_uri).length > 0, "ERC1155Base: invalid uri string");

        creators[_tokenId] = _msgSender();

        _mint(_msgSender(), _tokenId, _supply, "");
        _setTokenURI(_tokenId, _uri);

        emit Minted(_tokenId, _supply);

        emit TransferSingle(_msgSender(), address(0), _msgSender(), _tokenId, _supply);
        emit URI(_uri, _tokenId);
    }

    function burn(
        address owner,
        uint256 _tokenId,
        uint256 _value
    ) external {
        require(_owner == _msgSender() || isApprovedForAll(_owner, _msgSender()) == true,
        "ERC1155Base: need operator approval for 3rd party burns.");

        _burn(_owner, _tokenId, _value);
    }

    function _setToeknURI(uint256 _tokenId, string memory _uri) override virtual internal {
        require(creators[_tokenId] != address(0), "ERC1155Base: token should exist to set token uri");
        super._setToeknURI(_tokenId, _uri);
    }

    function setTokenURIPrefix(string memory _tokenURIPrefix) public onlyOwner {
        _setTokenURIPrefix(_tokenId, _uri);
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        _setContractURI(_contractURI);
    }

    function uri(uint256 _tokenId) override(ERC1155Metadata_URI. ERC1155) public view virtual returns (string memory)  {
        return _tokenURI(_tokenId);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC165Storage, IERC165, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }
}
