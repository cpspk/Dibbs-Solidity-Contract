# Basic Sample Hardhat Project

This project is to build smart contracts for Dibbs marketplace using Solidity. In a nutshell, it implements minting Card token, fractionalizing, and Shotgun auction.

## DibbsERC721Upgradeable
- mint: only dibbs admin can mint NFT to a user.
- transferToken: user transfer token to the contract for fractionalization.
- burn: burn NFT(card token)
## DibbsERC1155
- fractionalize: only dibbs admin can fractionalize a NFT to user who sent it to contract. It is possible in case the NFT is locked in contract.
- transferFractions: user transfers fractions to the contract.
- burnFractions: burn fractions with id after defractionalizing.

## ShotgunAuction
- transferForShotgun: User sends at least 0.5*token_supply tokens(fractions) to the smart contract it gets stored as balance, and sends Ethers to the smart contract, it gets stored as balance. The tokens(fractions) are locked.
- startAuction: Dibbs admin start Shotgun auction after receiving amount of fractions and Ethers.
- purchase: Another user purchase the locked fractions with payment proportional to the amount.
- refundToken: If the auction expired(after 3 months), the auction starter will get the rest fractions and his sending fractions back.
- claminProportion: afer Shotgun auction terminated(), the other owners of the token(fractions) can claim their proportional share of the balance which the auction starter sent depending on the tokens they had before.

Try running some of the following tasks:

```compile and test
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat help
```

``` deploy and verify
npx hardhat run scripts/deploy.js --network TESTNET
npx hardhat verify CONTRACT ADDRESS [PARAMETERs]
```