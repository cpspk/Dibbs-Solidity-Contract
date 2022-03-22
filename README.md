# Basic Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts.

## DibbsERC721Upgradeable
- mint: only dibbs admin can mint NFT to a user.
- transferToken: user transfer token to the contract for fractionalization.
## DibbsERC1155
- fractionalize: only dibbs admin can fractionalize a NFT to user who sent it to contract. It is possible in case the NFT is locked in contract.
- transferFractions: user transfers fractions to the contract.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```
