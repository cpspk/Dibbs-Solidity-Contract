pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

import "../interfaces/IDibbsERC1155.sol";
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
        WAITING,
        ONGOING,
        OVER
    }

    struct AuctionInfo {
        address auctionStarter;
        address[] otherOwners;
        uint256 starterFractionBalance;
        uint256 starterEtherBalance;
        uint256 startedAt;
        uint256 totalPrice;
        uint256 otherOwnersBalance;
        uint256 totalFractionBalance;
        uint256 tokenId;
        mapping(address => bool) claimed;
        mapping(address => bool) isFractionOwner;
        mapping(address => uint256) ownerFractionBalance;
    }

    mapping(uint256 => AuctionInfo) auctionInfos;

    address public dibbsAdmin;

    /// @dev current shotgun status
    ShotgunStatus public currentStatus;

    /// @dev fraction's address
    IDibbsERC1155 public tokenAddr;

    /// @dev represent other owners registered or not
    bool public isOwnerRegistered;

    bool public isTokenIdSet;

    /// @dev constant: half of all fracton amounts
    uint256 public constant HALF_OF_FRACTION_AMOUNT = 5000000000000000;

    /// @dev auction duration : 3 months
    uint256 public constant AUCTION_DURATION = 180;//3 mins for test

    event NewTokenIdSet(uint256 newTokenId);

    event TransferredForShotgun(address owner, address tokenAddr, uint256 id, uint256 amount);

    event AuctionStarted(uint256 auctionId, uint256 startedAt, uint256 totalAmount);

    event Purchased(address purchaser);

    event OtherOwnersReginstered(address owner, uint256 numberOfOwners);

    event ProportionClaimed(address claimer);

    event FractionsRefunded(address stater);

    event Withdrawn(address recepient, uint256 amount, uint256 balance);

    event DibbsAdminChanged(address prevAdmin, address newAdmin);

    event AuctionInitialized(uint256 newAuctionId);

    constructor(
        IDibbsERC1155 _tokenAddr
    ) {
        tokenAddr = _tokenAddr;
        dibbsAdmin = msg.sender;
    }

    /// @dev check if auction is expired or not
    function isAuctionExpired(uint256 id) public view returns (bool) {
        if(block.timestamp >= auctionInfos[id].startedAt.add(AUCTION_DURATION))
            return true;

        return false;
    }

    function getCurrentAuctionId() public view returns (uint256) {
        uint256 id = _auctionIdTracker.current();
        return auctionInfos[id].tokenId;
    }

    /**
     * @dev change master minter
     * @param newAdmin address of new minter
     */
    function changeDibbsAdmin(address newAdmin) external virtual override onlyOwner {
        require(newAdmin != address(0), "Shotgun: invalid address");

        address prevAdmin = dibbsAdmin;
        dibbsAdmin = newAdmin;
        emit DibbsAdminChanged(prevAdmin, newAdmin);
    }    

    /// @dev set new token id    
    function setTokenId(uint256 newTokenId) external override {
        require(msg.sender == dibbsAdmin, "Shotgun: only Dibbs admin can set new token id");
        uint256 id = _auctionIdTracker.current();
        auctionInfos[id].tokenId = newTokenId;
        isTokenIdSet = true;

        emit NewTokenIdSet(newTokenId);
    }

    /**
     * @dev transfer amount of fractions as a participant
     * @param _amount amount of fractions
     */
    function registerFractionOwner(
        uint256 _amount
    ) external override {
        require(isTokenIdSet, "Shotgun: token id should be set first");
        uint256 id = _auctionIdTracker.current();
        require(tokenAddr.balanceOf(msg.sender, auctionInfos[id].tokenId) >= _amount, "Shotgun: caller doesn't have the _amount of fractions");
        require(currentStatus == ShotgunStatus.FREE || currentStatus == ShotgunStatus.WAITING, "Shotgun: is ongoing now or over");
        require(!auctionInfos[id].isFractionOwner[msg.sender], "Shotgun: already registered owner");

        auctionInfos[id].otherOwners.push(msg.sender);
        auctionInfos[id].ownerFractionBalance[msg.sender] = _amount;
        auctionInfos[id].otherOwnersBalance = auctionInfos[id].otherOwnersBalance.add(_amount);
        auctionInfos[id].totalFractionBalance = auctionInfos[id].totalFractionBalance.add(_amount);
        tokenAddr.safeTransferFrom(msg.sender, address(this), auctionInfos[id].tokenId, _amount, '');
        tokenAddr.subFractions(msg.sender, auctionInfos[id].tokenId, _amount);
        auctionInfos[id].isFractionOwner[msg.sender] = true;
        isOwnerRegistered = true;

        emit OtherOwnersReginstered(msg.sender, auctionInfos[id].otherOwners.length);
    }

    /**
     * @dev transfer amount of fractions to start the auction
     * @param _amount amount of fractions
     */
    function registerShotgunStarter(
        uint256 _amount
    ) external payable nonReentrant override {
        require(isTokenIdSet, "Shotgun: token id should be set first");
        uint256 id = _auctionIdTracker.current();
        require(auctionInfos[id].auctionStarter == address(0), "Shoutgun: auction starter already registered.");
        require(currentStatus == ShotgunStatus.FREE, "Shotgun: is ongoing now");
        require(msg.value > 0, "Shotgun: insufficient funds");
        require(
            tokenAddr.balanceOf(msg.sender, auctionInfos[id].tokenId) >= _amount,
            "Shotgun: insufficient amount of fractions"
        );
        require(
            _amount >= HALF_OF_FRACTION_AMOUNT,
            "Shotgun: should be grater than or equal to the half of fraction amount"
        );

        tokenAddr.safeTransferFrom(msg.sender, address(this), auctionInfos[id].tokenId, _amount, '');
        auctionInfos[id].auctionStarter = msg.sender;
        auctionInfos[id].ownerFractionBalance[msg.sender] = _amount;
        auctionInfos[id].starterFractionBalance = _amount;
        auctionInfos[id].starterEtherBalance = msg.value;
        auctionInfos[id].totalFractionBalance = auctionInfos[id].totalFractionBalance.add(_amount);
        tokenAddr.subFractions(msg.sender, auctionInfos[id].tokenId, _amount);

        currentStatus = ShotgunStatus.WAITING;

        emit TransferredForShotgun(msg.sender, address(tokenAddr), auctionInfos[id].tokenId, _amount);
    }

    /// @dev start Shotgun auction
    function startAuction() external override {
        require(msg.sender == dibbsAdmin, "Shotgun: only Dibbs admin can start Shotgun auction");
        require(
            currentStatus == ShotgunStatus.WAITING && isOwnerRegistered,
            "Shotgun: is not ready now."
        );
        uint256 id = _auctionIdTracker.current();
        auctionInfos[id].startedAt = block.timestamp;
        currentStatus = ShotgunStatus.ONGOING;
        auctionInfos[id].totalPrice = auctionInfos[id].starterEtherBalance.mul(auctionInfos[id].totalFractionBalance).div(auctionInfos[id].otherOwnersBalance);
        
        emit AuctionStarted(id, auctionInfos[id].startedAt, auctionInfos[id].totalFractionBalance);
    }

    /// @dev purchse the locked fractions
    function purchase() external payable nonReentrant override {
        require(currentStatus == ShotgunStatus.ONGOING, "Shotgun: is not started yet.");
        uint256 id = _auctionIdTracker.current();
        require(!isAuctionExpired(id), "Shotgun: already expired");
        uint256 price = auctionInfos[id].totalPrice.mul(auctionInfos[id].starterFractionBalance).div(auctionInfos[id].totalFractionBalance);
        require(msg.value >= price, "Shotgun: insufficient funds.");
        require(msg.sender != auctionInfos[id].auctionStarter, "Shotgun: starter can't purchase its fractions");

        uint256 amount = auctionInfos[id].starterFractionBalance.add(auctionInfos[id].ownerFractionBalance[msg.sender]);
        tokenAddr.safeTransferFrom(address(this), msg.sender, auctionInfos[id].tokenId, amount, '');
        tokenAddr.addFractions(msg.sender, auctionInfos[id].tokenId, amount);

        currentStatus = ShotgunStatus.OVER;
        emit Purchased(msg.sender);
    }

    /// @dev claim proportional amount of total price
    function claimProportion(uint256 id) external nonReentrant override {
        require(
            isAuctionExpired(id),
            "Shotgun: is not over yet."
        );

        require(auctionInfos[id].isFractionOwner[msg.sender] || msg.sender == auctionInfos[id].auctionStarter, "Shotgun: caller is not registered.");
        require(!auctionInfos[id].claimed[msg.sender], "Shotgun: already claimed owner");
        auctionInfos[id].claimed[msg.sender] = true;

        uint256 price;
        if (msg.sender == auctionInfos[id].auctionStarter) {
            if (currentStatus == ShotgunStatus.OVER) {
                price = auctionInfos[id].totalPrice.
                            mul(auctionInfos[id].starterFractionBalance).
                            div(auctionInfos[id].totalFractionBalance).
                            add(auctionInfos[id].starterEtherBalance);
                (bool success, ) = payable(auctionInfos[id].auctionStarter).call{value: price}("");
                require(success, "Shotgun: refunding is not successful.");
                
                emit ProportionClaimed(msg.sender);
            } else {
                tokenAddr.safeTransferFrom(
                    address(this),
                    auctionInfos[id].auctionStarter,
                    auctionInfos[id].tokenId,
                    auctionInfos[id].starterFractionBalance.add(auctionInfos[id].otherOwnersBalance),
                    ''
                );

                tokenAddr.addFractions(auctionInfos[id].auctionStarter, auctionInfos[id].tokenId, auctionInfos[id].starterFractionBalance.add(auctionInfos[id].otherOwnersBalance));
                emit FractionsRefunded(msg.sender);
            }
        } else {
            
            if (currentStatus == ShotgunStatus.OVER) {
                tokenAddr.safeTransferFrom(
                    address(this),
                    msg.sender,
                    auctionInfos[id].tokenId,
                    auctionInfos[id].ownerFractionBalance[msg.sender],
                    ''
                );

                tokenAddr.addFractions(msg.sender, auctionInfos[id].tokenId, auctionInfos[id].ownerFractionBalance[msg.sender]);

                emit FractionsRefunded(msg.sender);
            } else {
                uint256 amount = auctionInfos[id].ownerFractionBalance[msg.sender];
                price = auctionInfos[id].starterEtherBalance.mul(amount).div(auctionInfos[id].starterFractionBalance);
                (bool success, ) = payable(msg.sender).call{value: price}("");
                require(success, "Shotgun: refunding is not successful.");

                emit ProportionClaimed(msg.sender);
            }
        }
    }

    /// @dev initialize after endin Shotgun auction
    function initialize() external override {
        require(msg.sender == dibbsAdmin, "Shotgun: only Dibbs admin can initialize.");
        uint256 id = _auctionIdTracker.current();
        require(
            currentStatus == ShotgunStatus.OVER || isAuctionExpired(id),
            "Shotgun: is not over yet."
        );
        ///@dev initialize state variables for next auction.
        currentStatus = ShotgunStatus.FREE;
        isOwnerRegistered = false;
        isTokenIdSet = false;
        _auctionIdTracker.increment();

        emit AuctionInitialized(_auctionIdTracker.current());
    }

    /**
    * @dev send / withdraw _amount to _receiver
    * @param _receiver address of recepient
    * @param _amount amount of ether to with
    */
    function withdrawTo(address _receiver, uint256 _amount) external nonReentrant override {
        require(msg.sender == dibbsAdmin, "Shotgun: only Dibbs admin can withdraw.");
        require(_receiver != address(0) && _receiver != address(this));
        require(_amount > 0 && _amount <= address(this).balance);
        (bool sent, ) = payable(_receiver).call{value: _amount}("");
        require(sent, "Shotgun: Transfer failed");
        emit Withdrawn(_receiver, _amount, address(this).balance);
    }
}
