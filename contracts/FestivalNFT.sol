// SPDX-License-Identifier: MIT
// SettleMint.com , Elton Tay

pragma solidity ^0.8.9;

// Removed opensea, reserves, whitelist, royalty
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./library/token/ERC721/extensions/ERC721Freezable.sol";
import "./library/token/ERC721/extensions/ERC721MintPausable.sol";
import "./library/token/ERC721/extensions/ERC721Batch.sol";
// Additional import
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./FestivalToken.sol";

contract FestivalNFT is
  ERC721Enumerable,
  ERC721Burnable,
  ERC721Pausable,
  ERC721Freezable,
  ERC721MintPausable,
  ERC721Batch,
  Ownable,
  ReentrancyGuard
{
  //////////////////////////////////////////////////////////////////
  // CONFIGURATION                                                //
  //////////////////////////////////////////////////////////////////
  uint256 public constant PRICE = 10; // Price per Festival NFT
  uint256 public constant MAX_PER_TX = 5; // Limiting to 5 for family purchase of Festival NFTs
  uint256 public constant MAX_SUPPLY = 1000; // Total amount of Festival NFTs

  //////////////////////////////////////////////////////////////////
  // TOKEN STORAGE                                                //
  //////////////////////////////////////////////////////////////////

  uint256 private _tokenId;
  string private _baseTokenURI; // the IPFS url to the folder holding the metadata.

  //////////////////////////////////////////////////////////////////
  // CROWDSALE STORAGE                                            //
  //////////////////////////////////////////////////////////////////

  address payable private immutable _organiser; // address of the festival owner
  bool private _publicSaleOpen = false; // is the public sale open?

  //////////////////////////////////////////////////////////////////
  // FESTIVAL DETAILS                                             //
  //////////////////////////////////////////////////////////////////

  // Structure of each ticket
  struct TicketDetails {
    address ticketOwner;
    uint256 currentPrice;
    uint256 sellingPrice;
    bool forSale;
  }
  
  bool private monetisation = false; // default monetisation (commision) set to false
  uint256 private commission = 0; // default commission value set to 0
  address[] private buyers; // list of buyers
  uint256[] private ticketsOnSale; // list of tickets for sale
  mapping(address => uint256[]) private _purchasedTickets; // tracking specific address to tickets
  mapping(uint256 => TicketDetails) private _ticketDetails; // mapping structure of ticket to each ticket

  FestivalToken private _token;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseTokenURI_,
    address payable wallet_,
    FestivalToken token_
  ) ERC721(name_, symbol_) {
    _baseTokenURI = baseTokenURI_;
    _organiser = wallet_;
    _token = token_;
  }

  //////////////////////////////////////////////////////////////////
  // CORE FUNCTIONS                                               //
  //////////////////////////////////////////////////////////////////

  function setBaseURI(string memory baseTokenURI_) public onlyOwner whenURINotFrozen {
    _baseTokenURI = baseTokenURI_;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    string memory tokenUri = super.tokenURI(tokenId);
    return bytes(tokenUri).length > 0 ? string(abi.encodePacked(tokenUri, ".json")) : "";
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable, ERC721Pausable, ERC721MintPausable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Freezable) {
    super._afterTokenTransfer(from, to, tokenId);
  }

  //////////////////////////////////////////////////////////////////
  // PUBLIC SALE                                                  //
  //////////////////////////////////////////////////////////////////

  function startPublicSale() public onlyOwner {
    _publicSaleOpen = true;
  }

  function publicMint(uint256 count) public payable nonReentrant {
    require(_publicSaleOpen, "Public sale not active");
    require(_tokenId + count <= MAX_SUPPLY, "Exceeds max supply");
    require(count < MAX_PER_TX, "Exceeds max per transaction");
    _token.transferFrom(_msgSender(),_organiser,count * PRICE); // Error will throw if insufficient funds
    
    for (uint256 i; i < count; i++) {
      _mint(_msgSender(), ++_tokenId);
      _purchasedTickets[_msgSender()].push(_tokenId); // mapping token id to buyer
      _ticketDetails[_tokenId] = TicketDetails({ // initialise structure to ticket
        ticketOwner: _msgSender(),
        currentPrice: PRICE,
        sellingPrice: 0,
        forSale: false
      });
    }

  }

  //////////////////////////////////////////////////////////////////
  // POST SALE MANAGEMENT                                         //
  //////////////////////////////////////////////////////////////////

  function withdraw() public {
    _organiser.transfer(address(this).balance);
  }

  function wallet() public view returns (address) {
    return _organiser;
  }

  function _burn(uint256 tokenId) internal override(ERC721) {
    super._burn(tokenId);
  }

  function burn(uint256 tokenId) public override {
    _burn(tokenId);
  }

  function freeze() public onlyOwner {
    super._freeze();
  }

  //////////////////////////////////////////////////////////////////
  // Pausable & MintPausable                                      //
  //////////////////////////////////////////////////////////////////

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function pauseMint() public onlyOwner {
    _pauseMint();
  }

  function unpauseMint() public onlyOwner {
    _unpauseMint();
  }

  //////////////////////////////////////////////////////////////////
  // ERC165                                                       //
  //////////////////////////////////////////////////////////////////

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return
      interfaceId == type(Ownable).interfaceId ||
      interfaceId == type(ERC721Burnable).interfaceId ||
      interfaceId == type(ERC721Enumerable).interfaceId ||
      interfaceId == type(ERC721Freezable).interfaceId ||
      interfaceId == type(ERC721MintPausable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  //////////////////////////////////////////////////////////////////
  // Festival Functions                                           //
  //////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////
  // Modifier Functions                                           //
  //////////////////////////////////////////////////////////////////

  /*
    Modifier - Validate that the selling price does not exceed 110% more than the 
    current price.
  */

  modifier checkSellingPrice(uint256 ticketId, uint256 sellingPrice) {
     uint256 currentPrice = _ticketDetails[ticketId].currentPrice;  
     require(
        currentPrice + SafeMath.div(SafeMath.mul(currentPrice,110), 100) > sellingPrice,
        "Re-selling price is more than 110%"
    );
    _;     
  }

  /*
    Modifier - Check msg sender is ticket owner
  */

  modifier checkTicketIsOwner(uint256 ticketId, address ticketOwner) {
    address realOwner = _ticketDetails[ticketId].ticketOwner;
    require(realOwner == ticketOwner, "You are not the ticket owner.");    
    _;
  }

  /*
    Modifier - Check msg sender is not ticket owner
  */

  modifier checkTicketIsNotOwner(uint256 ticketId, address ticketOwner) {
    address realOwner = _ticketDetails[ticketId].ticketOwner;
    require(realOwner != ticketOwner, "You are the ticket owner.");    
    _;
  }

  /*
    Modifier - Check if ticket is on sale
  */

  modifier checkTicketOnSale(uint256 ticketId) {
    require(_ticketDetails[ticketId].forSale, "Ticket is not on sale.");
    _;
  }

  /*
    Modifier - Check if ticket is not on sale
  */

  modifier checkTicketNotOnSale(uint256 ticketId) {
    require(!_ticketDetails[ticketId].forSale, "Ticket is on sale.");
    _;
  }


  /*
    Modifier - Check if value is sufficient for ticket purchase
  */

  modifier checkSufficientValue(uint256 ticketId, uint256 value) {
    uint256 sellingPrice = _ticketDetails[ticketId].sellingPrice;
    require(value >= sellingPrice, "Insufficient token for purchase.");
    _;
  }

  //////////////////////////////////////////////////////////////////
  // Secondary Marketplace Functions                              //
  //////////////////////////////////////////////////////////////////

  /*
    List ticket on secondary market.
    - Checks selling price validity
    - Checks ticket owner is msg sender
    - Checks ticket is not on sale
  */

  function setListing(uint256 ticketId, uint256 sellingPrice_) public  
    checkSellingPrice(ticketId,sellingPrice_)
    checkTicketIsOwner(ticketId,_msgSender())
    checkTicketNotOnSale(ticketId)
  {
    _ticketDetails[ticketId].sellingPrice = sellingPrice_;
    _ticketDetails[ticketId].forSale = true;
    ticketsOnSale.push(ticketId);
  }

  /*
    Remove ticket listing on secondary market.
    - Checks ticket owner is msg sender
    - Checks if ticket is on sale
  */

  function removeListing(uint256 ticketId) public 
    checkTicketIsOwner(ticketId,_msgSender())
    checkTicketOnSale(ticketId)
  {
    _ticketDetails[ticketId].sellingPrice = 0;
    _ticketDetails[ticketId].forSale = false;
    removeTicketOnSale(ticketId);
  }

  /*
    Adjust ticket listing on secondary market.
    - Checks selling price validity
    - Checks ticket owner is msg sender
    - Checks if ticket is on sale
  */

  function adjustListing(uint256 ticketId, uint256 sellingPrice_) public 
    checkSellingPrice(ticketId,sellingPrice_)
    checkTicketIsOwner(ticketId,_msgSender())
    checkTicketOnSale(ticketId)
  {
    _ticketDetails[ticketId].sellingPrice = sellingPrice_;
  }


  /*
    Buy ticket listing on secondary market.
    - Check sufficient buying power
    - Check ticket owner is not msg sender
    - Checks if ticket is on sale
  */

  function purchaseListing(uint256 ticketId, uint256 value) public payable
    checkSufficientValue(ticketId,value)
    checkTicketIsNotOwner(ticketId,_msgSender())
    checkTicketOnSale(ticketId)
  {
    address payable seller = payable(_ticketDetails[ticketId].ticketOwner);
    address payable buyer = payable(_msgSender());
    uint256 sellingPrice = _ticketDetails[ticketId].sellingPrice;
    uint256 commissionPrice = SafeMath.div(SafeMath.mul(sellingPrice,commission),100);
    // Transferring of Tokens
    _token.transferFrom(buyer,seller,sellingPrice-commissionPrice);
    if (commissionPrice > 0) {
      _token.transferFrom(buyer,_organiser,commissionPrice);      
    }
    // Transferring of NFT
    transferFrom(seller,buyer,ticketId);
    // Adjusting lists
    removeTicketOnSale(ticketId);
    removeTicketFromPurchased(seller,ticketId);
    _purchasedTickets[buyer].push(_tokenId);
  }

  //////////////////////////////////////////////////////////////////
  // Owner Functions                                           //
  //////////////////////////////////////////////////////////////////

  /*
    Monetisation option
    Input in whole numbers - E.g. 10% = 10, 100% = 100
    Limitation range : 0 - 100
  */
  function monetise(uint256 commissionPercentage) public onlyOwner {
    commission = commissionPercentage;
  }

  //////////////////////////////////////////////////////////////////
  // Internal Functions                                           //
  //////////////////////////////////////////////////////////////////

  /*
    Internal - Remove ticket from ticket on sale list
  */

  function removeTicketOnSale(uint256 ticketId) internal {
      uint256 numOfTickets = ticketsOnSale.length;

      for (uint256 i = 0; i < numOfTickets; i++) {
          if (ticketsOnSale[i] == ticketId) {
              for (uint256 j = i + 1; j < numOfTickets; j++) {
                  ticketsOnSale[j - 1] = ticketsOnSale[j];
              }
              ticketsOnSale.pop();
          }
      }
  }

  /*
    Internal - Remove ticket from purchased list
  */
  
   
  function removeTicketFromPurchased(address person, uint256 ticketId) internal {
      uint256 numOfTickets = _purchasedTickets[person].length;

      for (uint256 i = 0; i < numOfTickets; i++) {
          if (_purchasedTickets[person][i] == ticketId) {
              for (uint256 j = i + 1; j < numOfTickets; j++) {
                  _purchasedTickets[person][j - 1] = _purchasedTickets[
                      person
                  ][j];
              }
              _purchasedTickets[person].pop();
          }
      }
  }

  //////////////////////////////////////////////////////////////////
  // Getter Functions                                             //
  //////////////////////////////////////////////////////////////////



}
