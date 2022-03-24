pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../interfaces/IDibbsERC1155.sol";

contract Shotgun is Ownable {
    using Counters for Counters.Counter;

    ///@dev card id tracker
    Counters.Counter private _idTracker;

    enum ShotgunStatus {
        FREE,
        WAITING,
        ONGOING,
        OVER
    }

    struct ShotgunListing {
        address starter;
        address tokenAddr;
        uint256 tokenId;
        uint256 balance;
        uint256 firstAmount;
        uint256 remainingAmount;
        uint256 createdAt;
    }

    mapping(uint256 => ShotgunListing) listings;

    ShotgunStatus public currentStatus;

    uint256 public constant HALF_OF_FRACTION_AMOUNT = 5000000000000000;
    
    uint256 public constant FRACTION_AMOUNT = 10000000000000000;

    uint256 public constant AUCTION_DURATION = 90 days;

    address[] public fractionOwners;

    uint256 public totalAmount;

    event TransferredForShotgun(address owner, address tokenAddr, uint256 id, uint256 amount);

    event AuctionStarted(uint256 createdAt, uint256 totalAmount);

    event Purchased(address purchaser);

    constructor(
        address[] memory _fractionOwners,
        uint256 _totalAmount
    ) {
        fractionOwners = _fractionOwners;
        totalAmount = _totalAmount;
    }

    function isAuctionExpired(uint256 id) public view returns (bool) {
        if(block.timestamp >= listings[id].createdAt + AUCTION_DURATION)
            return true;

        return false;
    }

    function transferForShotgun(
        IDibbsERC1155 _tokenAddr,
        uint256 _tokenId,
        uint256 _amount
    ) external payable {
        require(currentStatus == ShotgunStatus.FREE, "Shotgun: is ongoing now");
        require(msg.value > 0, "Shotgun: insufficient funds");
        require(
            _tokenAddr.balanceOf(msg.sender, _tokenId) >= _amount,
            "Shotgun: insufficient amount of fractions"
        );
        require(
            _amount >= HALF_OF_FRACTION_AMOUNT,
            "Shotgun: should be grater than or equal to the half of fraction amount"
        );

        _tokenAddr.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, '');

        uint256 id = _idTracker.current();

        listings[id] = ShotgunListing(
            msg.sender,
            address(_tokenAddr),
            _tokenId,
            msg.value,
            _amount,
            0,
            0
        );

        currentStatus = ShotgunStatus.WAITING;
        _idTracker.increment();

        emit TransferredForShotgun(msg.sender, address(_tokenAddr), _tokenId, _amount);
    }

    function startAuction() public onlyOwner {
        require(currentStatus == ShotgunStatus.WAITING, "Shotgun: is not waiting now.");
        uint256 id = _idTracker.current() - 1;
        listings[id].createdAt = block.timestamp;
        listings[id].remainingAmount = totalAmount - listings[id].firstAmount;
        currentStatus = ShotgunStatus.ONGOING;

        emit AuctionStarted(listings[id].createdAt, totalAmount);
    }

    function _getUnitPrice(uint256 id) internal view returns (uint256) {
        return listings[id].balance * FRACTION_AMOUNT / listings[id].remainingAmount;
    }

    function getPrice(uint256 id, uint256 amount) internal view returns (uint256) {
        return _getUnitPrice(id) * amount / FRACTION_AMOUNT;
    }

    function purchase() external payable {
        require(currentStatus == ShotgunStatus.ONGOING, "Shotgun: is not started yet.");
        uint256 id = _idTracker.current() - 1;
        uint256 price = getPrice(id, listings[id].firstAmount);
        require(msg.value >= price, "Shotgun: insufficient funds.");

        IDibbsERC1155(listings[id].tokenAddr).safeTransferFrom(address(this), msg.sender, listings[id].tokenId, listings[id].firstAmount, '');
        currentStatus = ShotgunStatus.OVER;

        emit Purchased(msg.sender);
    }

    function refundToken() external {
        uint256 id = _idTracker.current() - 1;
        require(
            isAuctionExpired(id) && currentStatus != ShotgunStatus.OVER,
            "Shotgun: is ongoing now."
        );

        IDibbsERC1155(listings[id].tokenAddr).safeTransferFrom(
            address(this),
            listings[id].starter,
            listings[id].tokenId,
            totalAmount,
            ''
        );
    }

    function claimProportion() external {
        require(currentStatus == ShotgunStatus.OVER, "Shotgun: is not over yet.");
        uint256 id = _idTracker.current() - 1;
        require(msg.sender == listings[id].starter);
        uint256 price = getPrice(id, listings[id].firstAmount);
        (bool success, ) = payable(listings[id].starter).call{value: price}("");
        require(success, "Shotgun: refunding is not successful.");
    }
}

