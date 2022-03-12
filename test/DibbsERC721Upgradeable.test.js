const { expect } = require("chai")
const {ethers} = require("hardhat")

describe("DibbsERC721Upgradeable", function() {
  before(async () => {
    const users = await ethers.getSigners()
    const [masterMinter, Alice, Bob, Carl] = users
    this.masterMinter = masterMinter
    this.Alice = Alice
    this.Bob = Bob
    this.Carl = Carl
    this.tokenIds = [0, 1, 2, 3]

    const DibbsERC721Upgradeable = await ethers.getContractFactory("DibbsERC721Upgradeable")
    this.dibbsERC721Upgradeable = await DibbsERC721Upgradeable.deploy();

    const MockNFT = await ethers.getContractFactory('MockNFT')
    this.mockNFT = await MockNFT.deploy()

    await this.mockNFT.connect(this.masterMinter).mint(this.Alice.address, 0)
    await this.mockNFT.connect(this.masterMinter).mint(this.Alice.address, 1)
    await this.mockNFT.connect(this.masterMinter).mint(this.Bob.address, 2)
  })

  it("Deployment: initialize Admin contract", async () => {
    await this.dibbsERC721Upgradeable.initialize("https://dibbs/")
  })

  it("Setting card fractionalized fails: should fractionalize only existing token", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).setCardFractionalized(this.tokenIds[0]))
      .to.revertedWith("DibbsERC721Upgradeable: invalid card token id")
  })
  
  it("Mint succeeds: should mint a NFT on Alice's account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mint(this.Alice.address, "Messi shot SPA10", "SPA10", 123))
    .emit(this.dibbsERC721Upgradeable, "Minted")
    .withArgs(this.Alice.address, "Messi shot SPA10", "SPA10", 123, this.tokenIds[0])
  })

  it("Setting card fractionalized succeeds", async () => {
    await this.dibbsERC721Upgradeable.connect(this.masterMinter).setCardFractionalized(this.tokenIds[0])
  })
  
  it("Mint succeeds: should mint a NFT on Bob's account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mint(this.Bob.address, "Messi shot SPA10", "SPA10", 124))
      .emit(this.dibbsERC721Upgradeable, "Minted")
      .withArgs(this.Bob.address, "Messi shot SPA10", "SPA10", 124, this.tokenIds[1])
  })
  
  it("Mint succeeds: should mint one another NFT on Bob's account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mint(this.Bob.address, "Messi shot SPA10", "SPA10", 125))
      .emit(this.dibbsERC721Upgradeable, "Minted")
      .withArgs(this.Bob.address, "Messi shot SPA10", "SPA10", 125, this.tokenIds[2])
  })

  it("Mint fails: should not mint the existing NFT on Alice's account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mint(this.Alice.address, "Messi shot SPA10", "SPA10", 123))
      .to.revertedWith("DibbsERC721Upgradeable: existing card token")
  })

  it("Mint fails: should not mint on invalid address", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mint(ethers.constants.AddressZero, "Messi shot SPA10", "SPA10", 1223))
      .to.revertedWith("DibbsERC721Upgradeable: invalid recepient address")
  })

  it("Mint fails: should not mint card token without name", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mint(this.Alice.address, "", "SPA10", 2123))
      .to.revertedWith("DibbsERC721Upgradeable: invalid token name")
  })

  it("Mint fails: should not mint card token without grade", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mint(this.Alice.address, "Messi shot SPA10", "", 2123))
      .to.revertedWith("DibbsERC721Upgradeable: invalid token grade")
  })

  // it("Register fails: only token owner can transfer it", async () => {
  //   await expect(this.dibbsERC721Upgradeable.connect(this.Alice).register(
  //     this.tokenIds[2],
  //     "Messi shot SPA10",
  //     "SPA10",
  //     124
  //   )).to.revertedWith("DibbsERC721Upgradeable: caller is not the owner")
  // })

  // it("Register succeeds", async () => {
  //   await this.dibbsERC721Upgradeable.connect(this.Alice).approve(this.dibbsERC721Upgradeable.address, this.tokenIds[0])
  //   await expect(this.dibbsERC721Upgradeable.connect(this.Alice).register(
  //     this.tokenIds[0],
  //     "Messi shot SPA10",
  //     "SPA10",
  //     124
  //   )).emit(this.dibbsERC721Upgradeable, "Registered")
  //     .withArgs(this.Alice.address, this.dibbsERC721Upgradeable.address, this.tokenIds[0])
  // })
})
