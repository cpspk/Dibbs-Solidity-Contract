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

    const Admin = await ethers.getContractFactory("Admin")
    this.admin = await Admin.deploy("Admin", "AD", "https://Admin/");
  })

  it("Deployment: should return right name and symbol", async () => {
    await this.admin.deployed()

    expect(await this.admin.name()).to.equal("Admin")
    expect(await this.admin.symbol()).to.equal("AD")
  })

  it("Mint succeeds: should mint a NFT on Alice's account", async () => {
    await expect(this.admin.connect(this.masterMinter).mint(this.Alice.address, "Messi shot SPA10", "SPA10", 123))
      .emit(this.admin, "Minted")
      .withArgs(this.Alice.address, "Messi shot SPA10", "SPA10", 123)
  })

  it("Mint fails: no dibbs masterMinter should not mint NFTs", async () => {
    await expect(this.admin.connect(this.Alice).mint(this.Alice.address, "Messi Dribbling SPA10", "SPA10", 13445))
      .to.revertedWith("Admin: Only dibbs can mint NFTs")
  })

  it("Mint fails: should not mint the existing NFT on Alice's account", async () => {
    await expect(this.admin.connect(this.masterMinter).mint(this.Alice.address, "Messi shot SPA10", "SPA10", 123))
      .to.revertedWith("Admin: existing card token")
  })

  it("Mint fails: should not mint on invalid address", async () => {
    await expect(this.admin.connect(this.masterMinter).mint(ethers.constants.AddressZero, "Messi shot SPA10", "SPA10", 1223))
      .to.revertedWith("Admin: invalid recepient address")
  })

  it("Mint fails: should not mint card token without name", async () => {
    await expect(this.admin.connect(this.masterMinter).mint(this.Alice.address, "", "SPA10", 2123))
      .to.revertedWith("Admin: invalid token name")
  })

  it("Mint fails: should not mint card token without grade", async () => {
    await expect(this.admin.connect(this.masterMinter).mint(this.Alice.address, "Messi shot SPA10", "", 2123))
      .to.revertedWith("Admin: invalid token grade")
  })
})
