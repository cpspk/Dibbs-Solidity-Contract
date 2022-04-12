# Basic Sample Hardhat Project

This project is to build smart contracts for Dibbs marketplace using Solidity. In a nutshell, it implements minting Card token, fractionalizing, and Shotgun auction.

## DibbsERC721Upgradeable
- mint: only dibbs admin can mint NFT to a user(1).
- transferToken: user transfer token to the contract for fractionalization(2).
- burn: burn NFT(card token)
## DibbsERC1155
- fractionalize: only dibbs admin can fractionalize a NFT to user who sent it to contract. It is possible in case the NFT is locked in contract(3).
- defractionalize: only if caller has all amount of fractions.
- transferFractions: user transfers fractions to the contract(4).
- burnFractions: burn fractions with id after defractionalizing.

## ShotgunAuction(5)
- registerOwnersWithTokenId: register fraction owner who will participate in the auction and specific token id.
- transferForShotgun: User sends at least 0.5*token_supply tokens(fractions) to the smart contract it gets stored as balance, and sends Ethers to the smart contract, it gets stored as balance. The tokens(fractions) are locked.
- startAuction: Dibbs admin start Shotgun auction after receiving amount of fractions and Ethers.
- refundToken: If the auction expired(after 3 months), the auction starter will get the rest fractions and his sending fractions back.
- claminProportion: after Shotgun auction terminated(the case which another user purchases), the other owners of the token(fractions) can claim their proportional share of the balance which the auction starter sent depending on the tokens they had before.
- Initialize: initialize all state variables for new auction.
- withdrawTo: withdraw ethers locked in the contract.

Try running some of the following tasks:

```compile and test
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat help
```

``` deploy and verify
npx hardhat run scripts/deploy.js --network TESTNET(e.g matic)
npx hardhat verify CONTRACT ADDRESS [PARAMETERs]
```