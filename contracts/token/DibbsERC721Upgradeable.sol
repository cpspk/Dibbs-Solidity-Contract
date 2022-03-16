//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

import "../interfaces/IDibbsERC721Upgradeable.sol";

contract DibbsERC721Upgradeable is IDibbsERC721Upgradeable, ERC721Upgradeable, OwnableUpgradeable {
    using Counters for Counters.Counter;

    ///@dev card id tracker
    Counters.Counter private _tokenIdTracker;

    ///@dev dibbs vault address (Currently using Metamask address)
    // address public constant tokenVaultOwner = 0xAD143E30AD4852c97716ED5b32d45BcCfF7DEa36;

    ///@dev card token info
    struct Card {
        address owner;
        string name;
        string grade;
        uint256 serial;
        uint256 price;
        bool fractionalized;
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
    event Minted(string name, string grade, uint256 serial, uint256 id);

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

    ///@dev get (true or false) whether a token with id exists or not.
    function getExistence(uint256 id) external override view onlyValidToken(id) returns (bool) {
        return isCardTokenExisted[id];
    }

    ///@dev get (true or false) whether a token with id fractionalized or not.
    function getFractionStatus(uint256 id) external override view onlyValidToken(id) returns (bool) {
        return cards[id].fractionalized;
    }

    ///@dev get price of a token with id
    function getCardPrice(uint256 id) external override view onlyValidToken(id) returns (uint256) {
        return cards[id].price;
    }

    /**
     * @dev (To be called externally) setter function: set true when card is fractionalized
     * @param id the token id
     */
    function setCardFractionalized(uint256 id) external override onlyValidToken(id) {
        cards[id].fractionalized = true;
    }

    function setNewTokenOwner(address newowner, uint256 id) external override onlyValidToken(id) {
        cards[id].owner = newowner;
    }

    function getTokenOwner(uint256 id) external view override onlyValidToken(id) returns (address) {
        return cards[id].owner;
    }

    /**
     * @dev set card token struct when new token is minted
     * @param owner current token owner
     * @param name card token name
     * @param grade card token grade
     * @param serial card token serial id (Psa indentifier)
     * @param price cardtoken price
     * @param id card token id
     */
    function setCard(address owner, string calldata name, string calldata grade, uint256 serial, uint256 price, uint256 id) public override {

        isCardTokenExisted[serial] = true;
        cards[id] = Card(
            owner,
            name,
            grade,
            serial,
            price,
            false //fractionalized
        );
    }

    /**
     * @dev mint card token to a recepient without payment
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
    ) external override virtual {
        require(getCurrentMinter() == _msgSender(), "DibbsERC721Upgradeable: Only dibbs can mint NFTs");
        require(bytes(name).length != 0, "DibbsERC721Upgradeable: invalid token name");
        require(bytes(grade).length != 0, "DibbsERC721Upgradeable: invalid token grade");
        require(serial > 0, "DibbsERC721Upgradeable: invalid serial id");
        require(price > 0, "DibbsERC721Upgradeable: invalid token price");
        require(isCardTokenExisted[serial] != true, "DibbsERC721Upgradeable: existing card token");

        isCardTokenExisted[serial] = true;

        uint256 id = totalSupply();
        cards[id] = Card(
            masterMinter,
            name,
            grade,
            serial,
            price,
            false
        );

        uint256 ownerBalanceBefore = balanceOf(_msgSender());

        _safeMint(_msgSender(), id);

        uint256 ownerBalanceAfter = balanceOf(_msgSender());

        _tokenIdTracker.increment();

        require(
            (ownerBalanceAfter - ownerBalanceBefore) == 1,
            "DibbsERC721Upgradeable: token minting didn't work properly"
        );

        emit Minted(name, grade, serial, id);
    }

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
    ) external payable override {
        require(_msgSender() != getCurrentMinter(), "DibbsERC721Upgradeable: Dibbs shouldn't call payalble mint function");
        require(bytes(name).length != 0, "DibbsERC721Upgradeable: invalid token name");
        require(bytes(grade).length != 0, "DibbsERC721Upgradeable: invalid token grade");
        require(serial > 0, "DibbsERC721Upgradeable: invalid serial id");
        require(msg.value >= price, "DibbsERC721Upgradeable: not enough token price");
        require(isCardTokenExisted[serial] != true, "DibbsERC721Upgradeable: existing card token");

        isCardTokenExisted[serial] = true;

        uint256 id = totalSupply();
        cards[id] = Card(
            masterMinter,
            name,
            grade,
            serial,
            price,
            false
        );
        // refund when there's more money than its price
        if (msg.value > price) {
            (bool sent, ) = payable(_msgSender()).call{value: msg.value - price}("");
            require(sent, "DibbsERC721Upgradeable: Change transfer failed");
        }

        uint256 ownerBalanceBefore = balanceOf(_msgSender());

        _safeMint(_msgSender(), id);

        uint256 ownerBalanceAfter = balanceOf(_msgSender());

        _tokenIdTracker.increment();

        require(
            (ownerBalanceAfter - ownerBalanceBefore) == 1,
            "DibbsERC721Upgradeable: token minting didn't work properly"
        );

        emit Minted(name, grade, serial, id);
    }

    /**
     * @dev burn nft: delete card info corresponding to tokenId
     * @param tokenId burned id
     */
    function burn(uint256 tokenId) external override onlyOwner{
        isCardTokenExisted[cards[tokenId].serial] = false;
        delete cards[tokenId];

        _burn(tokenId);
    }

    /**
     * @dev change master minter
     * @param newMinter address of new minter
     */
    function changeMasterMinter(address newMinter) external override virtual onlyOwner {
        require(newMinter != address(0), "DibbsERC721Upgradeable: invalid address");

        address prevMinter = masterMinter;
        masterMinter = newMinter;
        emit MasterMinterChanged(prevMinter, newMinter);
    }    
    ///@dev get current master minter address
    function getCurrentMinter() internal view returns (address) {
        return masterMinter;
    }

    ///@dev get current token id tracker
    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
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
}
