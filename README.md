# Blockchain Festival

## Overview

> Blockchain Festival is a web-based platform powered by Settlemint for buying and reselling of festival tickets using blockchain technology. By utilising blockchain technology, numerous issues can be eliminated : Scalping , Security and Data Collection. This platform is built on the public Ethereum blockchain with 2 smart contracts utilising the latest standards, where *"FestivalNFT"* follows the ERC721 standard and *"FestivalToken"* follows the ERC20 standard.

### Issues tackled

1. **Scalping**

   > Scalpers, an unwanted byproduct of the free market exists typically by buying in bulk and reselling them for ridiculous prices higher than the initial retail price. Despite morality reasons, scalpers are not illegalised in Singapore. This is because margins are determined by willing buyers and willing sellers. However, this is an issue which can damage the reputation of the organiser, as it prevents genuine customers from purchasing tickets. That is why, Blockchain Festival has enforced predefined rules in the smart contracts, which limits the amount of tickets a buyer can purchase, and the price the buyer can resell at. In this example, the limitation of resell price is capped at 110% from the previous price.

2. **Security**

   > Authenticity is an issue when you unknowingly purchased fake tickets. This can happen through phishing sites or through dubious resellers. Using blockchain technology, each ticket has its own unique identity which is transparent for all users to see, allowing easy verification of authenticity not just for the organiser, but for the public as well. Blockchain Festival verifies these transactions in the smart contracts listed on the blockchain.

3. **Data Collection**

   > Data collection is an important aspect for organisers to better understand their target audience to ensure a successful launch of their festival. With blockchain technology, every transaction is tracked and monitored. This gives not just ownership of data to the organiser but also detailed insights. With these insights, organisers will be able to analyse the data and use them to achieve more successful campaigns.

#
## Technical Details

### Smart Contracts

There are 2 contracts listed under the `./contracts` directory.

- **FestivalToken**
   - ERC20 Token, named FTK, which is used to transact festival tickets (FNFT).
- **FestivalNFT**
   - ERC721 NFT, named FNFT, which is a representation of festival tickets.
   - Takes in an ERC20 Token as a parameter for transactions of tickets. In this case, FTK.

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

- When listing of FNFT on the secondary market, the owner's FNFT will be transfered to the FNFT contract to act as an escrow.
- The owner can list the selling price to no more than 110% of the previous price.

#### Adjusting listing of FNFT on Secondary Market

- The owner can adjust the selling price of the listed FNFT.

#### Remove listing of FNFT on Secondary Market

- When removing of FNFT from the secondary market, the owner's FNFT will be transfered back from the FNFT contract to the owner.

#### Purchase of FNFT on the Secondary Market

- When the customer wants to buy a FNFT on the secondary marketplace, the FNFT contract will first `approve()` the customer before the customer is 


### Explanation through HardHat Testing

The tests are listed under the `./test` directory.

In your Settlemint Smart Contract Terminal run the following commands :

```bash
npm run test
```

## More Information

- [Leverage the Graph Middleware to index on chain data](./docs/graph-middleware.md)
- [Collaborate with your colleagues over GitHub](./docs/collaborate-over-github.md)
- [Learn about the different tasks available for development](./docs/development-tasks.md)
- [What all the folders and files in this set are for](./docs/project-structure.md)
