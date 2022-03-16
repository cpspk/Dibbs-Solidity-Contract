const { expect } = require("chai")
const { ethers } = require("hardhat")
const { BN } = require("web3-utils");

describe("DibbsERC721Upgradeable", function() {
  before(async () => {
    const users = await ethers.getSigners()
    const [masterMinter, Alice, Bob, Carl] = users
    this.masterMinter = masterMinter
    this.Alice = Alice
    this.Bob = Bob
    this.Carl = Carl
    this.tokenIds = [0, 1, 2, 3]
    this.nftPrice = ethers.utils.parseEther("0.06")
    this.additional = ethers.utils.parseEther("0.00000000000000001")

    const DibbsERC721Upgradeable = await ethers.getContractFactory("DibbsERC721Upgradeable")
    this.dibbsERC721Upgradeable = await DibbsERC721Upgradeable.deploy();
  })

  it("Deployment: initialize Admin contract", async () => {
    await this.dibbsERC721Upgradeable.initialize("https://dibbs/")
  })

  it("Setting card fractionalized fails: should fractionalize only existing token", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).setCardFractionalized(this.tokenIds[0]))
      .to.revertedWith("DibbsERC721Upgradeable: invalid card token id")
  })

  it("Mint fails: Only dibbs can mint NFTs", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).mintToDibbs("Messi shot SPA10", "SPA10", 123, this.nftPrice))
    .to.revertedWith("DibbsERC721Upgradeable: Only dibbs can mint NFTs")
  })

  it("Mint succeeds: should mint a NFT on Dibbs account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mintToDibbs("Messi shot SPA10", "SPA10", 123, this.nftPrice))
    .emit(this.dibbsERC721Upgradeable, "Minted")
    .withArgs("Messi shot SPA10", "SPA10", 123, this.tokenIds[0])
  })

  it("Setting card fractionalized succeeds", async () => {
    await this.dibbsERC721Upgradeable.connect(this.masterMinter).setCardFractionalized(this.tokenIds[0])
  })
  
  it("Mint succeeds: should mint a NFT on Dibbs account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mintToDibbs("Messi shot SPA10", "SPA10", 124, this.nftPrice))
      .emit(this.dibbsERC721Upgradeable, "Minted")
      .withArgs("Messi shot SPA10", "SPA10", 124, this.tokenIds[1])
  })
  
  it("Mint succeeds: should mint one another NFT on Dibbs account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mintToDibbs("Messi shot SPA10", "SPA10", 125, this.nftPrice))
      .emit(this.dibbsERC721Upgradeable, "Minted")
      .withArgs("Messi shot SPA10", "SPA10", 125, this.tokenIds[2])
  })

  it("Mint fails: should not mint the existing NFT on Alice's account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mintToDibbs("Messi shot SPA10", "SPA10", 123, this.nftPrice))
      .to.revertedWith("DibbsERC721Upgradeable: existing card token")
  })

  it("Mint fails: invalid price", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mintToDibbs("Messi shot SPA10", "SPA10", 1223, 0))
      .to.revertedWith("DibbsERC721Upgradeable: invalid token price")
  })

  it("Mint fails: should not mint card token without name", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mintToDibbs("", "SPA10", 2123, this.nftPrice))
      .to.revertedWith("DibbsERC721Upgradeable: invalid token name")
  })

  it("Mint fails: should not mint card token without grade", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mintToDibbs("Messi shot SPA10", "", 2123, this.nftPrice))
      .to.revertedWith("DibbsERC721Upgradeable: invalid token grade")
  })

  it("Payable mint succeeds: should mint a NFT on Dibbs account with Alice", async () => {
    // const balanceBefore = await this.Alice.getBalance()
    // console.log(balanceBefore.toString())
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).mintToDibbsPayable(
      "Messi shot SPA10",
      "SPA10",
      456,
      this.nftPrice,
      { value: this.nftPrice + this.additional }
    ))
    .emit(this.dibbsERC721Upgradeable, "Minted")
    .withArgs("Messi shot SPA10", "SPA10", 456, this.tokenIds[3])
    
    const balanceAfter = await this.Alice.getBalance()

    // expect (balanceBefore - balanceAfter).to.equal(this.nftPrice + this.additional)
    // console.log(balanceAfter.toString())
  })

  it("Payable mint fails: Only user can mint NFTs receiving payments", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mintToDibbsPayable(
      "Messi shot SPA10",
      "SPA10",
      467,
      this.nftPrice,
      { value: this.nftPrice + this.additional }
    ))
    .to.revertedWith("DibbsERC721Upgradeable: Dibbs shouldn't call payalble mint function")
  })

  it("Payable mint fails: token should have valid name", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).mintToDibbsPayable(
      "",
      "SPA10",
      467,
      this.nftPrice,
      { value: this.nftPrice + this.additional }
    ))
    .to.revertedWith("DibbsERC721Upgradeable: invalid token name")
  })

  it("Payable mint fails: token should have valid grade", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).mintToDibbsPayable(
      "Messi shot SPA10",
      "",
      467,
      this.nftPrice,
      { value: this.nftPrice + this.additional }
    ))
    .to.revertedWith("DibbsERC721Upgradeable: invalid token grade")
  })

  it("Payable mint fails: token should have valid grade", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).mintToDibbsPayable(
      "Messi shot SPA10",
      "SPA10",
      0,
      this.nftPrice,
      { value: this.nftPrice + this.additional }
    ))
    .to.revertedWith("DibbsERC721Upgradeable: invalid serial id")
  })

  it("Payable mint fails: payment should be greater than or equal to token price", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).mintToDibbsPayable(
      "Messi shot SPA10",
      "SPA10",
      799,
      this.nftPrice,
      { value: this.additional }
    ))
    .to.revertedWith("DibbsERC721Upgradeable: not enough token price")
  })

  it("Payable mint fails: should mint a NFT on Dibbs account with Alice", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.Alice).mintToDibbsPayable(
      "Messi shot SPA10",
      "SPA10",
      456,
      this.nftPrice,
      { value: this.nftPrice + this.additional }
    )).to.revertedWith("DibbsERC721Upgradeable: existing card token")
  })
})
