const { expect } = require("chai")
const {ethers} = require("hardhat")

describe("CardToken", function() {
  before(async () => {
    const users = await ethers.getSigners()
    const [Admin, Alice, Bob, Carl] = users
    this.Admin = Admin
    this.Alice = Alice
    this.Bob = Bob
    this.Carl = Carl

    const CardToken = await ethers.getContractFactory("CardToken")
    this.cardToken = await CardToken.deploy("CardToken", "CT", "https://CardToken/");
  })

  it("Deployment: should return right name and symbol", async () => {
    await this.cardToken.deployed()

    expect(await this.cardToken.name()).to.equal("CardToken")
    expect(await this.cardToken.symbol()).to.equal("CT")
  })

  it("Mint succeeds: should mint a NFT on Alice's account", async () => {
    await expect(this.cardToken.connect(this.Admin).mint(this.Alice.address, "Messi shot SPA10", "SPA10", 123))
      .emit(this.cardToken, "Minted")
      .withArgs(this.Alice.address, "Messi shot SPA10", "SPA10", 123)
  })

  it("Mint fails: should not mint the existing NFT on Alice's account", async () => {

    await expect(this.cardToken.connect(this.Admin).mint(this.Alice.address, "Messi shot SPA10", "SPA10", 123))
      .to.revertedWith("CardToken: existing card token")
  })
})
