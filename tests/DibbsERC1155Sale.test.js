const { expect } = require("chai")
const { ethers } = require("hardhat")

const web3Utils = require("web3-utils")

describe("DibbsERC1155Sale", function() {
  before(async () => {
    const [masterMinter, Alice, Bob, Carl] = await ethers.getSigners()
    this.masterMinter = masterMinter
    this.Alice = Alice
    this.Bob = Bob
    this.Carl = Carl
    this.tokenIds = [0, 1, 2, 3, 4, 5, 6, 7, 8]
    this.supply = 100
    this.tokenURI = "fakeTokenURI"
    this.nftPrice = ethers.utils.parseEther("0.06")
    this.additional = ethers.utils.parseEther("0.00000000000000001")
    
    const DibbsERC721Upgradeable = await ethers.getContractFactory("DibbsERC721Upgradeable")
    this.dibbsERC721Upgradeable = await DibbsERC721Upgradeable.deploy();
    await this.dibbsERC721Upgradeable.initialize("https://dibbs/")

    const DibbsERC1155 = await ethers.getContractFactory("DibbsERC1155")
    this.dibbsERC1155 = await DibbsERC1155.deploy(
      this.dibbsERC721Upgradeable.address,
      "https://api-testnet.dibbs.co/contractMetadata/"
    )

    const TransferProxy = await ethers.getContractFactory("TransferProxy")
    this.transferProxy = await TransferProxy.deploy()

    const DibbsERC1155Sale = await ethers.getContractFactory("DibbsERC1155Sale")
    this.dibbsERC1155Sale = await DibbsERC1155Sale.deploy(
      this.dibbsERC1155.address,
      this.transferProxy.address
    )
  })

  it("Mint succeeds: should mint a NFT on Dibbs account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mintToDibbs("Messi shot SPA10", "SPA10", 123, this.nftPrice))
    .emit(this.dibbsERC721Upgradeable, "Minted")
    .withArgs("Messi shot SPA10", "SPA10", 123, this.tokenIds[0])
  })

  it("Mint succeeds: should mint a NFT on Dibbs account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mintToDibbs("Messi shot SPA10", "SPA10", 124, this.nftPrice))
    .emit(this.dibbsERC721Upgradeable, "Minted")
    .withArgs("Messi shot SPA10", "SPA10", 124, this.tokenIds[1])
  })

  it("Mint succeeds: should mint a NFT on Dibbs account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mintToDibbs("Messi shot SPA10", "SPA10", 125, this.nftPrice))
    .emit(this.dibbsERC721Upgradeable, "Minted")
    .withArgs("Messi shot SPA10", "SPA10", 125, this.tokenIds[2])
  })

  it("Fractionalizing to a user succeeds: to Alice", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalizeToUser(
      this.Alice.address,
      this.tokenIds[0],
    )).emit(this.dibbsERC1155, "Fractionalized")
      .withArgs(this.Alice.address, this.tokenIds[0])
  })

  it("Fractionalizing to a user succeeds: to Alice", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalizeToUser(
      this.Alice.address,
      this.tokenIds[1],
    )).emit(this.dibbsERC1155, "Fractionalized")
    .withArgs(this.Alice.address, this.tokenIds[1])
  })

  it("Fractionalizing to Dibbs succeeds", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalizeToDibbs(this.tokenIds[2]))
      .emit(this.dibbsERC1155, "Fractionalized")
      .withArgs(this.masterMinter.address, this.tokenIds[2])
  })

  it("Selling the token with id 0 from Alice to Dibbs by amount fails", async () => {
    const amount = await ethers.BigNumber.from("10000000000000001")
    await this.dibbsERC1155.connect(this.Alice).setApprovalForAll(
      this.dibbsERC1155Sale.address,
      true
    )

    await expect(this.dibbsERC1155Sale.connect(this.Alice).sell(
      this.dibbsERC1155.address,
      this.tokenIds[0],
      amount
    )).to.revertedWith("ERC1155Sale.sell: Sell amount exceeds balance")
  })

  it("Selling the token with id 0 (from Alice) to Dibbs by amount fails", async () => {
    const amount = await ethers.BigNumber.from("1")
    await this.dibbsERC1155.connect(this.Alice).setApprovalForAll(
      this.dibbsERC1155Sale.address,
      true
    )

    await expect(this.dibbsERC1155Sale.connect(this.Alice).sell(
      this.dibbsERC1155.address,
      this.tokenIds[0],
      amount
    )).to.revertedWith("ERC1155Sale.Sell: Change transfer failed")
  })

  it("Purchasing the token with id 2 from Dibbs (to Dibbs) by amount succeeds", async () => {
    const amount = await ethers.BigNumber.from("7000000000000000")
    const price = ethers.utils.parseEther("0.042")
    await this.dibbsERC1155.connect(this.masterMinter).setApprovalForAll(
      this.dibbsERC1155Sale.address,
      true
    )

    expect(await this.dibbsERC1155.isApprovedForAll(this.masterMinter.address, this.dibbsERC1155Sale.address)).to.equal(true)

    await expect(this.dibbsERC1155Sale.connect(this.Bob).purchase(
      this.dibbsERC1155.address,
      this.tokenIds[2],
      amount,
      { value: this.nftPrice }
    )).emit(this.dibbsERC1155Sale, "Purchased")
      .withArgs(this.dibbsERC1155.address, this.tokenIds[2], price, this.Bob.address, amount)

    expect(await this.dibbsERC1155.balanceOf(this.Bob.address, this.tokenIds[2])).to.equal(await ethers.BigNumber.from("7000000000000000"))
    expect(await this.dibbsERC1155.balanceOf(this.masterMinter.address, this.tokenIds[2])).to.equal(await ethers.BigNumber.from("3000000000000000"))
  })

  it("Selling the token with id 0 (from Alice) to Dibbs by amount succeeds", async () => {
    const amount = await ethers.BigNumber.from("1")
    await this.dibbsERC1155.connect(this.Alice).setApprovalForAll(
      this.dibbsERC1155Sale.address,
      true
    )

    await expect(this.dibbsERC1155Sale.connect(this.Alice).sell(
      this.dibbsERC1155.address,
      this.tokenIds[0],
      amount
    )).emit(this.dibbsERC1155Sale, "Sold")
      .withArgs(this.dibbsERC1155.address, this.tokenIds[0], this.Alice.address, amount)

    expect(await this.dibbsERC1155.balanceOf(this.Alice.address, this.tokenIds[0])).to.equal(await ethers.BigNumber.from("9999999999999999"))
    expect(await this.dibbsERC1155.balanceOf(this.masterMinter.address, this.tokenIds[0])).to.equal(await ethers.BigNumber.from("1"))
  })

  it("Selling the token with id 1 (from Alice) to Dibbs by amount succeeds", async () => {
    const amount = await ethers.BigNumber.from("2000000000000000")

    await expect(this.dibbsERC1155Sale.connect(this.Alice).sell(
      this.dibbsERC1155.address,
      this.tokenIds[1],
      amount
    )).emit(this.dibbsERC1155Sale, "Sold")
      .withArgs(this.dibbsERC1155.address, this.tokenIds[1], this.Alice.address, amount)

    expect(await this.dibbsERC1155.balanceOf(this.Alice.address, this.tokenIds[1])).to.equal(await ethers.BigNumber.from("8000000000000000"))
    expect(await this.dibbsERC1155.balanceOf(this.masterMinter.address, this.tokenIds[1])).to.equal(await ethers.BigNumber.from("2000000000000000"))
    // console.log(await this.dibbsERC1155.getPrice(this.tokenIds[1], amount))
  })
})