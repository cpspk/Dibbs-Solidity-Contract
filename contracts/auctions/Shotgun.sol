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

    /// @dev fractionOwner address => True/false
    mapping(address => bool) isFractionOwner;

    /// @dev fractionOwner address => balance
    mapping(address => uint256) ownerFractionBalance;

    /// @dev represent an owner claimedd his prooprtion or not
    mapping(address => bool) claimed;

    /// @dev current shotgun status
    ShotgunStatus public currentStatus;

    /// @dev fraction's address
    IDibbsERC1155 public tokenAddr;

    /// @dev auction starter address
    address public auctionStarter;

    /// @dev array of other fraction owners' address
    address[] public otherOwners;

    /// @dev fraction balance of auction starter
    uint256 public starterFractionBalance;

    /// @dev ether balance of auction starter
    uint256 public starterEtherBalance;

    /// @dev sum of other fraction owners' balance
    uint256 public otherOwnersBalance;

    /// @dev total fraction balance for auction
    uint256 public totalFractionBalance;

    /// @dev auction start date
    uint256 public startedAt;

    ///@dev total pric of fractions for auction
    uint256 public totalPrice;

    /// @dev fraction type id for auction
    uint256 public tokenId;

    /// @dev represent other owners registered or not
    bool public isOwnerRegistered;

    /// @dev constant: half of all fracton amounts
    uint256 public constant HALF_OF_FRACTION_AMOUNT = 5000000000000000;

    /// @dev auction duration : 3 months
    uint256 public constant AUCTION_DURATION = 90 days;

    event TransferredForShotgun(address owner, address tokenAddr, uint256 id, uint256 amount);

    event AuctionStarted(uint256 startedAt, uint256 totalAmount);

    event Purchased(address purchaser);

    event OtherOwnersReginstered(uint256 tokenId, uint256 numberOfOwners);

    event ProportionClaimed(address claimer);

    event FractionsRefunded(address stater);

    event Withdrawn(address recepient, uint256 amount, uint256 balance);

    constructor(
        IDibbsERC1155 _tokenAddr
    ) {
        tokenAddr = _tokenAddr;
    }

    /// @dev check if auction is expired or not
    function isAuctionExpired() public view returns (bool) {
        if(block.timestamp >= startedAt.add(AUCTION_DURATION))
            return true;

        return false;
    }
    
    /**
     * @dev register other fraction owners
     * @param _otherOwners array of other owners' address
     * @param _tokenId token if for auction
     */
    function registerOwnersWithTokenId(
        address[] calldata _otherOwners,
        uint256 _tokenId
    ) external override onlyOwner {
        require(currentStatus == ShotgunStatus.FREE, "Shotgun: is ongoing now");

        uint256 numberOfOwners = _otherOwners.length;
        require(numberOfOwners != 0, "Shotgun: no fraction owners");

        tokenId = _tokenId;

        for (uint i = 0; i < numberOfOwners; i = i.add(1)) {
            if (_otherOwners[i] == address(0)) continue;
            require(!isFractionOwner[_otherOwners[i]], "Shotgun: already registered owner");
            require(tokenAddr.balanceOf(_otherOwners[i], _tokenId) != 0, "Shotgun: the owner has no balance");

            otherOwners.push(_otherOwners[i]);
            uint256 fractionAmount = tokenAddr.balanceOf(_otherOwners[i], _tokenId);
            ownerFractionBalance[_otherOwners[i]] = fractionAmount;
            otherOwnersBalance = otherOwnersBalance.add(fractionAmount);
            tokenAddr.safeTransferFrom(_otherOwners[i], address(this), tokenId, fractionAmount, '');
            tokenAddr.subFractions(_otherOwners[i], tokenId, fractionAmount);
            isFractionOwner[_otherOwners[i]] = true;
        }

        if (otherOwners.length != 0)
            isOwnerRegistered = true;

        emit OtherOwnersReginstered(_tokenId, otherOwners.length);
    }

    /**
     * @dev transfer amount of fractions to start the auction
     * @param _amount amount of fractions
     */
    function transferForShotgun(
        uint256 _amount
    ) external payable nonReentrant override {
        require(auctionStarter == address(0), "Shoutgun: auction starter already registered.");
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
        totalFractionBalance = starterFractionBalance.add(otherOwnersBalance);
        tokenAddr.subFractions(msg.sender, tokenId, _amount);

        currentStatus = ShotgunStatus.WAITING;

        emit TransferredForShotgun(msg.sender, address(tokenAddr), tokenId, _amount);
    }

    /// @dev start Shotgun auction
    function startAuction() external onlyOwner override {
        require(
            currentStatus == ShotgunStatus.WAITING && isOwnerRegistered,
            "Shotgun: is not ready now."
        );
        startedAt = block.timestamp;
        currentStatus = ShotgunStatus.ONGOING;
        totalPrice = starterEtherBalance.mul(totalFractionBalance).div(otherOwnersBalance);
        
        emit AuctionStarted(startedAt, starterFractionBalance + otherOwnersBalance);
    }

    /// @dev purchse the locked fractions
    function purchase() external payable nonReentrant override {
        require(currentStatus == ShotgunStatus.ONGOING, "Shotgun: is not started yet.");
        require(!isAuctionExpired(), "Shotgun: already expired");
        uint256 price = totalPrice.mul(starterFractionBalance).div(totalFractionBalance);
        require(msg.value >= price, "Shotgun: insufficient funds.");

        uint256 amount = starterFractionBalance.add(ownerFractionBalance[msg.sender]);
        tokenAddr.safeTransferFrom(address(this), msg.sender, tokenId, amount, '');
        tokenAddr.addFractions(msg.sender, tokenId, amount);

        currentStatus = ShotgunStatus.OVER;
        emit Purchased(msg.sender);
    }

    /// @dev claim proportional amount of total price
    function claimProportion() external nonReentrant override {
        require(
            isAuctionExpired(),
            "Shotgun: is not over yet."
        );
        require(!claimed[msg.sender], "Shotgun: already claimed owner");
        claimed[msg.sender] = true;

        uint256 price;
        if (msg.sender == auctionStarter) {
            if (currentStatus == ShotgunStatus.OVER) {
                price = totalPrice.mul(starterFractionBalance).div(totalFractionBalance).add(starterEtherBalance);
                (bool success, ) = payable(auctionStarter).call{value: price}("");
                require(success, "Shotgun: refunding is not successful.");
                
                emit ProportionClaimed(msg.sender);
            } else {
                tokenAddr.safeTransferFrom(
                    address(this),
                    auctionStarter,
                    tokenId,
                    starterFractionBalance.add(otherOwnersBalance),
                    ''
                );

                tokenAddr.addFractions(auctionStarter, tokenId, starterFractionBalance.add(otherOwnersBalance));
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

                tokenAddr.addFractions(msg.sender, tokenId, ownerFractionBalance[msg.sender]);

                emit FractionsRefunded(msg.sender);
            } else {
                uint256 amount = ownerFractionBalance[msg.sender];
                price = starterEtherBalance.mul(amount).div(starterFractionBalance);
                (bool success, ) = payable(msg.sender).call{value: price}("");
                require(success, "Shotgun: refunding is not successful.");

                emit ProportionClaimed(msg.sender);
            }
        }
    }

    /// @dev initialize after endin Shotgun auction
    function initialize() external onlyOwner override {
        require(
            currentStatus == ShotgunStatus.OVER || isAuctionExpired(),
            "Shotgun: is not over yet."
        );

        ///@dev initialize state variables for next auction.
        uint len = otherOwners.length;
        for (uint i = 0; i < len; i++) {
            isFractionOwner[otherOwners[i]] = false;
            claimed[otherOwners[i]] = false;
        }
        delete otherOwners;

        claimed[auctionStarter] =  false;
        auctionStarter = address(0);
        currentStatus = ShotgunStatus.FREE;
        startedAt = 0;
        isOwnerRegistered = false;
        totalFractionBalance = 0;
        starterFractionBalance = 0;
        otherOwnersBalance = 0;
    }

    /**
    * @dev send / withdraw _amount to _receiver
    * @param _receiver address of recepient
    * @param _amount amount of ether to with
    */
    function withdrawTo(address _receiver, uint256 _amount) external onlyOwner nonReentrant override {
        require(_receiver != address(0) && _receiver != address(this));
        require(_amount > 0 && _amount <= address(this).balance);
        (bool sent, ) = payable(_receiver).call{value: _amount}("");
        require(sent, "ERC721Sale.withdrawTo: Transfer failed");
        emit Withdrawn(_receiver, _amount, address(this).balance);
    }
}
