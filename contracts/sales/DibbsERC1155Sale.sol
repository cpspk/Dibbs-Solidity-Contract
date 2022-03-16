// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../proxy/TransferProxy.sol";
import "../interfaces/IDibbsERC1155.sol";

contract DibbsERC1155Sale is ReentrancyGuard, Ownable {

    event Purchased(
        address indexed token,
        uint256 indexed tokenId,
        uint256 price,
        address buyer,
        uint256 amount
    );

    event Sold(
        address indexed token,
        uint256 indexed tokenId,
        address seller,
        uint256 amount
    );

    address public dibbsAdmin;

    bytes constant EMPTY = "";

    TransferProxy public transferProxy;

    IDibbsERC1155 public dibbsERC1155;

    constructor(
        IDibbsERC1155 _dibbsERC1155,
        TransferProxy _transferProxy
    ) {
        require(
            address(_transferProxy) != address(0x0) && 
            address(_dibbsERC1155) != address(0x0)
        );
        dibbsERC1155 = _dibbsERC1155;
        transferProxy = _transferProxy;
        dibbsAdmin = _msgSender();
    }

    function sell(
        IDibbsERC1155 _token,
        uint256 _tokenId,
        uint256 _amount
    ) external {
        require(
            _token.balanceOf(msg.sender, _tokenId) >= _amount,
            "ERC1155Sale.sell: Sell amount exceeds balance"
        );

        _token.safeTransferFrom(msg.sender, dibbsAdmin, _tokenId, _amount, EMPTY);

        uint256 price = dibbsERC1155.getPrice(_tokenId, _amount);
        //TODO platform fees(price - fee)
        (bool sent, ) = payable(msg.sender).call{ value: price }("");
        require(sent, "ERC1155Sale.Sell: Change transfer failed");

        dibbsERC1155.subFractions(msg.sender, _tokenId, _amount);
        dibbsERC1155.addFractions(dibbsAdmin, _tokenId, _amount);
        
        emit Sold(
            address(_token),
            _tokenId,
            msg.sender,
            _amount
        );
    }

    /**
     * @notice buy token
     * @param _token ERC1155 Token Interface
     * @param _tokenId Id of token
     * @param _amount buyingAmount
     */

    function purchase(
        IDibbsERC1155 _token,
        uint256 _tokenId,
        uint256 _amount
    ) external nonReentrant payable {
        require(
            _token.balanceOf(dibbsAdmin, _tokenId) >= _amount,
            "ERC1155Sale.Purchase: Dibbs doesn't have the amount of tokens"
        );

        uint256 price = dibbsERC1155.getPrice(_tokenId, _amount);
        require(msg.value >= price, "ERC1155Sale.Purchase: Insufficient funds");

        if (msg.value > price) {
            (bool sent, ) = payable(msg.sender).call{value: msg.value - price}("");
            require(sent, "ERC1155Sale.Purchase: Change transfer failed");
        }
        
        _token.safeTransferFrom(dibbsAdmin, msg.sender, _tokenId, _amount, EMPTY);
        // transferProxy.erc1155safeTransferFrom(
        //     _token,
        //     dibbsAdmin,
        //     msg.sender,
        //     _tokenId,
        //     _amount,
        //     EMPTY
        // );

        dibbsERC1155.subFractions(dibbsAdmin, _tokenId, _amount);
        dibbsERC1155.addFractions(msg.sender, _tokenId, _amount);

        if(dibbsERC1155.getFractions(dibbsAdmin, _tokenId) == 0) {
            dibbsERC1155.deleteOwnerFraction(dibbsAdmin, _tokenId);
        }

        emit Purchased(
            address(_token),
            _tokenId,
            price,
            msg.sender,
            _amount
        );
    }
}
