# Blockchain Festival

## Overview

Blockchain Festival is a web-based platform powered by Settlemint for buying and reselling of festival tickets using blockchain technology. By utilising blockchain technology, numerous issues can be eliminated : Scalping , Security and Data Collection. This platform is built on the public Ethereum blockchain with 2 smart contracts utilising the latest standards, where "FestivalNFT" follows the ERC721 standard and "FestivalToken" follows the ERC20 standard.

### Issues tackled

1. Scalping

Scalpers, an unwanted byproduct of the free market exists typically by buying in bulk and reselling them for ridiculous prices higher than the initial retail price. Despite morality reasons, scalpers are not illegalised in Singapore. This is because margins are determined by willing buyers and willing sellers. However, this is an issue which can damage the reputation of the organiser, as it prevents genuine customers from purchasing tickets. That is why, Blockchain Festival has enforced predefined rules in the smart contracts, which limits the amount of tickets a buyer can purchase, and the price the buyer can resell at. In this example, the limitation of resell price is capped at 110% from the previous price.

2. Security

Authenticity is an issue when you unknowingly purchased fake tickets. This can happen through phishing sites or through dubious resellers. Using blockchain technology, each ticket has its own unique identity which is transparent for all users to see, allowing easy verification of authenticity not just for the organiser, but for the public as well. Blockchain Festival verifies these transactions in the smart contracts listed on the blockchain.

3. Data Collection

Data collection is an important aspect for organisers to better understand their target audience to ensure a successful launch of their festival. With blockchain technology, every transaction is tracked and monitored. This gives not just ownership of data to the organiser but also detailed insights. With these insights, organisers will be able to analyse the data and use them to achieve more successful campaigns.

## Technical Details

### Smart Contract

There are 2 contracts listed under the `./contracts` directory.

1. **FestivalToken**
   - ERC20 Token, named FTK, which is used to transact festival tickets (FNFT).
2. **FestivalNFT**
   - ERC721 NFT, named FNFT, which is a representation of festival tickets.
   - Takes in an ERC20 Token as a parameter for transactions of tickets. In this case, FTK.

## How does it work?

### Creation of Festival Tokens

1. The organiser will first create FTK tokens for the public to transact with FNFT NFTs.

## More Information

- [Leverage the Graph Middleware to index on chain data](./docs/graph-middleware.md)
- [Collaborate with your colleagues over GitHub](./docs/collaborate-over-github.md)
- [Learn about the different tasks available for development](./docs/development-tasks.md)
- [What all the folders and files in this set are for](./docs/project-structure.md)
