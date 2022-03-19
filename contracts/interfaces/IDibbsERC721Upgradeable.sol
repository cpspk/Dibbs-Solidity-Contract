// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IDibbsERC721Upgradeable is IERC721Upgradeable {
    ///@dev struct card
    function cards(uint256 id) external returns (
        address,
        string calldata,
        string calldata,
        string calldata,
        bool
    );

    /**
     * @dev set card token struct when new token is minted
     * @param owner current token owner
     * @param name card token name
     * @param grade card token grade
     * @param serial card token serial id (Psa indentifier)
     * @param id card token id
     */
    function setCard(address owner, string calldata name, string calldata grade, string calldata serial, uint256 id) external;

    /**
     * @dev (To be called externally) setter function: set true when card is fractionalized
     * @param id the token id
     */
    function setCardFractionalized(uint256 id) external;

    ///@dev get (true or false) whether a token with id exists or not.
    // function getExistence(uint256 id) external returns (bool);

    ///@dev get (true or false) whether a token with id fractionalized or not.
    function getFractionStatus(uint256 id) external returns (bool);

    function setNewTokenOwner(address newowner, uint256 id) external;

    function getTokenOwner(uint256 id) external returns (address);

    function isTokenLocked(uint256 id) external view returns (bool);

    /**
     * @dev mint card token to a recepient without payment
     * @param _tokenURI token uri for a NFT
     * @param _to recepient address
     * @param _name card token name
     * @param _grade card token grade
     * @param _serial card token serial id (Psa indentifier)
     */
    function mint(
        string calldata _tokenURI,
        address _to,
        string calldata _name,
        string calldata _grade,
        string calldata _serial
    ) external;

    /**
     * @dev transfer token
     * @param _to recepient address
     * @param _tokenId token id
     */
    function transferToken(
        address _to,
        uint256 _tokenId
    ) external;

    /**
     * @dev burn nft: delete card info corresponding to tokenId
     * @param tokenId burned id
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev change master minter
     * @param newAdmin address of new minter
     */
    function changeDibbsAdmin(address newAdmin) external;
}
