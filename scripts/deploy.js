const { ethers } = require("hardhat")

async function main() {

  const DibbsERC721Upgradeable = await ethers.getContractFactory("DibbsERC721Upgradeable");
  const dibbsERC721Upgradeable = await DibbsERC721Upgradeable.deploy()
  await dibbsERC721Upgradeable.initialize()
  console.log("DibbsERC721Upgradeable Address: ", dibbsERC721Upgradeable.address);
  
  const Proxy = await ethers.getContractFactory("UnstructuredProxy")
  const proxy = await Proxy.deploy()
  console.log("Proxy", proxy.address)

  const DibbsERC1155 = await ethers.getContractFactory("DibbsERC1155");
  const dibbsERC1155 = await DibbsERC1155.deploy(
    dibbsERC721Upgradeable.address,
    "https://dibbs1155/"
  );
  console.log("DibbsERC1155 Address: ", dibbsERC1155.address);

  const Shotgun = await ethers.getContractFactory("Shotgun");
  const shotgun = await Shotgun.deploy(dibbsERC721Upgradeable.address, dibbsERC1155.address);
  console.log("Shotgun address:", shotgun.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
