pragma solidity ^0.8.4;

interface ICardToken {
    function mint(address to, string memory name, string memory grade, uint256 serial) external payable;

    function purchase(uint256 tokenId) external payable;
    
    function sell(uint256 tokenId) external payable;
}