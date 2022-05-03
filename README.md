# Dibbs Solidity Smart Contract

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
``` Shotgun logic
- 1 NFT
- -> gets fractionalized
- 1.0000000 tokens
- send 0.6 to userA
- send 0.1 to userB
- send 0.3 to userC


- userA wants the full asset, and will bid 5 eth
- userA sends his tokens (0.6) + `5 / 10 * 4` (2 eth) to the smart contract
- userA's tokens + userA's eth are locked up for 3 months

during those 3 months, this can happen to stop the shotgun:
- any user can come in, and buy userA's tokens at the valuation they offered
- userX sends 3 eth to the smart contract taking up that offer
	- userA will receive 3 eth
	- userX will receive the 0.6 tokens
	- the shotgun will be finished

if 3 month pass:
- the fractions can no longer be transferred
- userB and userC can redeem their 0.1 and 0.3 for their fraction of the 2 eth that userA put up
- userA gets the nft
```

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