# Blockchain Festival (Smart Contracts)

## Overview

> Blockchain Festival is a web-based platform powered by Settlemint for buying and reselling of festival tickets using blockchain technology. This platform is built on the public Ethereum blockchain with 2 smart contracts utilising the latest standards, where _"FestivalNFT"_ follows the ERC721 standard and _"FestivalToken"_ follows the ERC20 standard.

#

## Technical Details

### Smart Contracts

There are 2 contracts listed under the `./contracts` directory.

- **FestivalToken**
  - ERC20 Token, named FTK, which is used to transact festival tickets (FNFT).
- **FestivalNFT**
  - ERC721 NFT, named FNFT, which is a representation of festival tickets.
  - Takes in an ERC20 Token as a parameter for transactions of tickets. In this case, FTK.

### Deployment of Smart Contract

Since the Ethereum Merge, Ethereum Testnet does not support Rinkeby, Kovan or Ropsten. Therefore, as of 5 October 2022, Goerli testnet will be used for the deployment of this project.

You can view the contracts here

- **FestivalToken**

```bash
https://goerli.etherscan.io/token/0x32c2e50014417da4516fb78d683c574d38c0b37d
```

- **FestivalNFT**

```bash
https://goerli.etherscan.io/token/0x52e18abefb44e0ceb543ecb0935d5c42c6b2f233
```

#

## How does it work?

#### Creation of FTK

- The organiser has an initial supply of 1,000,000 FTKs.
- The organiser can either `transfer()` these FTKs or allow the public to `mint()` these FTKs.

#### Creation of FNFT

- There is a maximum cap of 1000 FNFTs.
- The organiser can initiate the sale of tickets with `startPublicSale()`.
- FNFTs can only be purchased with FTKs.
- The public can buy up to a maximum of 5 FNFTs at a fixed price of 10 FTKs.
- The public can buy/sell at a secondary market at a price not higher than 110% of the previous sale.
- The organiser is able to add a monetisation option in the secondary market.

#### Public purchase of FNFT

- Before the purchase of FNFT, the buyer must first `approve()` the FNFT contract to transact in FTKs. Next the buyer can purchase up to 5 FNFTs with `publicMint()`

#### Listing of FNFT on Secondary Market

- Before listing FNFT on the secondary market, the owner has to first `approve()` to the FNFT contract to transact the FNFT on the owner's behalf using `setListing()`
- The owner can list the selling price to no more than 110% of the previous price.
- Depending on the commission amount set by the organiser, the FNFT's owner will receive back the selling price less the commission, upon successful sale of the FNFT.

#### Adjusting listing of FNFT on Secondary Market

- The owner can adjust the selling price of the listed FNFT with `adjustListing()`

#### Removing listing of FNFT on Secondary Market

- The owner can remove listed FNFT with `removeListing()`

#### Purchase of FNFT on the Secondary Market

- A customer can purchase a FNFT using `purchaseListing()`

### Explanation through HardHat Testing

The tests are listed under the `./test` directory.

In your Settlemint Smart Contract Terminal run the following commands :

```bash
npm run test
```

## Deployment on Remix IDE

1. Open up https://remix.ethereum.org
2. -connect to localhost-
3. run `remixd -s ~/directory-of-files
4. compile using solidity version 0.8.9
5. change environment injected provider
6. deploy FestivalToken smart contract
7. deploy FestivalNFT smart contract 

## Deployment on Settlemint

Before Deployment, ensure that you have set up a private key in Settlemint.
In your Settlemint Smart Contract Terminal run the following command :

```bash
npm run smartcontract:deploy
```
