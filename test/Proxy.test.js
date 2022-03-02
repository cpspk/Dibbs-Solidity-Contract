const chai = require("chai")
const { expect } = require("chai")
const { solidity } = require("ethereum-waffle")
const { artifacts, ethers } = require("hardhat");

chai.use(solidity)

describe("Proxy", function () {
  it("works", async function () {
    const Proxy = await ethers.getContractFactory("UnstructuredProxy")
    const LogicV1 = await ethers.getContractFactory("LogicV1")
    const LogicV2 = await ethers.getContractFactory("LogicV2")
    const [alice, bob, carl] = await ethers.getSigners()

    const proxy = await Proxy.deploy()
    const logicV1 = await LogicV1.deploy()
    const logicV2 = await LogicV2.deploy()

    await proxy.deployed()
    await logicV1.deployed()
    await logicV2.deployed()

    await logicV1.initialize()
    await logicV2.initialize()
    
    await proxy.upgradeTo(logicV1.address)
    expect(await proxy.implementation())
      .to.equal(logicV1.address)
    
    const { abi: abiV1 } = await artifacts.readArtifact("LogicV1")
    const { abi: abiV2 } = await artifacts.readArtifact("LogicV2")

    let ProxyUpgraded = new ethers.Contract(proxy.address, abiV1, ethers.getDefaultProvider());
    let proxyUpgraded = await ProxyUpgraded.connect(alice)

    // check first logic contract
    await proxyUpgraded.set(3);
    await logicV2.setAnotherData(5);

    expect(await proxyUpgraded.data()).to.equal(3);

    // check transferProxyOwnership()
    await proxy.transferProxyOwnership(bob.address)
    await expect(proxy.upgradeTo(logicV2.address))
      .to.be.revertedWith("Not Proxy owner")

    // switch to new proxy owner bob
    const proxyWithBob = await proxy.connect(bob)
    await proxyWithBob.upgradeTo(logicV2.address)

    // connect second version of logic contract
    ProxyUpgraded = new ethers.Contract(proxy.address, abiV2, ethers.getDefaultProvider());
    proxyUpgraded = await ProxyUpgraded.connect(alice)
    proxyUpgraded.initialize()
  })
})
