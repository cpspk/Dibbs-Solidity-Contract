//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

import "../interfaces/IDibbsERC721Upgradeable.sol";

contract DibbsERC721Upgradeable is
    IDibbsERC721Upgradeable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    IERC721Receiver,
    OwnableUpgradeable {
    using Counters for Counters.Counter;

    ///@dev card id tracker
    Counters.Counter private _tokenIdTracker;

    ///@dev card token info
    struct Card {
        address owner;
        string name;
        string grade;
        string serial;
        bool fractionalized;
    }

    ///@dev id => card token
    mapping(uint256 => Card) public override cards;

    ///@dev Is the card token with id existed or not?
    mapping(string => bool) public exists;

    ///@dev baseTokenURI
    string public baseTokenURI;

    ///@dev dibbs admins
    address public dibbsAdmin;

    ///@dev change master minter event
    event DibbsAdminChanged(address prevMinter, address newMinter);

    ///@dev mint event
    event Minted(address to, string name, string grade, string serial, uint256 id);

    event Burnt(uint256 id);

    event TokenTransferred(uint256 id);

    /**
     * @dev initialize upgraddeable contract uses initialize() instead of constructor
     */
    function initialize() initializer public {
        __ERC721_init("Admin", "AD");
        __ERC721URIStorage_init();
        __Ownable_init();

        dibbsAdmin = _msgSender();// only owner
    }
    /**
     * @dev check if the token id is valid or not
     * @param tokenId the token id
     */
    modifier onlyValidToken(uint256 tokenId) {
        require(_exists(tokenId), "DibbsERC721Upgradeable: invalid card token id");
        _;
    }

    ///@dev get (true or false) whether a token with id fractionalized or not.
    function getFractionStatus(uint256 id) external override view onlyValidToken(id) returns (bool) {
        return cards[id].fractionalized;
    }

    /**
     * @dev (To be called externally) setter function: set true when card is fractionalized
     * @param id the token id
     */
    function setCardFractionalized(uint256 id) external override onlyValidToken(id) {
        cards[id].fractionalized = true;
    }

    function setNewTokenOwner(address newowner, uint256 id) public override onlyValidToken(id) {
        cards[id].owner = newowner;
    }

    function getTokenOwner(uint256 id) public view override onlyValidToken(id) returns (address) {
        return cards[id].owner;
    }

    function isTokenLocked(uint256 id) external view override onlyValidToken(id) returns (bool) {
        return cards[id].owner == address(this);
    }

    /**
     * @dev set card token struct when new token is minted
     * @param owner current token owner
     * @param name card token name
     * @param grade card token grade
     * @param serial card token serial id (Psa indentifier)
     * @param id card token id
     */
    function setCard(address owner, string calldata name, string calldata grade, string calldata serial, uint256 id) external override {
        string memory symbol = getSysmbol(name, grade, serial);
        exists[symbol] = true;

        cards[id] = Card(
            owner,
            name,
            grade,
            serial,
            false //fractionalized
        );
    }

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
    ) external virtual override {
        require(getCurrentMinter() == _msgSender(), "DibbsERC721Upgradeable: Only dibbs can mint NFTs");
        require(bytes(_name).length != 0, "DibbsERC721Upgradeable: invalid token name");
        require(bytes(_grade).length != 0, "DibbsERC721Upgradeable: invalid token grade");
        require(bytes(_serial).length != 0, "DibbsERC721Upgradeable: invalid serial id");
        
        uint256 id = totalSupply();
        string memory symbol = getSysmbol(_name, _grade, _serial);
        require(exists[symbol] != true, "DibbsERC721Upgradeable: existing card token");

        exists[symbol] = true;

        cards[id] = Card(
            _to,
            _name,
            _grade,
            _serial,
            false
        );

        _safeMint(_to, id);
        _setTokenURI(id, _tokenURI);
        _tokenIdTracker.increment();

        emit Minted(_to, _name, _grade, _serial, id);
    }

    /**
     * @dev transfer token
     * @param _tokenId token id
     */
    function transferToken(
        uint256 _tokenId
    ) external override {
        require(
            ownerOf(_tokenId) == _msgSender(),
            "DibbsERC721Upgradeable: Caller is not the owner of the token"
        );

        uint256 senderBalanceBefore = balanceOf(_msgSender());
        uint256 receiverBalanceBefore = balanceOf(address(this));

        safeTransferFrom(_msgSender(), address(this), _tokenId);
        
        uint256 senderBalanceAfter = balanceOf(_msgSender());
        uint256 receiverBalanceAfter = balanceOf(address(this));

        require(
            senderBalanceBefore - senderBalanceAfter == 1 && 
            receiverBalanceAfter - receiverBalanceBefore == 1,
            "DibbsERC721Upgradeable: not transferred successfully"
        );

        setNewTokenOwner(address(this), _tokenId);

        emit TokenTransferred(_tokenId);
    }

    /**
     * @dev get symbol: name + grade + serial
     * @param _name token name
     * @param _grade token grade
     * @param _serial token serial id
     */
    function getSysmbol(
        string memory _name,
        string memory _grade,
        string memory _serial
    ) public pure returns (string memory) {
        return string(abi.encodePacked(_name, _grade, _serial));
    }

    /**
     * @dev burn nft: delete card info corresponding to tokenId
     * @param id burned id
     */
    function burn(uint256 id) external override onlyOwner{
        string memory symbol = getSysmbol(cards[id].name, cards[id].grade, cards[id].serial);
        exists[symbol] = false;
        delete cards[id];

        _burn(id);
        emit Burnt(id);
    }

    /**
     * @dev change master minter
     * @param newAdmin address of new minter
     */
    function changeDibbsAdmin(address newAdmin) external virtual override onlyOwner {
        require(newAdmin != address(0), "DibbsERC721Upgradeable: invalid address");

        address prevAdmin = dibbsAdmin;
        dibbsAdmin = newAdmin;
        emit DibbsAdminChanged(prevAdmin, newAdmin);
    }    
    
    ///@dev get current master minter address
    function getCurrentMinter() internal view returns (address) {
        return dibbsAdmin;
    }

    ///@dev get current token id tracker
    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool) 
    {
        return super.supportsInterface(_interfaceId);
    }

    // Standard functions to be overridden
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable) {
        ERC721Upgradeable._beforeTokenTransfer(from, to, tokenId);
    }


    function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory ) {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        ERC721URIStorageUpgradeable._burn(tokenId);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
