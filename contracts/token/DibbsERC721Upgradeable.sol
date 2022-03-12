//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

import "../interfaces/IDibbsERC721Upgradeable.sol";

contract DibbsERC721Upgradeable is IDibbsERC721Upgradeable, ERC721Upgradeable, IERC721Receiver, OwnableUpgradeable {
    using Counters for Counters.Counter;

    ///@dev card id tracker
    Counters.Counter private _tokenIdTracker;

    ///@dev card token info
    struct Card {
        address owner;
        string name;
        string grade;
        uint256 serial;
        bool fractionalized;
        uint256 fractionBalance;
    }

    ///@dev id => card token
    mapping(uint256 => Card) public override cards;

    ///@dev Is the card token with id existed or not?
    mapping(uint256 => bool) public isCardTokenExisted;

     ///@dev baseTokenURI
    string public baseTokenURI;

    ///@dev dibbs admins
    address public masterMinter;

    ///@dev Fraction amount
    uint256 public constant fractionAmount = 10000000000000000;

    ///@dev change master minter event
    event MasterMinterChanged(address prevMinter, address newMinter);

    ///@dev mint event
    event Minted(address to, string name, string grade, uint256 serial, uint256 id);

    ///@dev register event
    event Registered(address from, address to, uint256 id);

    /**
     * @dev initialize upgraddeable contract uses initialize() instead of constructor
     * @param baseURI token base uri
     */
    function initialize(
        string memory baseURI
    ) initializer public {
        __ERC721_init("Admin", "AD");
        __Ownable_init();

        setBaseURI(baseURI);
        masterMinter = _msgSender();// only owner
    }
    /**
     * @dev check if the token id is valid or not
     * @param tokenId the token id
     */
    modifier onlyValidToken(uint256 tokenId) {
        require(_exists(tokenId), "DibbsERC721Upgradeable: invalid card token id");
        _;
    }

    function getExistence(uint256 id) external view returns (bool) {
        return isCardTokenExisted[id];
    }

    function getFractionStatus(uint256 id) external override view returns (bool) {
        return cards[id].fractionalized;
    }

    /**
     * @dev (To be called externally) setter function: set card balance as a initial amount and fractionalized true when card is fractionalized
     * @param id the token id
     */
    function setCardFractionalized(uint256 id) external override onlyValidToken(id) {
        Card storage card = cards[id];
        card.fractionalized = true;
        card.fractionBalance = fractionAmount;
    }

    function setCard(address owner, string calldata name, string calldata grade, uint256 serial, uint256 id) internal {
        cards[id] = Card(
            owner,  //will be owner of the token
            name,
            grade,
            serial,
            false,
            0
        );
    }

    /**
     * @dev mint card token to a recepient
     * @param owner receipent address: ** Even if owner is contract, owner address should be passed manually. 
     * @param name card token name
     * @param grade card token grade
     * @param serial card token serial id (Psa indentifier)
     */
    function mint(
        address owner, //TODO specify onwer, currently all tokens are minted to this contract.
        string calldata name,
        string calldata grade,
        uint256 serial
    ) external override virtual {
        require(getCurrentMinter() == _msgSender(), "DibbsERC721Upgradeable: Only dibbs can mint NFTs");
        require(owner != address(0), "DibbsERC721Upgradeable: invalid recepient address");
        require(bytes(name).length != 0, "DibbsERC721Upgradeable: invalid token name");
        require(bytes(grade).length != 0, "DibbsERC721Upgradeable: invalid token grade");
        require(serial > 0, "DibbsERC721Upgradeable: invalid serial id");
        require(isCardTokenExisted[serial] != true, "DibbsERC721Upgradeable: existing card token");
        
        isCardTokenExisted[serial] = true;

        uint256 id = _tokenIdTracker.current();
        setCard(
            owner,  //will be owner of the token
            name,
            grade,
            serial,
            id
        );

        uint256 ownerBalanceBefore = balanceOf(owner);

        _safeMint(owner, id);

        uint256 ownerBalanceAfter = balanceOf(owner);

        _tokenIdTracker.increment();

        require(
            (ownerBalanceAfter - ownerBalanceBefore) == 1,
            "DibbsERC721Upgradeable: token minting didn't work properly"
        );

        emit Minted(owner, name, grade, serial, id);
    }

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
    // ) external override {
    //     address owner = ownerOf(tokenId);
    //     require(owner == _msgSender(), "DibbsERC721Upgradeable: caller is not the owner");

    //     uint256 newTokenId = _tokenIdTracker.current();
    //     setCard(
    //         address(this),  //will be owner of the token
    //         name,
    //         grade,
    //         serial,
    //         newTokenId
    //     );

    //     _tokenIdTracker.increment();

    //     // uint256 ownerBalanceBefore = balanceOf(owner);
    //     // uint256 serverBalanceBefore = balanceOf(address(this));

    //     safeTransferFrom(owner, address(this), newTokenId);

    //     // uint256 ownerBalanceAfter = balanceOf(owner);
    //     // uint256 serverBalanceAfter = balanceOf(address(this));

    //     // require(
    //     //     (ownerBalanceAfter - ownerBalanceBefore) == 1 &&
    //     //     (serverBalanceBefore - serverBalanceAfter) == 1,
    //     //     "DibbsERC721Upgradeable: token transferring didn't work properly"
    //     // );

    //     emit Registered(owner, address(this), newTokenId);
    // }

    /**
     * @dev burn nft: delete card info corresponding to tokenId
     * @param tokenId burned id
     */
    function burn(uint256 tokenId) external override onlyOwner{
        isCardTokenExisted[cards[tokenId].serial] = false;
        delete cards[tokenId];

        _burn(tokenId);
    }

    function changeMasterMinter(address newMinter) external override virtual onlyOwner {
        require(newMinter != address(0), "DibbsERC721Upgradeable: invalid address");

        address prevMinter = masterMinter;
        masterMinter = newMinter;
        emit MasterMinterChanged(prevMinter, newMinter);
    }    

    function getCurrentMinter() internal view returns (address) {
        return masterMinter;
    }

    /**
     * @dev Get `baseTokenURI`
     * Overrided
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Set `baseTokenURI`
     * Only `owner` can call
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
