const { expect } = require("chai")
const {ethers} = require("hardhat")

describe("DibbsERC1155", function() {
  before(async () => {
    const [masterMinter, Alice, Bob, Carl] = await ethers.getSigners()
    this.masterMinter = masterMinter
    this.Alice = Alice
    this.Bob = Bob
    this.Carl = Carl
    this.tokenIds = [1, 2, 3, 4, 5, 6, 7, 8]
    this.supply = 100
    this.tokenURI = "fakeTokenURI"

    const DibbsERC1155 = await ethers.getContractFactory("DibbsERC1155")
    this.dibbsERC1155 = await DibbsERC1155.deploy(
      "Dibbs1155",
      "DIBBS1155",
      "https://api-testnet.dibbs.co/contractMetadata/{address}",// contractURI
      "DIBBS_", // tokenURIPrefix
      "Dibbs_", // uri
    )
  })

  it("Deployment: name and symbol are set correctly", async () => {
    await this.dibbsERC1155.deployed()
    expect (await this.dibbsERC1155.name()).to.equal("Dibbs1155")
    expect (await this.dibbsERC1155.symbol()).to.equal("DIBBS1155")
  })

  it("Fractionalizing fails: owner address shoud be valid", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalize(
      ethers.constants.AddressZero,
      this.tokenIds[0],
      this.supply,
      this.tokenURI
    )).to.revertedWith("DibbsERC1155: invalid owner address")
  })

  it("Fractionalizing fails: supply should not be zero", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalize(
      this.Alice.address,
      this.tokenIds[0],
      0,
      this.tokenURI
    )).to.revertedWith("DibbsERC1155: invalid number of supply")
  })
  
  it("Fractionalizing fails: uri should exist", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalize(
      this.Alice.address,
      this.tokenIds[0],
      this.supply,
      ""
    )).to.revertedWith("DibbsERC1155: invalid uri string")
  })

  it("Fractionalizing succeeds: to Alice", async () => {
    await this.dibbsERC1155.connect(this.masterMinter).fractionalize(
      this.Alice.address,
      this.tokenIds[0],
      this.supply,
      this.tokenURI
    )
    
    expect(await this.dibbsERC1155.balanceOf(this.Alice.address, this.tokenIds[0])).to.equal(100)
  })

  it("Fractionalizing fails: tokens are already minted", async () => {
    await expect(this.dibbsERC1155.connect(this.masterMinter).fractionalize(
      this.Bob.address,
      this.tokenIds[0],
      this.supply,
      this.tokenURI
    )).to.revertedWith("DibbsERC1155: already minted")
  })

  it("Fractionalizing succeeds: to Bob", async () => {
    await this.dibbsERC1155.connect(this.masterMinter).fractionalize(
      this.Bob.address,
      this.tokenIds[1],
      this.supply,
      this.tokenURI
    )
    
    expect(await this.dibbsERC1155.balanceOf(this.Bob.address, this.tokenIds[1])).to.equal(100)
  })
  
})