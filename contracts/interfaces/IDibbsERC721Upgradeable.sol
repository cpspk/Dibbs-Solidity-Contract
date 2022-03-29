// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IDibbsERC721Upgradeable is IERC721Upgradeable {
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
     * @param _tokenId token id
     */
    function transferToken(
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
