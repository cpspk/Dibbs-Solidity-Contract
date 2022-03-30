// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IDibbsERC1155 is IERC1155 {
    /**
     * @dev fractionalize to a certain user
     * @param owner owner address
     * @param _tokenId token id
     */
    function fractionalize(
        address owner,
        uint256 _tokenId
    ) external;

     /**
     * @notice defractionalize fractions
     * @dev if a user has 1.0 tokens, he/she can defractionalize them. If all the fractions are sent, it will be burnt and contract sends a NFT related to the fractions.
     * @param _tokenId token type id
     */
    function defractionalize(uint256 _tokenId) external;

    /**
     * @dev withdraw the NFT after defractionalzing.
     * @param _tokenId defractionalized token id.
     */
    function withdrawNFTAfterDefractionalizing(uint256 _tokenId) external;

    /**
     * @dev transfer fractions to a certain address
     * @param to owner address
     * @param _tokenId token id
     * @param _amount fraction amount
     */
    function transferFractions(
        address to,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @dev burn a token
     * @param _tokenId a token type id
     */
    function burnFractions(
        uint256 _tokenId
    ) external;

    /**
     * @dev set new upgradeable contract address
     * @param newAddr new upgradeable contract address
     */
    function setContractAddress(address newAddr) external;

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

}
