require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4"
  // defaultNetwork: "rinkeby",
  // networks: {
  //   hardhat: {
  //   },
  //   rinkeby: {
  //     url: "https://eth-rinkeby.alchemyapi.io/v2/O5qM_FikSoa7bFkXG0TG8Yka4B5biVux",
  //     accounts: ['d08baa7f60eea18e4bac1c13a3b2328e699ba47d550743b903218289cd153c12']
  //   }
  // },
  // paths: {
  //   sources: "./contracts",
  //   tests: "./test",
  //   cache: "./cache",
  //   artifacts: "./artifacts"
  // },
  // etherscan: {
  //   apiKey: "JQ6MUG6MPM1RBZAGKW48D47VJDXKNWSRQV"
  // },
  // mocha: {
  //   timeout: 40000
  // }
};
