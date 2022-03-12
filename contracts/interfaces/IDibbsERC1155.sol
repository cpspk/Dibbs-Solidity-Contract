// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDibbsERC1155 {

    function fractionalize(
        address owner,
        uint256 _tokenId
    ) external;

    function burn(
        address _owner,
        uint256 _tokenId,
        uint256 _value
    ) external;

}
