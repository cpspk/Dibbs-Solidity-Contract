const { expect } = require("chai")
const {ethers} = require("hardhat")

describe("Admin", function() {
  before(async () => {
    const users = await ethers.getSigners()
    const [masterMinter, Alice, Bob, Carl] = users
    this.masterMinter = masterMinter
    this.Alice = Alice
    this.Bob = Bob
    this.Carl = Carl

    const DibbsERC1155 = await ethers.getContractFactory("DibbsERC1155")
    this.dibbsERC1155 = await DibbsERC1155.deploy(
      "Dibbs1155",
      "DIBBS1155",
      "https://api-testnet.dibbs.co/contractMetadata/{address}",// contractURI
      "DIBBS_", // tokenURIPrefix
      "Dibbs_", // uri
    )

    const Admin = await ethers.getContractFactory("Admin")
    this.admin = await Admin.deploy();
  })

  it("Deployment: initialize Admin contract", async () => {
    await this.admin.initialize( this.dibbsERC1155.address, "https://dibbs/")
  })

  it("Mint succeeds: should mint a NFT on Alice's account", async () => {
    await expect(this.admin.connect(this.masterMinter).mintAndFractionalize(this.Alice.address, "Messi shot SPA10", "SPA10", 123))
      .emit(this.admin, "Minted")
      .withArgs(this.Alice.address, "Messi shot SPA10", "SPA10", 123)
  })

  it("Mint succeeds: should mint another one NFT on Alice's account", async () => {
    await expect(this.admin.connect(this.masterMinter).mintAndFractionalize(this.Alice.address, "Messi shot SPA10", "SPA10", 124))
      .emit(this.admin, "Minted")
      .withArgs(this.Alice.address, "Messi shot SPA10", "SPA10", 124)
  })

  it("Mint fails: no dibbs masterMinter should not mint NFTs", async () => {
    await expect(this.admin.connect(this.Alice).mintAndFractionalize(this.Alice.address, "Messi Dribbling SPA10", "SPA10", 13445))
      .to.revertedWith("Admin: Only dibbs can mint NFTs")
  })

  it("Mint fails: should not mint the existing NFT on Alice's account", async () => {
    await expect(this.admin.connect(this.masterMinter).mintAndFractionalize(this.Alice.address, "Messi shot SPA10", "SPA10", 123))
      .to.revertedWith("Admin: existing card token")
  })

  it("Mint fails: should not mint on invalid address", async () => {
    await expect(this.admin.connect(this.masterMinter).mintAndFractionalize(ethers.constants.AddressZero, "Messi shot SPA10", "SPA10", 1223))
      .to.revertedWith("Admin: invalid recepient address")
  })

  it("Mint fails: should not mint card token without name", async () => {
    await expect(this.admin.connect(this.masterMinter).mintAndFractionalize(this.Alice.address, "", "SPA10", 2123))
      .to.revertedWith("Admin: invalid token name")
  })

  it("Mint fails: should not mint card token without grade", async () => {
    await expect(this.admin.connect(this.masterMinter).mintAndFractionalize(this.Alice.address, "Messi shot SPA10", "", 2123))
      .to.revertedWith("Admin: invalid token grade")
  })
})
