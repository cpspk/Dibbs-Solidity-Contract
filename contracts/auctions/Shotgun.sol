pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

import "../interfaces/IDibbsERC1155.sol";

contract Shotgun is
    ERC1155Holder,
    Ownable
{
    enum ShotgunStatus {
        FREE,
        WAITING,
        ONGOING,
        OVER
    }

    mapping(address => bool) isFractionOwner;

    mapping(address => uint256) ownerFractionBalance;

    ShotgunStatus public currentStatus;

    IDibbsERC1155 public tokenAddr;

    address public auctionStarter;

    address[] public otherOwners;

    uint256 public starterFractionBalance;

    uint256 public starterEtherBalance;

    uint256 public otherOwnersBalance;

    uint256 public totalFractionBalance;

    uint256 public createdAt;

    uint256 public totalPrice;

    uint256 public tokenId;

    bool public isOwnerRegistered;

    uint256 public constant HALF_OF_FRACTION_AMOUNT = 5000000000000000;

    uint256 public constant AUCTION_DURATION = 90 days;

    event TransferredForShotgun(address owner, address tokenAddr, uint256 id, uint256 amount);

    event AuctionStarted(uint256 createdAt, uint256 totalAmount);

    event Purchased(address purchaser);

    event OtherOwnersReginstered(uint256 tokenId, uint256 numberOfOwners);

    event ProportionClaimed(address claimer);

    event FractionsRefunded(address stater);

    constructor(
        IDibbsERC1155 _tokenAddr
    ) {
        tokenAddr = _tokenAddr;
    }

    function isAuctionExpired() public view returns (bool) {
        if(block.timestamp >= createdAt + AUCTION_DURATION)
            return true;

        return false;
    }
    
    function registerOwnersWithTokenId(
        address[] calldata _otherOwners,
        uint256 _tokenId
    ) external onlyOwner {
        require(currentStatus == ShotgunStatus.FREE, "Shotgun: is ongoing now");

        uint256 numberOfOwners = _otherOwners.length;
        require(numberOfOwners != 0, "Shotgun: no fraction owners");

        tokenId = _tokenId;
        isOwnerRegistered = true;

        for (uint i = 0; i < numberOfOwners; i++) {
            if (_otherOwners[i] == address(0)) continue;
            require(!isFractionOwner[_otherOwners[i]], "Shotgun: already registered owner");
            require(tokenAddr.balanceOf(_otherOwners[i], _tokenId) != 0, "Shotgun: the owner has no balance");

            otherOwners.push(_otherOwners[i]);
            uint256 fractionAmount = tokenAddr.balanceOf(_otherOwners[i], _tokenId);
            ownerFractionBalance[_otherOwners[i]] = fractionAmount;
            otherOwnersBalance += fractionAmount;
            tokenAddr.safeTransferFrom(_otherOwners[i], address(this), tokenId, fractionAmount, '');
            isFractionOwner[_otherOwners[i]] = true;
        }

        emit OtherOwnersReginstered(_tokenId, otherOwners.length);
    }

    function transferForShotgun(
        uint256 _amount
    ) external payable {
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
        auctionStarter = msg.sender;
        ownerFractionBalance[auctionStarter] = _amount;
        starterFractionBalance = _amount;
        starterEtherBalance = msg.value;
        totalFractionBalance = starterFractionBalance + otherOwnersBalance;

        currentStatus = ShotgunStatus.WAITING;

        emit TransferredForShotgun(msg.sender, address(tokenAddr), tokenId, _amount);
    }

    function startAuction() public onlyOwner {
        require(
            currentStatus == ShotgunStatus.WAITING && isOwnerRegistered,
            "Shotgun: is not ready now."
        );
        createdAt = block.timestamp;
        currentStatus = ShotgunStatus.ONGOING;
        totalPrice = starterEtherBalance * totalFractionBalance / otherOwnersBalance;
        
        emit AuctionStarted(createdAt, starterFractionBalance + otherOwnersBalance);
    }

    function purchase() external payable {
        require(currentStatus == ShotgunStatus.ONGOING, "Shotgun: is not started yet.");
        require(!isAuctionExpired(), "Shotgun: already expired");
        uint256 price = totalPrice *  starterFractionBalance / totalFractionBalance;
        require(msg.value >= price, "Shotgun: insufficient funds.");

        uint256 amount = starterFractionBalance + ownerFractionBalance[msg.sender];
        tokenAddr.safeTransferFrom(address(this), msg.sender, tokenId, amount, '');

        currentStatus = ShotgunStatus.OVER;
        emit Purchased(msg.sender);
    }

    function claimProportion() external {
        require(
            isAuctionExpired(),
            "Shotgun: is not over yet."
        );
        uint256 price;
        if (msg.sender == auctionStarter) {
            if (currentStatus == ShotgunStatus.OVER) {
                price = totalPrice *  starterFractionBalance / totalFractionBalance + starterEtherBalance;
                (bool success, ) = payable(auctionStarter).call{value: price}("");
                require(success, "Shotgun: refunding is not successful.");
                
                emit ProportionClaimed(msg.sender);
            } else {
                tokenAddr.safeTransferFrom(
                    address(this),
                    auctionStarter,
                    tokenId,
                    starterFractionBalance + otherOwnersBalance,
                    ''
                );
                
                emit FractionsRefunded(msg.sender);
            }
        } else {
            require(isFractionOwner[msg.sender], "Shotgun: caller is not registered.");
            
            if (currentStatus == ShotgunStatus.OVER) {
                tokenAddr.safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenId,
                    ownerFractionBalance[msg.sender],
                    ''
                );

                emit FractionsRefunded(msg.sender);
            } else {
                uint256 amount = ownerFractionBalance[msg.sender];
                price = starterEtherBalance *  amount / starterFractionBalance;
                (bool success, ) = payable(msg.sender).call{value: price}("");
                require(success, "Shotgun: refunding is not successful.");

                emit ProportionClaimed(msg.sender);
            }
        }
    }

    function initialize() external onlyOwner {
        require(
            currentStatus == ShotgunStatus.OVER || isAuctionExpired(),
            "Shotgun: is not over yet."
        );

        ///@dev initialize state variables for next auction.
        uint len = otherOwners.length;
        for (uint i = 0; i < len; i++) {
            isFractionOwner[otherOwners[i]] = false; 
        }
        delete otherOwners;
        currentStatus = ShotgunStatus.FREE;
        createdAt = 0;
        isOwnerRegistered = false;
        totalFractionBalance = 0;
        starterFractionBalance = 0;
        otherOwnersBalance = 0;
    }
}
