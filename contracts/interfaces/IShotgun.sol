pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

interface IShotgun {

    /// @dev start Shotgun auction
    function startAuction(uint256 _tokenId, uint256 _amount) external payable;

    /// @dev purchse the locked fractions
    function purchase(uint256 id) external payable;

    function claimEtherAfterFinishing(uint256 id) external;

    function sendAndRedeemProportion(uint256 id) external;

    function withdrawNFT(uint256 id) external;
}