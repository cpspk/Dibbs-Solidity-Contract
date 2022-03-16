// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IDibbsERC1155 is IERC1155 {
    /**
     * @dev fractionalize to a certain user
     * @param owner owner address
     * @param _tokenId token id
     */
    function fractionalizeToUser(
        address owner,
        uint256 _tokenId
    ) external;

    /**
     * @dev fractionalize to dibbs
     * @param _tokenId token id
     */
    function fractionalizeToDibbs(
        uint256 _tokenId
    ) external payable;

    /**
     * @dev burn a token
     * @param _owner owner address
     * @param _tokenId a token type id
     * @param _amount amount tokens
     */
    function burn(
        address _owner,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @dev add amount balace of a owner
     * @param to owner address
     * @param tokenId token id
     * @param amount to be added
     */
    function addFractions(address to, uint256 tokenId, uint256 amount) external ;

    /**
     * @dev subtract amount balace of a owner
     * @param to owner address
     * @param tokenId token id
     * @param amount to be subtracted
     */
    function subFractions(address to, uint256 tokenId, uint256 amount) external ;

    /**
     * @dev get a current balance of an owner
     * @param to owner address
     * @param tokenId token id
     */
    function getFractions(address to, uint256 tokenId) external returns (uint256);

    /**
     * @dev get price corresponding to the amount
     * @param tokenId token id
     * @param amount amount
     */
    function getPrice(uint256 tokenId, uint256 amount) external returns (uint256);

    /**
     * @dev delete a mapping data of owner
     * @param to owner address
     * @param tokenId token id
     */
    function deleteOwnerFraction(address to, uint256 tokenId) external;

}
