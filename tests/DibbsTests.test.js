const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("DibbsTests", function() {
  before(async () => {
    const users = await ethers.getSigners()
    const [dibbsAdmin, Alice, Bob, Carl] = users
    this.dibbsAdmin = dibbsAdmin
    this.Alice = Alice
    this.Bob = Bob
    this.Carl = Carl
    this.tokenIds = [0, 1, 2, 3]
    this.nftPrice = ethers.utils.parseEther("0.06")
    this.additional = ethers.utils.parseEther("0.00000000000000001")
    this.tokenURI = 'https://dibbs.testURI/'

    const DibbsERC721Upgradeable = await ethers.getContractFactory("DibbsERC721Upgradeable")
    this.dibbsERC721Upgradeable = await DibbsERC721Upgradeable.deploy()
    await this.dibbsERC721Upgradeable.initialize()

    const DibbsERC1155 = await ethers.getContractFactory("DibbsERC1155")
    this.dibbsERC1155 = await DibbsERC1155.deploy(
      this.dibbsERC721Upgradeable.address,
      "https://api-testnet.dibbs.co/contractMetadata/"
    )
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

  it("Transferring token to contract fails: caller doesnt have the token with id", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).transferToken(this.tokenIds[0]))
      .to.revertedWith("DibbsERC721Upgradeable: Caller is not the owner of the token")
  })

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

  it("Fractionalizing to a user fails: tokens are already minted", async () => {
    await expect(this.dibbsERC1155.connect(this.dibbsAdmin).fractionalize(
      this.Bob.address,
      this.tokenIds[0],
    )).to.revertedWith("DibbsERC1155: this token is already fractionalized")
  })

  it("Fractionalizing to a user fails: to Bob", async () => {
    await expect(this.dibbsERC1155.connect(this.dibbsAdmin).fractionalize(
      this.Bob.address,
      this.tokenIds[1],
    )).to.revertedWith("DibbsERC1155: this token is not locked in contract")
  })

  it("Transferring fractions to smart contract failed", async () => {
    const amount = ethers.BigNumber.from("1000000000000000000")
    await expect(this.dibbsERC1155.connect(this.Alice).transferFractions(
      this.tokenIds[0],
      amount
    )).to.revertedWith("DibbsERC1155: caller doesn't have the amount of tokens")
  })

  it("Transferring fractions to smart contract succeeds", async () => {
    const amount = ethers.BigNumber.from("10000000000000000")
    await expect(this.dibbsERC1155.connect(this.Alice).transferFractions(
      this.tokenIds[0],
      amount
    )).emit(this.dibbsERC1155, "FractionsTransferred")
      .withArgs(this.Alice.address, this.dibbsERC1155.address, this.tokenIds[0], amount)
  })

  

})
