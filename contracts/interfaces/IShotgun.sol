pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

interface IShotgun {
    // /**
    //  * @dev register other fraction owners
    //  * @param _otherOwner array of other owners' address
    //  * @param _tokenId token if for auction
    //  */
    // function registerOwnersWithTokenId(
    //     address _otherOwner,
    //     uint256 _tokenId
    // ) external;

    /**
     * @dev transfer amount of fractions as a participant
     * @param _amount amount of fractions
     */
    function registerFractionOwner(
        uint256 _amount
    ) external;

    /**
     * @dev transfer amount of fractions to start the auction
     * @param _amount amount of fractions
     */
    function registerShotgunStarter(
        uint256 _amount
    ) external payable;

    /// @dev start Shotgun auction
    function startAuction() external;

    /// @dev purchse the locked fractions
    function purchase() external payable;

    /// @dev claim proportional amount of total price
    function claimProportion(uint256 _tokenId) external;

    /// @dev initialize after endin Shotgun auction
    function initialize() external;

    /// @dev set new token id    
    function setTokenId(uint256 newTokenId) external;

    /**
    * @dev send / withdraw _amount to _receiver
    * @param _receiver address of recepient
    * @param _amount amount of ether to withdraw
    */
    function withdrawTo(address _receiver, uint256 _amount) external;

    /**
     * @dev change master minter
     * @param newAdmin address of new minter
     */
    function changeDibbsAdmin(address newAdmin) external;
}