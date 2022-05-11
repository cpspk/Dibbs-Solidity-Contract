pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

import "../interfaces/IDibbsERC1155.sol";
import "../interfaces/IDibbsERC721Upgradeable.sol";
import "../interfaces/IShotgun.sol";

contract Shotgun is
    IShotgun,
    ReentrancyGuard,
    ERC1155Holder,
    Ownable
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    ///@dev card id tracker
    Counters.Counter public _auctionIdTracker;

    /// @dev represent the status of Shotgun auction
    enum ShotgunStatus {
        FREE,
        ONGOING,
        OVER
    }

    struct AuctionInfo {
        address starter;
        uint256 fractions;
        uint256 ethers;
        uint256 startedAt;
        uint256 restEthers;
        uint256 tokenId;
        ShotgunStatus status;
    }

    mapping(uint256 => AuctionInfo) auctionInfos;

    mapping(uint256 => uint256) auctionIDs;

    address public dibbsAdmin;

    /// @dev current shotgun status
    ShotgunStatus public currentStatus;

    /// @dev fraction's address
    IDibbsERC1155 public fractionAddr;

    IDibbsERC721Upgradeable public nftAddr;

    /// @dev constants
    uint256 public constant HALF_OF_FRACTION_AMOUNT = 5000000000000000;

    uint256 public constant TOTAL_FRACTION_AMOUNT = 10000000000000000;

    /// @dev auction duration : 3 months
    uint256 public AUCTION_DURATION = 1800;//30 mins for test

    event AuctionStarted(uint256 auctionId, uint256 tokenId, uint256 amountLocked);

    event Purchased(address purchaser, uint256 ethers);

    event StarterClaimed(address starter, uint256 ethers);

    event OwnerRedeemed(address owner, uint256 amount, uint256 ethers);

    event OwnerSentAndRedeemed(address owner, uint256 amount, uint256 price);

    event NftWithdrawn(uint256 auctionID, address recipient, uint256 tokenId);

    constructor(
        IDibbsERC721Upgradeable _nftAddr,
        IDibbsERC1155 _fractionAddr
    ) {
        nftAddr = _nftAddr;
        fractionAddr = _fractionAddr;
    }

    function getAuctionIDbyTokenID(uint256 _tokenID)
        public
        view
        returns (uint256)
    {
        return auctionIDs[_tokenID];
    }

    /// @dev check if auction is expired or not
    function isAuctionExpired(uint256 id) public view returns (bool) {
        if(block.timestamp >= auctionInfos[id].startedAt.add(AUCTION_DURATION))
            return true;

        return false;
    }

    function getCurrentAuctionInfo(uint256 id)
        public
        view 
        returns (address, uint256, uint256, uint256, uint256, uint256, ShotgunStatus)
    {
        return (
            auctionInfos[id].starter,
            auctionInfos[id].fractions,
            auctionInfos[id].ethers,
            auctionInfos[id].startedAt,
            auctionInfos[id].restEthers,
            auctionInfos[id].tokenId,
            auctionInfos[id].status
        );
    }

    function changeAuction_Duration(uint256 newDuration)
        external
        virtual
        onlyOwner
    {
        AUCTION_DURATION = newDuration;
    }

    function getPrice(uint256 _amount, uint256 id) public view returns (uint256) {
        uint256 remainings = TOTAL_FRACTION_AMOUNT - auctionInfos[id].fractions;
        uint256 ethers = _amount.mul(auctionInfos[id].ethers).div(remainings);
        return ethers;
    }

    /// @dev start Shotgun auction
    function startAuction(uint256 _tokenId, uint256 _amount) external payable nonReentrant override {
        uint256 id = _auctionIdTracker.current();
        require(auctionInfos[id].status == ShotgunStatus.FREE, "Shotgun: is ongoing or over.");
        require(msg.value > 0, "Shotgun: insufficient funds");
        require(
            fractionAddr.balanceOf(msg.sender, _tokenId) >= _amount,
            "Shotgun: insufficient amount of fractions"
        );
        require(
            _amount >= HALF_OF_FRACTION_AMOUNT,
            "Shotgun: should be grater than or equal to the half of fraction amount"
        );

        auctionIDs[_tokenId] = id;

        auctionInfos[id].startedAt = block.timestamp;
        auctionInfos[id].tokenId = _tokenId;
        auctionInfos[id].starter = msg.sender;
        auctionInfos[id].fractions = _amount;
        auctionInfos[id].ethers = msg.value;
        auctionInfos[id].status = ShotgunStatus.ONGOING;
        _auctionIdTracker.increment();

        fractionAddr.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, '');

        emit AuctionStarted(id, _tokenId, _amount);
    }

    /// @dev purchse the locked fractions
    function purchase(uint256 id) external payable nonReentrant override {
        require(auctionInfos[id].status == ShotgunStatus.ONGOING, "Shotgun: is not started yet.");
        require(!isAuctionExpired(id), "Shotgun: already expired");
        uint256 price = getPrice(auctionInfos[id].fractions, id);
        require(msg.value >= price, "Shotgun: insufficient funds.");
        
        if (msg.value > price) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - price}("");
            require(success);
        }

        fractionAddr.safeTransferFrom(address(this), msg.sender, auctionInfos[id].tokenId, auctionInfos[id].fractions, '');
        auctionInfos[id].status = ShotgunStatus.OVER;
        auctionInfos[id].restEthers = msg.value;

        emit Purchased(msg.sender, msg.value);
    }

    /// @dev Starter claims ethers after it is over
    function claimEtherAfterFinishing(uint256 id) external nonReentrant override {
        require(
            auctionInfos[id].status == ShotgunStatus.OVER,
            "Shotgun: is not over."
        );
        require(msg.sender == auctionInfos[id].starter, "Shotgun: only starter can redeem the locked ETH");

        (bool success, ) = payable(msg.sender).call{value: auctionInfos[id].restEthers + auctionInfos[id].ethers}("");
        require(success, "Shotgun: redeeming is not successful.");

        auctionInfos[id].status = ShotgunStatus.FREE;

        emit StarterClaimed(msg.sender, auctionInfos[id].restEthers);
    }

    function sendAndRedeemProportion(uint256 id) external nonReentrant override {
        require(
            isAuctionExpired(id) && auctionInfos[id].status == ShotgunStatus.ONGOING,
            "Shotgun: is not expired yet."
        );
        uint256 tokenId = auctionInfos[id].tokenId;
        uint256 amount = fractionAddr.balanceOf(msg.sender, tokenId);
        require(amount > 0, "Shotgun: no fractions");

        fractionAddr.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        uint256 price = getPrice(amount, id);
        (bool success, ) = payable(msg.sender).call{value: price}("");
        require(success, "Shotgun: redeeming is not successful.");

        if (fractionAddr.balanceOf(address(this), tokenId) == TOTAL_FRACTION_AMOUNT) {
            fractionAddr.defractionalize(tokenId);
            nftAddr.setCardFractionalized(tokenId, false);
            auctionInfos[id].status = ShotgunStatus.FREE;
        }

        emit OwnerSentAndRedeemed(msg.sender, amount, price);
    }

    function withdrawNFT(uint256 id) external override {
        uint256 tokenId = auctionInfos[id].tokenId;
        address recipient = auctionInfos[id].starter;
        require(msg.sender == auctionInfos[id].starter, "Shotgun: only starter can withdraw the NFT");
        require(
            isAuctionExpired(id) && auctionInfos[id].status == ShotgunStatus.ONGOING,
            "Shotgun: is not expired yet."
        );

        nftAddr.withdraw(recipient, tokenId);
        
        emit NftWithdrawn(id, recipient, tokenId);
    }
}
