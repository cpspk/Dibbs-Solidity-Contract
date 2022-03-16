// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "../interfaces/IDibbsERC721Upgradeable.sol";
import "../interfaces/IDibbsERC1155.sol";

contract TransferProxy {
    function erc721safeTransferFrom(
        IDibbsERC721Upgradeable token,
        address from,
        address to,
        uint tokenId
    ) external {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(
        IDibbsERC1155 token,
        address _from,
        address _to,
        uint _id,
        uint _value,
        bytes calldata _data
    ) external {
        token.safeTransferFrom(_from, _to, _id, _value, _data);
    }
}
