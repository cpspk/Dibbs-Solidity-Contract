//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract CardToken is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    ///@dev card id tracker
    Counters.Counter private _cardIdTracker;

    ///@dev card token info
    struct Card {
        address owner;
        uint256 id;
        string name;
        string grade;
        uint256 serial;
    }
    
    ///@dev id => card token
    mapping(uint256 => Card) internal cards;

    ///@dev Is the card token with id existed or not?
    mapping(uint256 => bool) isCardTokenExisted;

     // baseTokenURI
    string public baseTokenURI;

    ///@dev mint event
    event Minted(address to, string name, string grade, uint256 serial);

    ///@dev constructor
    constructor(
      string memory _name,
      string memory _symbol,
      string memory baseURI
    )
        ERC721(_name, _symbol)
        Ownable()
        ReentrancyGuard()
    {
        setBaseURI(baseURI);
    }

    /**
     * @dev mint card token to a recepient
     * @param to receipent address
     * @param name card token name
     * @param grade card token grade
     * @param serial card token serial id (Psa indentifier)
     */
    function mint(address to, string memory name, string memory grade, uint256 serial) external payable nonReentrant {
        require(to != address(0), "CardToken: invalid recepient address");
        require(bytes(name).length != 0, "CardToken: invalid token name");
        require(bytes(grade).length != 0, "CardToken: invalid token grade");
        require(serial > 0, "CardToken: invalid serial id");
        require(isCardTokenExisted[serial] != true, "CardToken: existing card token");

        isCardTokenExisted[serial] = true;

        uint256 id = _totalSupply();
        cards[id] = Card(
            to,  //will be owner of the token
            id,  //token id
            name,
            grade,
            serial
        );

        _safeMint(to, id);
        _cardIdTracker.increment();

        emit Minted(to, name, grade, serial);
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

    /**
     * @dev Get `totalSupply`
     */
    function _totalSupply() internal view returns (uint256) {
        return _cardIdTracker.current();
    }

}
