// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../proxy/TransferProxy.sol";
import "../interfaces/IDibbsERC721Upgradeable.sol";

contract DibbsERC721Sale is ReentrancyGuard, Ownable {
    event SentToDibbs(
        string name,
        string grade,
        uint256 serial,
        uint256 id
    );

    event Purchased(
        address owner,
        uint256 tokenId
    );

    ///@dev dibbs vault address (Currently using Metamask address)
    address public constant tokenVaultAddr = 0xAD143E30AD4852c97716ED5b32d45BcCfF7DEa36;

    ///@dev master minter
    address public masterMinter;

    TransferProxy public transferProxy;
    IDibbsERC721Upgradeable public dibbsERC721Upgradeable;

    constructor(
        TransferProxy _transferProxy,
        IDibbsERC721Upgradeable _dibbsERC721Upgradeable
    ) {
        require(
            address(_transferProxy) != address(0x0) && 
            address(_dibbsERC721Upgradeable) != address(0x0)
        );
        transferProxy = _transferProxy;
        dibbsERC721Upgradeable = _dibbsERC721Upgradeable;
        masterMinter = _msgSender();
    }

    /**
     * @dev transfer token to contract
     * @param _token ERC721 Token Interface
     * @param _tokenId Id of token
     * @param _name name of token
     * @param _grade grade of token
     * @param _serial serial id of token
     */
    
    function sendTokenToDibbs(
        IDibbsERC721Upgradeable _token,
        uint256 _tokenId,
        string calldata _name,
        string calldata _grade,
        uint256 _serial,
        uint256 _price
    ) external {
        require(
            _token.ownerOf(_tokenId) == _msgSender(),
            "DibbsERC721Sale.Send: Caller is not the owner of the token"
        );
        uint256 id = _tokenId;
        dibbsERC721Upgradeable.setCard(masterMinter, _name, _grade, _serial, _price, id);

        uint256 senderBalanceBefore = _token.balanceOf(_msgSender());
        uint256 receiverBalanceBefore = _token.balanceOf(masterMinter);
        _token.safeTransferFrom(_msgSender(), masterMinter, id);
        uint256 senderBalanceAfter = _token.balanceOf(_msgSender());
        uint256 receiverBalanceAfter = _token.balanceOf(masterMinter);

        require(
            senderBalanceBefore - senderBalanceAfter == 1 && 
            receiverBalanceAfter - receiverBalanceBefore == 1,
            "DibbsERC721Sale.purchase: not transferred successfully;"
        );

        emit SentToDibbs(_name, _grade, _serial, id);
    }

    /**
     * @dev transfer token to contract
     * @param _token ERC721 Token Interface
     * @param _tokenId Id of token
     */

    function purchase(
        IDibbsERC721Upgradeable _token,
        uint256 _tokenId
    ) external payable {
        uint256 tokenPrice = dibbsERC721Upgradeable.getCardPrice(_tokenId);
        require(
            msg.value >= tokenPrice,
            "DibbsERC721Sale.purchase: insufficient funds"
        );
        
        dibbsERC721Upgradeable.setNewTokenOwner(_msgSender(), _tokenId);

        uint256 senderBalanceBefore = _token.balanceOf(masterMinter);
        uint256 receiverBalanceBefore = _token.balanceOf(_msgSender());
        _token.safeTransferFrom(masterMinter, _msgSender(), _tokenId);
        uint256 senderBalanceAfter = _token.balanceOf(masterMinter);
        uint256 receiverBalanceAfter = _token.balanceOf(_msgSender());

        require(
            senderBalanceBefore - senderBalanceAfter == 1 && 
            receiverBalanceAfter - receiverBalanceBefore == 1,
            "DibbsERC721Sale.purchase: not transferred successfully;"
        );

        emit Purchased(_msgSender(), _tokenId);
    }
}
