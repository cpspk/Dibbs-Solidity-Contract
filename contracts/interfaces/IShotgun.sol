// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IShotgun {
    /**
     * @dev register other fraction owners
     * @param _otherOwners array of other owners' address
     * @param _tokenId token if for auction
     */
    function registerOwnersWithTokenId(
        address[] calldata _otherOwners,
        uint256 _tokenId
    ) external;

    /**
     * @dev transfer amount of fractions to start the auction
     * @param _amount amount of fractions
     */
    function transferForShotgun(
        uint256 _amount
    ) external payable;

    /// @dev start Shotgun auction
    function startAuction() external;

    /// @dev purchse the locked fractions
    function purchase() external payable;

    /// @dev claim proportional amount of total price
    function claimProportion() external;

    /// @dev initialize after endin Shotgun auction
    function initialize() external;

    /**
    * @dev send / withdraw _amount to _receiver
    * @param _receiver address of recepient
    * @param _amount amount of ether to withdraw
    */
    function withdrawTo(address _receiver, uint256 _amount) external;
}