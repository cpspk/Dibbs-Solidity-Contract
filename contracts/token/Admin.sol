//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

import "../interfaces/IAdmin.sol";
import "./DibbsERC1155.sol";

contract Admin is IAdmin, ERC721Upgradeable, OwnableUpgradeable {
    using Counters for Counters.Counter;

    ///@dev card id tracker
    Counters.Counter private _cardIdTracker;

    ///@dev dibbs admins
    address public masterMinter;

    ///@dev card token info
    struct Card {
        address owner;
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

    // Fraction amount
    uint256 public constant fractionAmount = 100;

    ///@dev mint event
    event Minted(address to, string name, string grade, uint256 serial);

    ///@dev change master minter event
    event MasterMinterChanged(address prevMinter, address newMinter);

    function initialize(string memory baseURI) initializer public {
        __ERC721_init("Admin", "AD");
        __Ownable_init();

        masterMinter = _msgSender();
        setBaseURI(baseURI);
     }

    /**
     * @dev mint card token to a recepient
     * @param owner receipent address
     * @param name card token name
     * @param grade card token grade
     * @param serial card token serial id (Psa indentifier)
     */
    function mintAndFractionalize(address owner, string calldata name, string calldata grade, uint256 serial) external virtual {
        require(getCurrentMinter() == _msgSender(), "Admin: Only dibbs can mint NFTs");
        require(owner != address(0), "Admin: invalid recepient address");
        require(bytes(name).length != 0, "Admin: invalid token name");
        require(bytes(grade).length != 0, "Admin: invalid token grade");
        require(serial > 0, "Admin: invalid serial id");
        require(isCardTokenExisted[serial] != true, "Admin: existing card token");

        isCardTokenExisted[serial] = true;

        uint256 id = _totalSupply();
        cards[id] = Card(
            owner,  //will be owner of the token
            name,
            grade,
            serial
        );

        _safeMint(owner, id);

        DibbsERC1155.fractionalize(owner, id, fractionAmount, baseTokenURI);

        _cardIdTracker.increment();

        emit Minted(owner, name, grade, serial);
    }

    function changeMasterMinter(address newMinter) external virtual onlyOwner {
        require(newMinter != address(0), "Admin: invalid address");

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
