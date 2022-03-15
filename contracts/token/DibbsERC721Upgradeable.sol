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

    address public constant tokenVaultAddr = 0xAD143E30AD4852c97716ED5b32d45BcCfF7DEa36;

    ///@dev card token info
    struct Card {
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

    function getCardPrice(uint256 id) external override view returns (uint256) {
        return cards[id].price;
    }

    /**
     * @dev (To be called externally) setter function: set card balance as a initial amount and fractionalized true when card is fractionalized
     * @param id the token id
     */
    function setCardFractionalized(uint256 id) external override onlyValidToken(id) {
        Card storage card = cards[id];
        card.fractionalized = true;
    }

    function setCard(string calldata name, string calldata grade, uint256 serial, uint256 price, uint256 id) public override {
        require(isCardTokenExisted[serial] != true, "DibbsERC721Upgradeable: existing card token");

        isCardTokenExisted[serial] = true;
        cards[id] = Card(
            name,
            grade,
            serial,
            price,
            false
        );
    }

    /**
     * @dev mint card token to a recepient
     * @param name card token name
     * @param grade card token grade
     * @param serial card token serial id (Psa indentifier)
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
            name,
            grade,
            serial,
            price,
            false
        );

        uint256 ownerBalanceBefore = balanceOf(tokenVaultAddr);

        _safeMint(tokenVaultAddr, id);

        uint256 ownerBalanceAfter = balanceOf(tokenVaultAddr);

        _tokenIdTracker.increment();

        require(
            (ownerBalanceAfter - ownerBalanceBefore) == 1,
            "DibbsERC721Upgradeable: token minting didn't work properly"
        );

        emit Minted(name, grade, serial, id);
    }

    /**
     * @dev mint card token to a recepient
     * @param originalOwner original token owner
     * @param name card token name
     * @param grade card token grade
     * @param serial card token serial id (Psa indentifier)
     * @param price card token price
     */
    function mintToDibbsPayable(
        address originalOwner,
        string calldata name,
        string calldata grade,
        uint256 serial,
        uint256 price
    ) external payable {
        require(getCurrentMinter() == _msgSender(), "DibbsERC721Upgradeable: Only dibbs can mint NFTs");
        require(bytes(name).length != 0, "DibbsERC721Upgradeable: invalid token name");
        require(bytes(grade).length != 0, "DibbsERC721Upgradeable: invalid token grade");
        require(serial > 0, "DibbsERC721Upgradeable: invalid serial id");
        require(msg.value >= price, "DibbsERC721Upgradeable: not enough token price");
        require(isCardTokenExisted[serial] != true, "DibbsERC721Upgradeable: existing card token");

        isCardTokenExisted[serial] = true;

        uint256 id = totalSupply();
        cards[id] = Card(
            name,
            grade,
            serial,
            price,
            false
        );

        if (msg.value > price) {
            (bool sent, ) = payable(originalOwner).call{value: msg.value - price}("");
            require(sent, "DibbsERC721Upgradeable: Change transfer failed");
        }

        uint256 ownerBalanceBefore = balanceOf(tokenVaultAddr);

        _safeMint(tokenVaultAddr, id);

        uint256 ownerBalanceAfter = balanceOf(tokenVaultAddr);

        _tokenIdTracker.increment();

        require(
            (ownerBalanceAfter - ownerBalanceBefore) == 1,
            "DibbsERC721Upgradeable: token minting didn't work properly"
        );

        emit Minted(name, grade, serial, id);
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

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
