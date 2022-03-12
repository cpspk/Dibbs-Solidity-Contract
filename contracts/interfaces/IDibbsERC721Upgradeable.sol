// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IDibbsERC721Upgradeable is IERC721Upgradeable {

    function cards(uint256 id) external returns (
        address,
        string calldata,
        string calldata,
        uint256,
        bool,
        uint256
    );

    function setCardFractionalized(uint256 id) external;

    function getFractionStatus(uint256 id) external returns (bool);

    /**
     * @dev mint card token to a recepient~
     * @param owner receipent address
     * @param name card token name
     * @param grade card token grade
     * @param serial card token serial id (Psa indentifier)
     */
    function mint(
        address owner,
        string calldata name,
        string calldata grade,
        uint256 serial
    ) external;

    // /**
    //  * @dev register existing token
    //  * @param tokenId old token id
    //  * @param name card token name
    //  * @param grade card token grade
    //  * @param serial card token serial id (Psa indentifier)
    //  */
    // function register(
    //     uint256 tokenId,
    //     string calldata name,
    //     string calldata grade,
    //     uint256 serial
    // ) external;

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
