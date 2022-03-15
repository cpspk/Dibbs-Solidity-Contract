// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../proxy/TransferProxy.sol";
import "./ERC721SaleNonceHolder.sol";
import "../interfaces/IDibbsERC721Upgradeable.sol";

contract DibbsERC721Sale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    event SentToDibbs(
        string name,
        string grade,
        uint256 serial,
        uint256 id
    );

    bytes constant EMPTY = "";
    address public constant tokenVaultAddr = 0xAD143E30AD4852c97716ED5b32d45BcCfF7DEa36;

    TransferProxy public transferProxy;
    ERC721SaleNonceHolder public nonceHolder;
    IDibbsERC721Upgradeable public dibbsERC721Upgradeable;

    constructor(
        TransferProxy _transferProxy,
        ERC721SaleNonceHolder _nonceHolder,
        IDibbsERC721Upgradeable _dibbsERC721Upgradeable
    ) {
        require(
            address(_transferProxy) != address(0x0) && 
            address(_nonceHolder) != address(0x0)
        );
        transferProxy = _transferProxy;
        nonceHolder = _nonceHolder;
        dibbsERC721Upgradeable = _dibbsERC721Upgradeable;
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
            _token.ownerOf(_tokenId) == msg.sender,
            "DibbsERC721Sale.Send: Caller is not the owner of the token"
        );

        transferProxy.erc721safeTransferFrom(_token, msg.sender, tokenVaultAddr, _tokenId);
        dibbsERC721Upgradeable.setCard(_name, _grade, _serial, _price, _tokenId);

        emit SentToDibbs(_name, _grade, _serial, _tokenId);
    }
}
