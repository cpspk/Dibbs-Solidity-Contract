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
    this.tokenURI = "fakeTokenURI"
    this.nftPrice = ethers.utils.parseEther("0.06")
    this.additional = ethers.utils.parseEther("0.00000000000000001")
    
    const DibbsERC721Upgradeable = await ethers.getContractFactory("DibbsERC721Upgradeable")
    this.dibbsERC721Upgradeable = await DibbsERC721Upgradeable.deploy();

    const DibbsERC1155 = await ethers.getContractFactory("DibbsERC1155")
    this.dibbsERC1155 = await DibbsERC1155.deploy(
      this.dibbsERC721Upgradeable.address,
      "https://api-testnet.dibbs.co/contractMetadata/"
    )
  })

  it("Initialize", async () => {
    await this.dibbsERC1155.deployed()
    await this.dibbsERC721Upgradeable.initialize("https://dibbs/")
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

  it("Mint succeeds: should mint a NFT on Dibbs account", async () => {
    await expect(this.dibbsERC721Upgradeable.connect(this.masterMinter).mintToDibbs("Messi shot SPA10", "SPA10", 126, this.nftPrice))
    .emit(this.dibbsERC721Upgradeable, "Minted")
    .withArgs("Messi shot SPA10", "SPA10", 126, this.tokenIds[3])
  })

  it("Fractionalizing to a user fails: owner address shoud be valid", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalizeToUser(
      ethers.constants.AddressZero,
      this.tokenIds[0],
    )).to.revertedWith("DibbsERC1155: invalid to address")
  })

  it("Fractionalizing to a user succeeds: to Alice", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalizeToUser(
      this.Alice.address,
      this.tokenIds[0],
    )).emit(this.dibbsERC1155, "Fractionalized")
      .withArgs(this.Alice.address, this.tokenIds[0])
  })

  it("Fractionalizing to a user fails: tokens are already minted", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalizeToUser(
      this.Bob.address,
      this.tokenIds[0],
    )).to.revertedWith("DibbsERC1155: this token is already fractionalized")
  })

  it("Fractionalizing to a user succeeds: to Bob", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalizeToUser(
      this.Bob.address,
      this.tokenIds[1],
    )).emit(this.dibbsERC1155, "Fractionalized")
    .withArgs(this.Bob.address, this.tokenIds[1])
  })

  it("Fractionalizing to Dibbs succeeds", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalizeToDibbs(this.tokenIds[2]))
      .emit(this.dibbsERC1155, "Fractionalized")
      .withArgs(this.masterMinter.address, this.tokenIds[2])
  })

  it("Fractionalizing to Dibbs fails", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalizeToDibbs(this.tokenIds[2]))
      .to.revertedWith("DibbsERC1155: this token is already fractionalized")
  })

  it("Fractionalizing to Dibbs succeeds", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalizeToDibbs(this.tokenIds[3]))
      .emit(this.dibbsERC1155, "Fractionalized")
      .withArgs(this.masterMinter.address, this.tokenIds[3])
  })
})
