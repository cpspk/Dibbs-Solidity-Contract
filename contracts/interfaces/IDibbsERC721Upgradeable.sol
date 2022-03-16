// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IDibbsERC721Upgradeable is IERC721Upgradeable {
    ///@dev struct card
    function cards(uint256 id) external returns (
        address,
        string calldata,
        string calldata,
        uint256,
        uint256,
        bool
    );

    /**
     * @dev set card token struct when new token is minted
     * @param owner current token owner
     * @param name card token name
     * @param grade card token grade
     * @param serial card token serial id (Psa indentifier)
     * @param price cardtoken price
     * @param id card token id
     */
    function setCard(address owner, string calldata name, string calldata grade, uint256 serial, uint256 price, uint256 id) external;

    /**
     * @dev (To be called externally) setter function: set true when card is fractionalized
     * @param id the token id
     */
    function setCardFractionalized(uint256 id) external;

    ///@dev get (true or false) whether a token with id exists or not.
    function getExistence(uint256 id) external returns (bool);

    ///@dev get (true or false) whether a token with id fractionalized or not.
    function getFractionStatus(uint256 id) external returns (bool);

    ///@dev get price of a token with id
    function getCardPrice(uint256 id) external returns (uint256);

    function setNewTokenOwner(address newowner, uint256 id) external;

    function getTokenOwner(uint256 id) external returns (address);

    /**
     * @dev mint card token to a recepient
     * @param name card token name
     * @param grade card token grade
     * @param serial card token serial id (Psa indentifier)
     * @param price card token price
     */
    function mintToDibbs(
        string calldata name,
        string calldata grade,
        uint256 serial,
        uint256 price
    ) external;

    /**
     * @dev mint card token to a recepient
     * @param name card token name
     * @param grade card token grade
     * @param serial card token serial id (Psa indentifier)
     * @param price card token price
     */
    function mintToDibbsPayable(
        string calldata name,
        string calldata grade,
        uint256 serial,
        uint256 price
    ) external payable;

    /**
     * @dev burn nft: delete card info corresponding to tokenId
     * @param tokenId burned id
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev change master minter
     * @param newMinter address of new minter
     */
    function changeMasterMinter(address newMinter) external;
}
