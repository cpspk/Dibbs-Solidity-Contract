pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

import "./ERC1155Base.sol";

contract DibbsERC1155 is ERC1155Base {

    string public name;
    string public symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        string memory _tokenURIPrefix,
        string memory _uri
    ) ERC1155Base(_contractURI, _tokenURIPrefix, _uri) {
        name = _name;
        symbol = _symbol;
    }

    function fractionalize(
        address owner,
        uint256 _tokenId,
        uint256 _supply,
        string memory _uri
    ) external {
        _mint(owner, _tokenId, _supply, _uri);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155Base) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
}
