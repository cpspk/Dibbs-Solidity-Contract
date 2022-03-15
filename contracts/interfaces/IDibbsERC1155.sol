// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IDibbsERC1155 is IERC1155 {

    function fractionalizeToUser(
        address owner,
        uint256 _tokenId
    ) external;

    function burn(
        address _owner,
        uint256 _tokenId,
        uint256 _value
    ) external;

    function addFractions(address to, uint256 tokenId, uint256 amount) external ;

    function subFractions(address to, uint256 tokenId, uint256 amount) external ;

    function getFractions(address to, uint256 tokenId) external returns (uint256);

    function getPrice(uint256 tokenId, uint256 amount) external returns (uint256);

    function deleteOwnerFraction(address to, uint256 tokenId) external;

}
