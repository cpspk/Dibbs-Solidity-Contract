//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract Admin is ERC721Upgradeable, OwnableUpgradeable {
    using Counters for Counters.Counter;

    ///@dev card id tracker
    Counters.Counter private _cardIdTracker;

    ///@dev dibbs admins
    address public masterMinter;

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

    ///@dev change master minter event
    event MasterMinterChanged(address prevMinter, address newMinter);

    // ///@dev constructor
    // constructor(
    //   string memory _name,
    //   string memory _symbol,
    //   string memory baseURI
    // )
    //     ERC721(_name, _symbol)
    //     Ownable()
    // {
    //     masterMinter = _msgSender();

    //     setBaseURI(baseURI);
    // }

    function initialize(string memory baseURI) initializer public {
        __ERC721_init("Admin", "AD");
        __Ownable_init();

        masterMinter = _msgSender();
        setBaseURI(baseURI);
     }

    /**
     * @dev mint card token to a recepient
     * @param to receipent address
     * @param name card token name
     * @param grade card token grade
     * @param serial card token serial id (Psa indentifier)
     */
    function mint(address to, string calldata name, string calldata grade, uint256 serial) external virtual {
        require(getCurrentMinter() == _msgSender(), "Admin: Only dibbs can mint NFTs");
        require(to != address(0), "Admin: invalid recepient address");
        require(bytes(name).length != 0, "Admin: invalid token name");
        require(bytes(grade).length != 0, "Admin: invalid token grade");
        require(serial > 0, "Admin: invalid serial id");
        require(isCardTokenExisted[serial] != true, "Admin: existing card token");

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

    function changeMasterMinter(address newMinter) external virtual onlyOwner {
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

    /**
     * @dev Get `totalSupply`
     */
    function _totalSupply() internal view returns (uint256) {
        return _cardIdTracker.current();
    }

}
