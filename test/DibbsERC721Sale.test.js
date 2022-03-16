const { expect } = require("chai")
const { ethers } = require("hardhat")
const { BN } = require("web3-utils");

describe("DibbsERC721Sale", function() {
  before(async () => {
    const users = await ethers.getSigners()
    const [masterMinter, Alice, Bob] = users
    this.masterMinter = masterMinter
    this.Alice = Alice
    this.Bob = Bob
    this.tokenIds = [0, 1, 2, 3]
    this.nftPrice = ethers.utils.parseEther("0.06")
    this.additional = ethers.utils.parseEther("0.00000000000000001")

    const TransferProxy = await ethers.getContractFactory("TransferProxy")
    this.transferProxy = await TransferProxy.deploy()

    const DibbsERC721Upgradeable = await ethers.getContractFactory("DibbsERC721Upgradeable")
    this.dibbsERC721Upgradeable = await DibbsERC721Upgradeable.deploy();
    await this.dibbsERC721Upgradeable.initialize("https://dibbs/")

    const DibbsERC721Sale = await ethers.getContractFactory("DibbsERC721Sale")
    this.dibbsERC721Sale = await DibbsERC721Sale.deploy(
      this.transferProxy.address,
      this.dibbsERC721Upgradeable.address
    );
  })

  it("Mint succeeds: should mint a NFT on Dibbs account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mintToDibbs("Messi shot SPA10", "SPA10", 124, this.nftPrice))
      .emit(this.dibbsERC721Upgradeable, "Minted")
      .withArgs("Messi shot SPA10", "SPA10", 124, this.tokenIds[0])
  })

  it("Mint succeeds: should mint a NFT on Dibbs account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mintToDibbs("Messi shot SPA10", "SPA10", 125, this.nftPrice))
      .emit(this.dibbsERC721Upgradeable, "Minted")
      .withArgs("Messi shot SPA10", "SPA10", 125, this.tokenIds[1])
  })

  it("Get the token with id: Master minter", async () => {
    expect(await this.dibbsERC721Upgradeable.getTokenOwner(this.tokenIds[0])).to.equal(this.masterMinter.address)
  })

  it("Purchasing a card token fails: insufficient funds", async () => {
    await this.dibbsERC721Upgradeable.connect(this.masterMinter).approve(this.dibbsERC721Sale.address, this.tokenIds[0])
    await expect(this.dibbsERC721Sale.connect(this.Alice).purchase(
      this.dibbsERC721Upgradeable.address,
      this.tokenIds[0],
      { value: this.additional }
    )).to.revertedWith("DibbsERC721Sale.purchase: insufficient funds")
  })

  it("Purchasing a card token fails: nonexistent token", async () => {
    await this.dibbsERC721Upgradeable.connect(this.masterMinter).approve(this.dibbsERC721Sale.address, this.tokenIds[0])
    await expect(this.dibbsERC721Sale.connect(this.Alice).purchase(
      this.dibbsERC721Upgradeable.address,
      this.tokenIds[3],
      { value: this.additional }
    )).to.revertedWith("DibbsERC721Upgradeable: invalid card token id")
  })

  it("Purchasing a card token succeeds", async () => {
    await this.dibbsERC721Upgradeable.connect(this.masterMinter).approve(this.dibbsERC721Sale.address, this.tokenIds[0])
    await expect(this.dibbsERC721Sale.connect(this.Alice).purchase(
      this.dibbsERC721Upgradeable.address,
      this.tokenIds[0],
      { value: this.nftPrice + this.additional }
    )).emit(this.dibbsERC721Sale, "Purchased")
      .withArgs(this.Alice.address, this.tokenIds[0])
  })

  it("Get the token with id: Alice", async () => {
    expect(await this.dibbsERC721Upgradeable.getTokenOwner(this.tokenIds[0])).to.equal(this.Alice.address)
  })

  it("Sending token to Dibbs failed: only token owner(Alice) can send it", async () => {
    await expect(this.dibbsERC721Sale.connect(this.Bob).sendTokenToDibbs(
      this.dibbsERC721Upgradeable.address,
      this.tokenIds[0],
      "Messi shot SPA10",
      "SPA10",
      124,
      this.nftPrice
    )).to.revertedWith("DibbsERC721Sale.Send: Caller is not the owner of the token")
  })

  it("Sending token to Dibbs succeeds", async () => {
    await this.dibbsERC721Upgradeable.connect(this.Alice).approve(this.dibbsERC721Sale.address, this.tokenIds[0]);
    await expect(this.dibbsERC721Sale.connect(this.Alice).sendTokenToDibbs(
      this.dibbsERC721Upgradeable.address,
      this.tokenIds[0],
      "Messi shot SPA10",
      "SPA10",
      124,
      this.nftPrice
    )).emit(this.dibbsERC721Sale, "SentToDibbs")
      .withArgs(
        "Messi shot SPA10",
        "SPA10",
        124,
        this.tokenIds[0]
      )
  })
})
