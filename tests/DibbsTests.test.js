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

  it("Transferring token to contract fails: caller doesn't have the token with id", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Carl).transferToken(this.tokenIds[0]))
      .to.revertedWith("DibbsERC721Upgradeable: Caller is not the owner of the token")
  })

  it("Transferring token to contract succeeds", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).transferToken(this.tokenIds[0]))
      .emit(this.dibbsERC721Upgradeable, "TokenTransferred")
      .withArgs(this.tokenIds[0])
    
    expect(await this.dibbsERC721Upgradeable.ownerOf(this.tokenIds[0])).to.equal(this.dibbsERC721Upgradeable.address)
  })

  it("Transferring token to contract succeeds", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).transferToken(this.tokenIds[1]))
      .emit(this.dibbsERC721Upgradeable, "TokenTransferred")
      .withArgs(this.tokenIds[1])
    
    expect(await this.dibbsERC721Upgradeable.ownerOf(this.tokenIds[1])).to.equal(this.dibbsERC721Upgradeable.address)
  })

  it("Transferring token to contract succeeds", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).transferToken(this.tokenIds[2]))
      .emit(this.dibbsERC721Upgradeable, "TokenTransferred")
      .withArgs(this.tokenIds[2])
    
    expect(await this.dibbsERC721Upgradeable.ownerOf(this.tokenIds[2])).to.equal(this.dibbsERC721Upgradeable.address)
  })

  it("Transferring token to contract succeeds", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).transferToken(this.tokenIds[3]))
      .emit(this.dibbsERC721Upgradeable, "TokenTransferred")
      .withArgs(this.tokenIds[3])
    
    expect(await this.dibbsERC721Upgradeable.ownerOf(this.tokenIds[3])).to.equal(this.dibbsERC721Upgradeable.address)
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

  it("Changing into a new admin succeeds", async () => {
    await expect(this.dibbsERC1155.connect(this.dibbsAdmin).changeDibbsAdmin(this.Bob.address))
      .emit(this.dibbsERC1155, "DibbsAdminChanged")
      .withArgs(this.dibbsAdmin.address, this.Bob.address)
  })

  it("Fractionalizing to a user succeeds: to Alice", async () => {
    await expect(this.dibbsERC1155.connect(this.Bob).fractionalize(
      this.Alice.address,
      this.tokenIds[0],
    )).emit(this.dibbsERC1155, "Fractionalized")
      .withArgs(this.Alice.address, this.tokenIds[0])
  })

  it("Fractionalizing to a user succeeds: to Alice", async () => {
    await expect(this.dibbsERC1155.connect(this.Bob).fractionalize(
      this.Alice.address,
      this.tokenIds[1],
    )).emit(this.dibbsERC1155, "Fractionalized")
      .withArgs(this.Alice.address, this.tokenIds[1])
  })

  it("Fractionalizing to a user succeeds: to Alice", async () => {
    await expect(this.dibbsERC1155.connect(this.Bob).fractionalize(
      this.Alice.address,
      this.tokenIds[2],
    )).emit(this.dibbsERC1155, "Fractionalized")
      .withArgs(this.Alice.address, this.tokenIds[2])
  })

  it("Fractionalizing to a user succeeds: to Alice", async () => {
    await expect(this.dibbsERC1155.connect(this.Bob).fractionalize(
      this.Alice.address,
      this.tokenIds[3],
    )).emit(this.dibbsERC1155, "Fractionalized")
      .withArgs(this.Alice.address, this.tokenIds[3])
  })

  it("Fractionalizing to a user fails: tokens are already minted", async () => {
    await expect(this.dibbsERC1155.connect(this.Bob).fractionalize(
      this.Bob.address,
      this.tokenIds[0],
    )).to.revertedWith("DibbsERC1155: this token is already fractionalized")
  })

  it("Locking fractions into smart contract failed", async () => {
    const amount = ethers.BigNumber.from("1000000000000000000")
    await expect(this.dibbsERC1155.connect(this.Alice).transferFractions(
      this.dibbsERC1155.address,
      this.tokenIds[0],
      amount
    )).to.revertedWith("DibbsERC1155: caller doesn't have the amount of tokens")
  })

  it("Locking fractions into smart contract succeeds", async () => {
    const amount = ethers.BigNumber.from("10000000000000000")
    await expect(this.dibbsERC1155.connect(this.Alice).transferFractions(
      this.dibbsERC1155.address,
      this.tokenIds[0],
      amount
    )).emit(this.dibbsERC1155, "FractionsTransferred")
      .withArgs(this.Alice.address, this.dibbsERC1155.address, this.tokenIds[0], amount)
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
  
  it("Changing into a new admin succeeds", async () => {
    await expect(this.shotgun.connect(this.dibbsAdmin).changeDibbsAdmin(this.David.address))
      .emit(this.shotgun, "DibbsAdminChanged")
      .withArgs(this.dibbsAdmin.address, this.David.address)
  })

  it("Alice registers as a participant fails: token id for auction is not set yet.", async () => {
    const amount = ethers.BigNumber.from("6000000000000000")
    await expect(this.shotgun.connect(this.Alice).registerFractionOwner(amount))
      .to.revertedWith("Shotgun: token id should be set first")
  })

  it("Setting a token id for new Shotgun auction succeeds", async () => {
    await expect(this.shotgun.connect(this.David).setTokenId(this.tokenIds[1]))
      .emit(this.shotgun, "NewTokenIdSet")
      .withArgs(this.tokenIds[1])
  })

  it("Bob registers as a participant", async () => {
    this.dibbsERC1155.connect(this.Bob).setApprovalForAll(this.shotgun.address, true)
    const amount = ethers.BigNumber.from("1000000000000000")
    await expect(this.shotgun.connect(this.Bob).registerFractionOwner(
      amount
    )).emit(this.shotgun, "OtherOwnersReginstered")
      .withArgs(this.tokenIds[1], 1)
  })

  it("Carl registers as a participant", async () => {
    this.dibbsERC1155.connect(this.Carl).setApprovalForAll(this.shotgun.address, true)
    const amount = ethers.BigNumber.from("3000000000000000")
    await expect(this.shotgun.connect(this.Carl).registerFractionOwner(
      amount
    )).emit(this.shotgun, "OtherOwnersReginstered")
      .withArgs(this.tokenIds[1], 2)
  })

  it("Transferring fractions and ethers for Shotgun auction failed: insufficient funds", async () => {
    const amount = ethers.BigNumber.from("6000000000000000")
    await expect(this.shotgun.connect(this.Alice).registerShotgunStarter(
      amount,
      {value: 0}
    )).to.revertedWith("Shotgun: insufficient funds")
  })

  it("Transferring fractions and ethers for Shotgun auction failed: insufficient amount of fractions", async () => {
    const amount = ethers.BigNumber.from("7000000000000000")
    await expect(this.shotgun.connect(this.Alice).registerShotgunStarter(
      amount,
      {value: this.starterBalance}
    )).to.revertedWith("Shotgun: insufficient amount of fractions")
  })

  it("Transferring fractions and ethers for Shotgun auction failed: should transfer more than 5000000000000000 fractions", async () => {
    const amount = ethers.BigNumber.from("4000000000000000")
    await expect(this.shotgun.connect(this.Alice).registerShotgunStarter(
      amount,
      {value: this.starterBalance}
    )).to.revertedWith("Shotgun: should be grater than or equal to the half of fraction amount")
  })
  
  it("Transferring fractions and ethers as a auction starter for Shotgun auction succeeds", async () => {
    const amount = ethers.BigNumber.from("6000000000000000")
    await this.dibbsERC1155.connect(this.Alice).setApprovalForAll(this.shotgun.address, true)
    await expect(this.shotgun.connect(this.Alice).registerShotgunStarter(
      amount,
      {value: this.starterBalance}
    )).emit(this.shotgun, "TransferredForShotgun")
      .withArgs(this.Alice.address, this.dibbsERC1155.address, this.tokenIds[1], amount)
  })

  it("Purchasing by Carl failed: auction is not started", async () => {
    await expect(this.shotgun.connect(this.Carl).purchase()).to.revertedWith("Shotgun: is not started yet.")
  })

  it("Starting Shotgun auction", async () => {
    await this.shotgun.connect(this.David).startAuction()
  })
  
  it("Claiming proportion failed: Shotgun is not over yet", async () => {
    await expect(this.shotgun.connect(this.Alice).claimProportion(this.tokenIds[1]))
      .to.revertedWith("Shotgun: is not over yet.")
  })

  it("Pass 3 month", async () => {
    await advanceTime(90 * 24 * 3600);
  })

  it("Claiming proportion succeeded by Alice", async () => {
    await expect(this.shotgun.connect(this.Alice).claimProportion(this.tokenIds[1]))
      .emit(this.shotgun, "FractionsRefunded")
      .withArgs(this.Alice.address)
  })
  
  // it("Purchasing by Carl succeeded", async () => {
  //   await expect(this.shotgun.connect(this.Carl).purchase({value: this.buyerBalance}))
  //     .emit(this.shotgun, "Purchased")
  //     .withArgs(this.Carl.address)
  // })

  // it("Claiming proportion failed: caller is not registered", async () => {
  //   await expect(this.shotgun.connect(this.Carl).claimProportion(this.tokenIds[1]))
  //     .to.revertedWith("Shotgun: caller is not registered.")
  // })

  // it("Claiming proportion succeeded by Alice", async () => {
  //   await expect(this.shotgun.connect(this.Alice).claimProportion(this.tokenIds[1]))
  //     .emit(this.shotgun, "ProportionClaimed")
  //     .withArgs(this.Alice.address)
  // })
  
  it("Claiming proportion succeeded by Bob", async () => {
    await expect(this.shotgun.connect(this.Bob).claimProportion(this.tokenIds[1]))
      .emit(this.shotgun, "ProportionClaimed")
      .withArgs(this.Bob.address)
  })
  
  it("Claiming proportion succeeded by Carl", async () => {
    await expect(this.shotgun.connect(this.Carl).claimProportion(this.tokenIds[1]))
      .emit(this.shotgun, "ProportionClaimed")
      .withArgs(this.Carl.address)
  })

  it("Initialize for next auction", async () => {
    await this.shotgun.connect(this.David).initialize()
  })

  it("Setting a token id for new Shotgun auction succeeds", async () => {
    await expect(this.shotgun.connect(this.David).setTokenId(this.tokenIds[2]))
      .emit(this.shotgun, "NewTokenIdSet")
      .withArgs(this.tokenIds[2])
  })

  it("Bob registers as a participant", async () => {
    this.dibbsERC1155.connect(this.Bob).setApprovalForAll(this.shotgun.address, true)
    const amount = ethers.BigNumber.from("1000000000000000")
    await expect(this.shotgun.connect(this.Bob).registerFractionOwner(
      amount
    )).emit(this.shotgun, "OtherOwnersReginstered")
      .withArgs(this.tokenIds[2], 1)
  })

  it("Carl registers as a participant", async () => {
    this.dibbsERC1155.connect(this.Carl).setApprovalForAll(this.shotgun.address, true)
    const amount = ethers.BigNumber.from("3000000000000000")
    await expect(this.shotgun.connect(this.Carl).registerFractionOwner(
      amount
    )).emit(this.shotgun, "OtherOwnersReginstered")
      .withArgs(this.tokenIds[2], 2)
  })

  it("Transferring fractions and ethers as a auction starter for Shotgun auction succeeds", async () => {
    const amount = ethers.BigNumber.from("6000000000000000")
    await this.dibbsERC1155.connect(this.Alice).setApprovalForAll(this.shotgun.address, true)
    await expect(this.shotgun.connect(this.Alice).registerShotgunStarter(
      amount,
      {value: this.starterBalance}
    )).emit(this.shotgun, "TransferredForShotgun")
      .withArgs(this.Alice.address, this.dibbsERC1155.address, this.tokenIds[2], amount)
  })

  it("Starting Shotgun auction", async () => {
    await this.shotgun.connect(this.David).startAuction()
  })

  it("Pass 2 month", async () => {
    await advanceTime(60 * 24 * 3600);
  })

  it("Purchasing by Carl succeeded", async () => {
    await expect(this.shotgun.connect(this.Carl).purchase({value: this.buyerBalance}))
      .emit(this.shotgun, "Purchased")
      .withArgs(this.Carl.address)
  })

  it("Pass 1 month", async () => {
    await advanceTime(30 * 24 * 3600);
  })

  it("Claiming proportion succeeded by Alice", async () => {
    await expect(this.shotgun.connect(this.Alice).claimProportion(this.tokenIds[2]))
      .emit(this.shotgun, "ProportionClaimed")
      .withArgs(this.Alice.address)
  })

  it("Claiming proportion succeeded by Bob", async () => {
    await expect(this.shotgun.connect(this.Bob).claimProportion(this.tokenIds[2]))
      .emit(this.shotgun, "FractionsRefunded")
      .withArgs(this.Bob.address)
  })

  it("Defractionalizing fraction from Carl failed: insufficient fractions", async () => {
    await expect(this.dibbsERC1155.connect(this.Carl).defractionalize(this.tokenIds[2]))
      .to.revertedWith("DibbsERC1155: insufficient fraction balance")
  })

  it("Defractionalizing fraction from Alice succeeded", async () => {
    await expect(this.dibbsERC1155.connect(this.Alice).defractionalize(this.tokenIds[3]))
      .emit(this.dibbsERC1155, "Defractionalized")
      .withArgs(this.Alice.address, this.tokenIds[3])
  })

  it("Withdrawing a NFT after defractionalizing failed: Bob is not the fraction owner with id 3", async () => {
    await expect(this.dibbsERC1155.connect(this.Bob).withdrawNFTAfterDefractionalizing(this.tokenIds[3]))
      .to.revertedWith("DibbsERC1155: caller is not defractionalizer or tokend id is not the defractionalized one or already withdrew.")
  })

  it("Withdrawing a NFT after defractionalizing failed: Alice can't withdraw the NFT with id 2", async () => {
    await expect(this.dibbsERC1155.connect(this.Alice).withdrawNFTAfterDefractionalizing(this.tokenIds[2]))
      .to.revertedWith("DibbsERC1155: caller is not defractionalizer or tokend id is not the defractionalized one or already withdrew.")
  })

  it("Withdrawing a NFT before defractionalizing failed", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).withdraw(this.Alice.address, this.tokenIds[3]))
      .to.revertedWith("DibbsERC721Upgradeable: caller is not dibbsERC1155 contract")
  })

  it("Withdrawing a NFT after defractionalizing succeeded", async () => {
    await expect(this.dibbsERC1155.connect(this.Alice).withdrawNFTAfterDefractionalizing(this.tokenIds[3]))
      .emit(this.dibbsERC1155, "DefractionalizedNFTWithdrawn")
      .withArgs(this.Alice.address, this.tokenIds[3])
    
    expect(await this.dibbsERC721Upgradeable.ownerOf(this.tokenIds[3])).to.equal(this.Alice.address)
  })

  it("Withdrawing a NFT after defractionalizing failed: Alice already withdrew the NFT", async () => {
    await expect(this.dibbsERC1155.connect(this.Alice).withdrawNFTAfterDefractionalizing(this.tokenIds[3]))
      .to.revertedWith("DibbsERC1155: caller is not defractionalizer or tokend id is not the defractionalized one or already withdrew.")
  })
})
