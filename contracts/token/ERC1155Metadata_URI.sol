pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

import "./HasTokenURI.sol";

abstract contract ERC1155Metadata_URI is IERC1155MetadataURI, HasTokenURI {
    
    constructor(string memory _tokenURIPrefix) HasTokenURI(_tokenURIPrefix) {

    }

    function uri(uint256 _tokenId) override virtual external view returns (string memory) {
        return _tokenURI(_tokenId);
    }
}
