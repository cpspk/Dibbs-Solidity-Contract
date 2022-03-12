// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {

  string public baseTokenURI;

  constructor() ERC721("MockNFT", "MockNFT") {
    setBaseURI("http://mock/");
  }

  function mint(address to, uint256 tokenId) external {
    _safeMint(to, tokenId);
  }

  /**
     * @dev Get `baseTokenURI`
     * Overrided
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Set `baseTokenURI`
     * Only `owner` can call
     */
    function setBaseURI(string memory baseURI) internal {
        baseTokenURI = baseURI;
    }
}