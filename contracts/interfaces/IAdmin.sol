//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IAdmin {

    /**
     * @dev mint card token to contract
     * @param owner receipent address
     * @param name card token name
     * @param grade card token grade
     * @param serial card token serial
     */
    function mintAndFractionalize(
        address owner,
        string calldata name,
        string calldata grade,
        uint256 serial
    ) external;

    function changeMasterMinter(address newMinter) external;
}