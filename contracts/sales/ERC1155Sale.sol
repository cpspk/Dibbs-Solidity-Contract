// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC1155SaleNonceHolder.sol";
import "../proxy/TransferProxy.sol";
import "../interfaces/IDibbsERC1155.sol";

contract ERC1155Sale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    uint256 orderId;

    event CloseOrder(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 nonce,
        uint256 orderId
    );

    event Buy(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        address buyer,
        uint256 buyingAmount
    );

    event Sell(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 amount
    );

    event UpdatePrice(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        uint256 orderId
    );

    event UpdateExpSaleDate(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 expSaleDate,
        uint256 orderId
    );

    event UpdateSaleAmount(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 expSaleDate,
        uint256 orderId
    );

    event Withdrawn(
        address receiver,
        uint256 amount,
        uint256 balance
    );

    struct SaleInfo {
        uint256 price;
        uint256 amount;
        address owner;
        uint256 orderId;
    }

    bytes constant EMPTY = "";

    IDibbsERC1155 public dibbsERC1155;

    address public constant tokenVaultAddr = 0xAD143E30AD4852c97716ED5b32d45BcCfF7DEa36;

    /// @dev token address -> order ID -> token id -> sale info
    mapping(address => mapping(uint256 => mapping(uint256 => SaleInfo))) public saleInfos;

    /// @dev token address -> token id -> latestListingPrice
    mapping(address => mapping(uint256 => uint256)) public latestListingPrices;

    /// @dev token address -> token id -> latestSalePrice
    mapping(address => mapping(uint256 => uint256)) public latestSalePrices;

    TransferProxy public transferProxy;
    ERC1155SaleNonceHolder public nonceHolder;

    constructor(
        IDibbsERC1155 _dibbsERC1155,
        TransferProxy _transferProxy,
        ERC1155SaleNonceHolder _nonceHolder
    ) {
        require(
            address(_transferProxy) != address(0x0) && 
            address(_nonceHolder) != address(0x0)
        );
        dibbsERC1155 = _dibbsERC1155;
        transferProxy = _transferProxy;
        nonceHolder = _nonceHolder;
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

        transferProxy.erc1155safeTransferFrom(
            _token,
            msg.sender,
            tokenVaultAddr,
            _tokenId,
            _amount,
            EMPTY
        );

        dibbsERC1155.subFractions(msg.sender, _tokenId, _amount);
        dibbsERC1155.addFractions(tokenVaultAddr, _tokenId, _amount);
        
        emit Sell(
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

    function buy(
        IDibbsERC1155 _token,
        uint256 _tokenId,
        uint256 _amount
    ) external nonReentrant payable {
        require(
            dibbsERC1155.getFractions(tokenVaultAddr, _tokenId) > _amount,
            "ERC1155Sale.buy: Dibbs doesn't have the amount of tokens"
        );

        uint256 tokenPrice = dibbsERC1155.getPrice(_tokenId, _amount);
        require(msg.value >= tokenPrice, "ERC1155Sale.buy: Insufficient funds");

        if (msg.value > tokenPrice) {
            (bool sent, ) = payable(msg.sender).call{value: msg.value - tokenPrice}("");
            require(sent, "ERC1155Sale.buy: Change transfer failed");
        }

        transferProxy.erc1155safeTransferFrom(
            _token,
            tokenVaultAddr,
            msg.sender,
            _tokenId,
            _amount,
            EMPTY
        );

        // Remove from sale info list
        dibbsERC1155.subFractions(tokenVaultAddr, _tokenId, _amount);
        dibbsERC1155.addFractions(msg.sender, _tokenId, _amount);

        if(dibbsERC1155.getFractions(tokenVaultAddr, _tokenId) == 0) {
            dibbsERC1155.deleteOwnerFraction(tokenVaultAddr, _tokenId);
        }

        emit Buy(
            address(_token),
            _tokenId,
            tokenVaultAddr,
            tokenPrice,
            msg.sender,
            _amount
        );
    }
}
