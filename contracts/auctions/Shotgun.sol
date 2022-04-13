pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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

    /// @dev fraction type id for auction
    uint256 public tokenId;

    /// @dev represent other owners registered or not
    bool public isOwnerRegistered;

    bool public isTokenIdSet;

    /// @dev constant: half of all fracton amounts
    uint256 public constant HALF_OF_FRACTION_AMOUNT = 5000000000000000;

    /// @dev auction duration : 3 months
    uint256 public constant AUCTION_DURATION = 90 days;

    event NewTokenIdSet(uint256 newTokenId);

    event TransferredForShotgun(address owner, address tokenAddr, uint256 id, uint256 amount);

    event AuctionStarted(uint256 startedAt, uint256 totalAmount);

    event Purchased(address purchaser);

    event OtherOwnersReginstered(address owner, uint256 numberOfOwners);

    event ProportionClaimed(address claimer);

    event FractionsRefunded(address stater);

    event Withdrawn(address recepient, uint256 amount, uint256 balance);

    event DibbsAdminChanged(address prevAdmin, address newAdmin);

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
        tokenId = newTokenId;
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
        require(tokenAddr.balanceOf(msg.sender, tokenId) >= _amount, "Shotgun: caller doesn't have the _amount of fractions");
        require(currentStatus == ShotgunStatus.FREE || currentStatus == ShotgunStatus.WAITING, "Shotgun: is ongoing now or over");
        require(!auctionInfos[tokenId].isFractionOwner[msg.sender], "Shotgun: already registered owner");

        auctionInfos[tokenId].otherOwners.push(msg.sender);
        auctionInfos[tokenId].ownerFractionBalance[msg.sender] = _amount;
        auctionInfos[tokenId].otherOwnersBalance = auctionInfos[tokenId].otherOwnersBalance.add(_amount);
        auctionInfos[tokenId].totalFractionBalance = auctionInfos[tokenId].totalFractionBalance.add(_amount);
        tokenAddr.safeTransferFrom(msg.sender, address(this), tokenId, _amount, '');
        tokenAddr.subFractions(msg.sender, tokenId, _amount);
        auctionInfos[tokenId].isFractionOwner[msg.sender] = true;
        isOwnerRegistered = true;

        emit OtherOwnersReginstered(msg.sender, auctionInfos[tokenId].otherOwners.length);
    }

    /**
     * @dev transfer amount of fractions to start the auction
     * @param _amount amount of fractions
     */
    function registerShotgunStarter(
        uint256 _amount
    ) external payable nonReentrant override {
        require(isTokenIdSet, "Shotgun: token id should be set first");
        require(auctionInfos[tokenId].auctionStarter == address(0), "Shoutgun: auction starter already registered.");
        require(currentStatus == ShotgunStatus.FREE, "Shotgun: is ongoing now");
        require(msg.value > 0, "Shotgun: insufficient funds");
        require(
            tokenAddr.balanceOf(msg.sender, tokenId) >= _amount,
            "Shotgun: insufficient amount of fractions"
        );
        require(
            _amount >= HALF_OF_FRACTION_AMOUNT,
            "Shotgun: should be grater than or equal to the half of fraction amount"
        );

        tokenAddr.safeTransferFrom(msg.sender, address(this), tokenId, _amount, '');
        auctionInfos[tokenId].auctionStarter = msg.sender;
        auctionInfos[tokenId].ownerFractionBalance[msg.sender] = _amount;
        auctionInfos[tokenId].starterFractionBalance = _amount;
        auctionInfos[tokenId].starterEtherBalance = msg.value;
        auctionInfos[tokenId].totalFractionBalance = auctionInfos[tokenId].totalFractionBalance.add(_amount);
        tokenAddr.subFractions(msg.sender, tokenId, _amount);

        currentStatus = ShotgunStatus.WAITING;

        emit TransferredForShotgun(msg.sender, address(tokenAddr), tokenId, _amount);
    }

    /// @dev start Shotgun auction
    function startAuction() external override {
        require(msg.sender == dibbsAdmin, "Shotgun: only Dibbs admin can start Shotgun auction");
        require(
            currentStatus == ShotgunStatus.WAITING && isOwnerRegistered,
            "Shotgun: is not ready now."
        );
        auctionInfos[tokenId].startedAt = block.timestamp;
        currentStatus = ShotgunStatus.ONGOING;
        auctionInfos[tokenId].totalPrice = auctionInfos[tokenId].starterEtherBalance.mul(auctionInfos[tokenId].totalFractionBalance).div(auctionInfos[tokenId].otherOwnersBalance);
        
        emit AuctionStarted(auctionInfos[tokenId].startedAt, auctionInfos[tokenId].totalFractionBalance);
    }

    /// @dev purchse the locked fractions
    function purchase() external payable nonReentrant override {
        require(currentStatus == ShotgunStatus.ONGOING, "Shotgun: is not started yet.");
        require(!isAuctionExpired(tokenId), "Shotgun: already expired");
        uint256 price = auctionInfos[tokenId].totalPrice.mul(auctionInfos[tokenId].starterFractionBalance).div(auctionInfos[tokenId].totalFractionBalance);
        require(msg.value >= price, "Shotgun: insufficient funds.");

        uint256 amount = auctionInfos[tokenId].starterFractionBalance.add(auctionInfos[tokenId].ownerFractionBalance[msg.sender]);
        tokenAddr.safeTransferFrom(address(this), msg.sender, tokenId, amount, '');
        tokenAddr.addFractions(msg.sender, tokenId, amount);

        currentStatus = ShotgunStatus.OVER;
        emit Purchased(msg.sender);
    }

    /// @dev claim proportional amount of total price
    function claimProportion(uint256 _tokenId) external nonReentrant override {
        require(
            currentStatus == ShotgunStatus.OVER || isAuctionExpired(tokenId),
            "Shotgun: is not over yet."
        );
        require(auctionInfos[_tokenId].isFractionOwner[msg.sender] || msg.sender == auctionInfos[_tokenId].auctionStarter, "Shotgun: caller is not registered.");
        require(!auctionInfos[_tokenId].claimed[msg.sender], "Shotgun: already claimed owner");
        auctionInfos[_tokenId].claimed[msg.sender] = true;

        uint256 price;
        if (msg.sender == auctionInfos[_tokenId].auctionStarter) {
            if (currentStatus == ShotgunStatus.OVER) {
                price = auctionInfos[_tokenId].totalPrice.
                            mul(auctionInfos[_tokenId].starterFractionBalance).
                            div(auctionInfos[_tokenId].totalFractionBalance).
                            add(auctionInfos[_tokenId].starterEtherBalance);
                (bool success, ) = payable(auctionInfos[_tokenId].auctionStarter).call{value: price}("");
                require(success, "Shotgun: refunding is not successful.");
                
                emit ProportionClaimed(msg.sender);
            } else {
                tokenAddr.safeTransferFrom(
                    address(this),
                    auctionInfos[_tokenId].auctionStarter,
                    _tokenId,
                    auctionInfos[_tokenId].starterFractionBalance.add(auctionInfos[_tokenId].otherOwnersBalance),
                    ''
                );

                tokenAddr.addFractions(auctionInfos[_tokenId].auctionStarter, _tokenId, auctionInfos[_tokenId].starterFractionBalance.add(auctionInfos[_tokenId].otherOwnersBalance));
                emit FractionsRefunded(msg.sender);
            }
        } else {
            
            if (currentStatus == ShotgunStatus.OVER) {
                tokenAddr.safeTransferFrom(
                    address(this),
                    msg.sender,
                    _tokenId,
                    auctionInfos[_tokenId].ownerFractionBalance[msg.sender],
                    ''
                );

                tokenAddr.addFractions(msg.sender, _tokenId, auctionInfos[_tokenId].ownerFractionBalance[msg.sender]);

                emit FractionsRefunded(msg.sender);
            } else {
                uint256 amount = auctionInfos[_tokenId].ownerFractionBalance[msg.sender];
                price = auctionInfos[_tokenId].starterEtherBalance.mul(amount).div(auctionInfos[_tokenId].starterFractionBalance);
                (bool success, ) = payable(msg.sender).call{value: price}("");
                require(success, "Shotgun: refunding is not successful.");

                emit ProportionClaimed(msg.sender);
            }
        }
    }

    /// @dev initialize after endin Shotgun auction
    function initialize() external override {
        require(msg.sender == dibbsAdmin, "Shotgun: only Dibbs admin can initialize.");
        require(
            currentStatus == ShotgunStatus.OVER || isAuctionExpired(tokenId),
            "Shotgun: is not over yet."
        );
        ///@dev initialize state variables for next auction.
        currentStatus = ShotgunStatus.FREE;
        isOwnerRegistered = false;
        isTokenIdSet = false;
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
