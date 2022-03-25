const { expect } = require("chai")
const { ethers } = require("hardhat")
const { advanceTime } = require('../utils/lib');

describe("DibbsTests", function() {
  before(async () => {
    const users = await ethers.getSigners()
    const [dibbsAdmin, Alice, Bob, Carl, David] = users
    this.dibbsAdmin = dibbsAdmin
    this.Alice = Alice
    this.Bob = Bob
    this.Carl = Carl
    this.David = David
    this.tokenIds = [0, 1, 2, 3]
    this.nftPrice = ethers.utils.parseEther("0.06")
    this.additional = ethers.utils.parseEther("0.00000000000000001")
    this.starterBalance = ethers.utils.parseEther("0.004")
    this.buyerBalance = ethers.utils.parseEther("0.006")
    this.tokenURI = 'https://dibbs.testURI/'

    const DibbsERC721Upgradeable = await ethers.getContractFactory("DibbsERC721Upgradeable")
    this.dibbsERC721Upgradeable = await DibbsERC721Upgradeable.deploy()
    await this.dibbsERC721Upgradeable.initialize()

    const DibbsERC1155 = await ethers.getContractFactory("DibbsERC1155")
    this.dibbsERC1155 = await DibbsERC1155.deploy(
      this.dibbsERC721Upgradeable.address,
      "https://api-testnet.dibbs.co/contractMetadata/"
    )

    const Shotgun = await ethers.getContractFactory("Shotgun")
    this.shotgun = await Shotgun.deploy(this.dibbsERC1155.address)
  })

  it("Setting card fractionalized fails: should fractionalize only existing token", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.dibbsAdmin).setCardFractionalized(this.tokenIds[0]))
      .to.revertedWith("DibbsERC721Upgradeable: invalid card token id")
  })

  it("Minting fails: Only dibbs can mint NFTs", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).mint(this.tokenURI, this.Alice.address, "Messi shot SPA10", "SPA10", "123"))
    .to.revertedWith("DibbsERC721Upgradeable: Only dibbs can mint NFTs")
  })

  it("Minting succeeds: should mint a NFT on Alice's account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.dibbsAdmin).mint(this.tokenURI, this.Alice.address, "Messi shot SPA10", "SPA10", "123"))
    .emit(this.dibbsERC721Upgradeable, "Minted")
    .withArgs(this.Alice.address, "Messi shot SPA10", "SPA10", "123", this.tokenIds[0])
  })
  
  it("Minting succeeds: should mint a NFT on Alice's account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.dibbsAdmin).mint(this.tokenURI, this.Alice.address, "Messi shot SPA10", "SPA10", "124"))
    .emit(this.dibbsERC721Upgradeable, "Minted")
    .withArgs(this.Alice.address, "Messi shot SPA10", "SPA10", "124", this.tokenIds[1])
  })
  
  it("Minting succeeds: should mint a NFT on Alice's account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.dibbsAdmin).mint(this.tokenURI, this.Alice.address, "Messi shot SPA10", "SPA10", "125"))
    .emit(this.dibbsERC721Upgradeable, "Minted")
    .withArgs(this.Alice.address, "Messi shot SPA10", "SPA10", "125", this.tokenIds[2])
  })

  it("Minting fails: should not mint the existing NFT on Alice's account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.dibbsAdmin).mint(this.tokenURI, this.Alice.address, "Messi shot SPA10", "SPA10", "123"))
      .to.revertedWith("DibbsERC721Upgradeable: existing card token")
  })

  it("Minting fails: should not mint card token without name", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.dibbsAdmin).mint(this.tokenURI, this.Alice.address, "", "SPA10", "126"))
      .to.revertedWith("DibbsERC721Upgradeable: invalid token name")
  })

  it("Minting fails: should not mint card token without grade", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.dibbsAdmin).mint(this.tokenURI, this.Alice.address, "Messi shot SPA10", "", "126"))
      .to.revertedWith("DibbsERC721Upgradeable: invalid token grade")
  })
  
  it("Minting fails: should not mint card token without grade", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.dibbsAdmin).mint(this.tokenURI, this.Alice.address, "Messi shot SPA10", "SPA10", ""))
      .to.revertedWith("DibbsERC721Upgradeable: invalid serial id")
  })

  it("Changing into a new admin fails: invalid admin address", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.dibbsAdmin).changeDibbsAdmin(ethers.constants.AddressZero))
      .to.revertedWith("DibbsERC721Upgradeable: invalid address")
  })

  it("Changing into a new admin succeeds", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.dibbsAdmin).changeDibbsAdmin(this.Bob.address))
      .emit(this.dibbsERC721Upgradeable, "DibbsAdminChanged")
      .withArgs(this.dibbsAdmin.address, this.Bob.address)
  })

  it("Minting succeeds: should mint a NFT on Alice's account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Bob).mint(this.tokenURI, this.Alice.address, "Messi shot SPA10", "SPA10", "126"))
    .emit(this.dibbsERC721Upgradeable, "Minted")
    .withArgs(this.Alice.address, "Messi shot SPA10", "SPA10", "126", this.tokenIds[3])
  })

  it("Transferring token to contract fails: caller doesnt have the token with id", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Carl).transferToken(this.tokenIds[0]))
      .to.revertedWith("DibbsERC721Upgradeable: Caller is not the owner of the token")
  })

  it("Transferring token to contract succeeds", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).transferToken(this.tokenIds[0]))
      .emit(this.dibbsERC721Upgradeable, "TokenTransferred")
      .withArgs(this.tokenIds[0])
    
    expect(await this.dibbsERC721Upgradeable.ownerOf(this.tokenIds[0])).to.equal(this.dibbsERC721Upgradeable.address)
    expect(await this.dibbsERC721Upgradeable.getTokenOwner(this.tokenIds[0])).to.equal(this.dibbsERC721Upgradeable.address)
  })

  it("Transferring token to contract succeeds", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).transferToken(this.tokenIds[1]))
      .emit(this.dibbsERC721Upgradeable, "TokenTransferred")
      .withArgs(this.tokenIds[1])
    
    expect(await this.dibbsERC721Upgradeable.ownerOf(this.tokenIds[1])).to.equal(this.dibbsERC721Upgradeable.address)
    expect(await this.dibbsERC721Upgradeable.getTokenOwner(this.tokenIds[1])).to.equal(this.dibbsERC721Upgradeable.address)
  })

  it("Transferring token to contract succeeds", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).transferToken(this.tokenIds[2]))
      .emit(this.dibbsERC721Upgradeable, "TokenTransferred")
      .withArgs(this.tokenIds[2])
    
    expect(await this.dibbsERC721Upgradeable.ownerOf(this.tokenIds[2])).to.equal(this.dibbsERC721Upgradeable.address)
    expect(await this.dibbsERC721Upgradeable.getTokenOwner(this.tokenIds[2])).to.equal(this.dibbsERC721Upgradeable.address)
  })

  it("Transferring token to contract fails: caller doesnt have the token with id", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).transferToken(this.tokenIds[0]))
      .to.revertedWith("DibbsERC721Upgradeable: Caller is not the owner of the token")
  })

  //=====================================  Fractionalization  ====================================== 

  it("Fractionalizing to a user fails: owner address shoud be valid", async () => {
    await expect(this.dibbsERC1155.connect(this.dibbsAdmin).fractionalize(
      ethers.constants.AddressZero,
      this.tokenIds[0],
    )).to.revertedWith("DibbsERC1155: invalid to address")
  })

  it("Fractionalizing to a user succeeds: to Alice", async () => {
    await expect(this.dibbsERC1155.connect(this.dibbsAdmin).fractionalize(
      this.Alice.address,
      this.tokenIds[0],
    )).emit(this.dibbsERC1155, "Fractionalized")
      .withArgs(this.Alice.address, this.tokenIds[0])
  })

  it("Fractionalizing to a user succeeds: to Alice", async () => {
    await expect(this.dibbsERC1155.connect(this.dibbsAdmin).fractionalize(
      this.Alice.address,
      this.tokenIds[1],
    )).emit(this.dibbsERC1155, "Fractionalized")
      .withArgs(this.Alice.address, this.tokenIds[1])
  })

  it("Fractionalizing to a user succeeds: to Alice", async () => {
    await expect(this.dibbsERC1155.connect(this.dibbsAdmin).fractionalize(
      this.Alice.address,
      this.tokenIds[2],
    )).emit(this.dibbsERC1155, "Fractionalized")
      .withArgs(this.Alice.address, this.tokenIds[2])
  })

  it("Fractionalizing to a user fails: tokens are already minted", async () => {
    await expect(this.dibbsERC1155.connect(this.dibbsAdmin).fractionalize(
      this.Bob.address,
      this.tokenIds[0],
    )).to.revertedWith("DibbsERC1155: this token is already fractionalized")
  })

  it("Locking fractions into smart contract failed", async () => {
    const amount = ethers.BigNumber.from("1000000000000000000")
    await expect(this.dibbsERC1155.connect(this.Alice).lockFractions(
      this.tokenIds[0],
      amount
    )).to.revertedWith("DibbsERC1155: caller doesn't have the amount of tokens")
  })

  it("Locking fractions into smart contract succeeds", async () => {
    const amount = ethers.BigNumber.from("10000000000000000")
    await expect(this.dibbsERC1155.connect(this.Alice).lockFractions(
      this.tokenIds[0],
      amount
    )).emit(this.dibbsERC1155, "FractionsLocked")
      .withArgs(this.Alice.address, this.tokenIds[0], amount)
  })

  it("Transferring fractions to Bob succeeds", async () => {
    const amount = ethers.BigNumber.from("1000000000000000")
    await expect(this.dibbsERC1155.connect(this.Alice).transferFractions(
      this.Bob.address,
      this.tokenIds[1],
      amount
    )).emit(this.dibbsERC1155, "FractionsTransferred")
      .withArgs(this.Alice.address, this.Bob.address, this.tokenIds[1], amount)
  })

  it("Transferring fractions to Carl succeeds", async () => {
    const amount = ethers.BigNumber.from("3000000000000000")
    await expect(this.dibbsERC1155.connect(this.Alice).transferFractions(
      this.Carl.address,
      this.tokenIds[1],
      amount
    )).emit(this.dibbsERC1155, "FractionsTransferred")
      .withArgs(this.Alice.address, this.Carl.address, this.tokenIds[1], amount)
  })

  it("Transferring fractions to Bob succeeds", async () => {
    const amount = ethers.BigNumber.from("1000000000000000")
    await expect(this.dibbsERC1155.connect(this.Alice).transferFractions(
      this.Bob.address,
      this.tokenIds[2],
      amount
    )).emit(this.dibbsERC1155, "FractionsTransferred")
      .withArgs(this.Alice.address, this.Bob.address, this.tokenIds[2], amount)
  })

  it("Transferring fractions to Carl succeeds", async () => {
    const amount = ethers.BigNumber.from("3000000000000000")
    await expect(this.dibbsERC1155.connect(this.Alice).transferFractions(
      this.Carl.address,
      this.tokenIds[2],
      amount
    )).emit(this.dibbsERC1155, "FractionsTransferred")
      .withArgs(this.Alice.address, this.Carl.address, this.tokenIds[2], amount)
  })

  //=====================================  Shotgun auction  ====================================== 
  
  it("Starting Shotgun auction fails", async () => {
    await expect(this.shotgun.connect(this.dibbsAdmin).startAuction()).to.revertedWith("Shotgun: is not ready now.")
  })
  
  it("Registering fraction owners failed: only dibbs admin can register fraction owners for Shotgun auction", async () => {
    const fractionOwners = [this.Alice.address, this.Bob.address]
    await expect(this.shotgun.connect(this.Carl).registerOwnersWithTokenId(
      fractionOwners,
      this.tokenIds[1]
    )).to.revertedWith("Ownable: caller is not the owner")
  })

  it("Registering fraction owners failed: no fraction owners there", async () => {
    const fractionOwners = []
    await expect(this.shotgun.connect(this.dibbsAdmin).registerOwnersWithTokenId(
      fractionOwners,
      this.tokenIds[1]
    )).to.revertedWith("Shotgun: no fraction owners")
  })

  it("Registering fraction owners succeeds", async () => {
    const fractionOwners = [this.Carl.address, ethers.constants.AddressZero]
    await this.dibbsERC1155.connect(this.Carl).setApprovalForAll(this.shotgun.address, true)
    await expect(this.shotgun.connect(this.dibbsAdmin).registerOwnersWithTokenId(
      fractionOwners,
      this.tokenIds[1]
    )).emit(this.shotgun, "OtherOwnersReginstered")
      .withArgs(this.tokenIds[1], 1)
  })

  it("Registering fraction owners fails: has already registered owner", async () => {
    const fractionOwners = [this.Carl.address, this.Bob.address]
    await expect(this.shotgun.connect(this.dibbsAdmin).registerOwnersWithTokenId(
      fractionOwners,
      this.tokenIds[1]
    )).to.revertedWith("Shotgun: already registered owner")
  })

  it("Registering fraction other two owners succeeds", async () => {
    const fractionOwners = [this.Bob.address]
    await this.dibbsERC1155.connect(this.Bob).setApprovalForAll(this.shotgun.address, true)
    await this.dibbsERC1155.connect(this.Carl).setApprovalForAll(this.shotgun.address, true)
    await expect(this.shotgun.connect(this.dibbsAdmin).registerOwnersWithTokenId(
      fractionOwners,
      this.tokenIds[1]
    )).emit(this.shotgun, "OtherOwnersReginstered")
      .withArgs(this.tokenIds[1], 2)
  })

  it("Transferring fractions and ethers for Shotgun auction failed: insufficient funds", async () => {
    const amount = ethers.BigNumber.from("6000000000000000")
    await expect(this.shotgun.connect(this.Alice).transferForShotgun(
      amount,
      {value: 0}
    )).to.revertedWith("Shotgun: insufficient funds")
  })

  it("Transferring fractions and ethers for Shotgun auction failed: insufficient amount of fractions", async () => {
    const amount = ethers.BigNumber.from("7000000000000000")
    await expect(this.shotgun.connect(this.Alice).transferForShotgun(
      amount,
      {value: this.starterBalance}
    )).to.revertedWith("Shotgun: insufficient amount of fractions")
  })

  it("Transferring fractions and ethers for Shotgun auction failed: should transfer more than 5000000000000000 fractions", async () => {
    const amount = ethers.BigNumber.from("4000000000000000")
    await expect(this.shotgun.connect(this.Alice).transferForShotgun(
      amount,
      {value: this.starterBalance}
    )).to.revertedWith("Shotgun: should be grater than or equal to the half of fraction amount")
  })
  
  it("Transferring fractions and ethers as a auction starter for Shotgun auction succeeds", async () => {
    const amount = ethers.BigNumber.from("6000000000000000")
    await this.dibbsERC1155.connect(this.Alice).setApprovalForAll(this.shotgun.address, true)
    await expect(this.shotgun.connect(this.Alice).transferForShotgun(
      amount,
      {value: this.starterBalance}
    )).emit(this.shotgun, "TransferredForShotgun")
      .withArgs(this.Alice.address, this.dibbsERC1155.address, this.tokenIds[1], amount)
  })

  it("Purchasing by David failed: auction is not started", async () => {
    await expect(this.shotgun.connect(this.David).purchase()).to.revertedWith("Shotgun: is not started yet.")
  })

  it("Starting Shotgun auction", async () => {
    await this.shotgun.connect(this.dibbsAdmin).startAuction()
  })
  
  it("Claiming proportion failed: Shotgun is not over yet", async () => {
    await expect(this.shotgun.connect(this.Alice).claimProportion())
      .to.revertedWith("Shotgun: is not over yet.")
  })

  it("Pass 3 month", async () => {
    await advanceTime(90 * 24 * 3600);
  })

  it("Claiming proportion succeeded by Alice", async () => {
    await expect(this.shotgun.connect(this.Alice).claimProportion())
      .emit(this.shotgun, "AllFractionsRefunded")
      .withArgs(this.Alice.address)
  })
  
  // it("Purchasing by David succeeded", async () => {
  //   await expect(this.shotgun.connect(this.David).purchase({value: this.buyerBalance}))
  //     .emit(this.shotgun, "Purchased")
  //     .withArgs(this.David.address)
  // })

  // it("Claiming proportion failed: caller is not registered", async () => {
  //   await expect(this.shotgun.connect(this.David).claimProportion())
  //     .to.revertedWith("Shotgun: caller is not registered.")
  // })

  // it("Claiming proportion succeeded by Alice", async () => {
  //   await expect(this.shotgun.connect(this.Alice).claimProportion())
  //     .emit(this.shotgun, "ProportionClaimed")
  //     .withArgs(this.Alice.address)
  // })
  
  it("Claiming proportion succeeded by Bob", async () => {
    await expect(this.shotgun.connect(this.Bob).claimProportion())
      .emit(this.shotgun, "ProportionClaimed")
      .withArgs(this.Bob.address)
  })
  
  it("Claiming proportion succeeded by Carl", async () => {
    await expect(this.shotgun.connect(this.Carl).claimProportion())
      .emit(this.shotgun, "ProportionClaimed")
      .withArgs(this.Carl.address)
  })

  it("Initialize for next auction", async () => {
    await this.shotgun.connect(this.dibbsAdmin).initialize()
  })

  it("Registering fraction other two owners succeeds", async () => {
    const fractionOwners = [this.Bob.address, this.Carl.address]
    await this.dibbsERC1155.connect(this.Bob).setApprovalForAll(this.shotgun.address, true)
    await this.dibbsERC1155.connect(this.Carl).setApprovalForAll(this.shotgun.address, true)
    await expect(this.shotgun.connect(this.dibbsAdmin).registerOwnersWithTokenId(
      fractionOwners,
      this.tokenIds[2]
    )).emit(this.shotgun, "OtherOwnersReginstered")
      .withArgs(this.tokenIds[2], 2)
  })

  it("Transferring fractions and ethers as a auction starter for Shotgun auction succeeds", async () => {
    const amount = ethers.BigNumber.from("6000000000000000")
    await this.dibbsERC1155.connect(this.Alice).setApprovalForAll(this.shotgun.address, true)
    await expect(this.shotgun.connect(this.Alice).transferForShotgun(
      amount,
      {value: this.starterBalance}
    )).emit(this.shotgun, "TransferredForShotgun")
      .withArgs(this.Alice.address, this.dibbsERC1155.address, this.tokenIds[2], amount)
  })

  it("Starting Shotgun auction", async () => {
    await this.shotgun.connect(this.dibbsAdmin).startAuction()
  })

  it("Purchasing by David succeeded", async () => {
    await expect(this.shotgun.connect(this.David).purchase({value: this.buyerBalance}))
      .emit(this.shotgun, "Purchased")
      .withArgs(this.David.address)
  })

  it("Claiming proportion succeeded by Alice", async () => {
    await expect(this.shotgun.connect(this.Alice).claimProportion())
      .emit(this.shotgun, "ProportionClaimed")
      .withArgs(this.Alice.address)
  })

  it("Claiming proportion succeeded by Bob", async () => {
    await expect(this.shotgun.connect(this.Bob).claimProportion())
      .emit(this.shotgun, "ProportionClaimed")
      .withArgs(this.Bob.address)
  })
  
  it("Claiming proportion succeeded by Carl", async () => {
    await expect(this.shotgun.connect(this.Carl).claimProportion())
      .emit(this.shotgun, "ProportionClaimed")
      .withArgs(this.Carl.address)
  })
})
