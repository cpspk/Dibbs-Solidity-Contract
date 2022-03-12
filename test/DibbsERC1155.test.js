const { expect } = require("chai")
const {ethers} = require("hardhat")

describe("DibbsERC1155", function() {
  before(async () => {
    const [masterMinter, Alice, Bob, Carl] = await ethers.getSigners()
    this.masterMinter = masterMinter
    this.Alice = Alice
    this.Bob = Bob
    this.Carl = Carl
    this.tokenIds = [0, 1, 2, 3, 4, 5, 6, 7, 8]
    this.supply = 100
    this.tokenURI = "fakeTokenURI"
    
    const DibbsERC721Upgradeable = await ethers.getContractFactory("DibbsERC721Upgradeable")
    this.dibbsERC721Upgradeable = await DibbsERC721Upgradeable.deploy();

    const DibbsERC1155 = await ethers.getContractFactory("DibbsERC1155")
    this.dibbsERC1155 = await DibbsERC1155.deploy(
      this.dibbsERC721Upgradeable.address,
      "https://api-testnet.dibbs.co/contractMetadata/"
    )
  })

  it("Deployment: name and symbol are set correctly", async () => {
    await this.dibbsERC1155.deployed()
    await this.dibbsERC721Upgradeable.initialize("https://dibbs/")
  })

  it("Mint succeeds: should mint a NFT on Alice's account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mint(this.dibbsERC721Upgradeable.address, "Messi shot SPA10", "SPA10", 123))
    .emit(this.dibbsERC721Upgradeable, "Minted")
    .withArgs(this.dibbsERC721Upgradeable.address, "Messi shot SPA10", "SPA10", 123, this.tokenIds[0])
  })

  it("Mint succeeds: should mint a NFT on Alice's account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mint(this.dibbsERC721Upgradeable.address, "Messi shot SPA10", "SPA10", 124))
    .emit(this.dibbsERC721Upgradeable, "Minted")
    .withArgs(this.dibbsERC721Upgradeable.address, "Messi shot SPA10", "SPA10", 124, this.tokenIds[1])
  })

  it("Fractionalizing fails: owner address shoud be valid", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalize(
      ethers.constants.AddressZero,
      this.tokenIds[0],
    )).to.revertedWith("DibbsERC1155: invalid to address")
  })

  it("Fractionalizing succeeds: to Alice", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalize(
      this.Alice.address,
      this.tokenIds[0],
    )).emit(this.dibbsERC1155, "Fractionalized")
      .withArgs(this.Alice.address, this.tokenIds[0])
  })

  it("Fractionalizing fails: tokens are already minted", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalize(
      this.Bob.address,
      this.tokenIds[0],
    )).to.revertedWith("DibbsERC1155: this token is already fractionalized")
  })

  it("Fractionalizing succeeds: to Bob", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalize(
      this.Bob.address,
      this.tokenIds[1],
    )).emit(this.dibbsERC1155, "Fractionalized")
    .withArgs(this.Bob.address, this.tokenIds[1])
  })
})