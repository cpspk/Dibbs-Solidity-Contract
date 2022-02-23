//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ICardToken {

    /**
     * @dev mint card token to contract
     * @param to receipent address
     * @param name card token name
     * @param grade card token grade
     * @param serial card token serial
     */
    function mint(
        address to,
        string memory name,
        string memory grade,
        uint256 serial
    ) external payable;

    function purchase(uint256 tokenId) external;
    
    function sell(uint256 tokenId) external;
}