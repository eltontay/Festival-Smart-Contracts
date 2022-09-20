// SPDX-License-Identifier: MIT
// SettleMint.com , Elton Tay

pragma solidity ^0.8.9;

// Removed opensea, reserves, whitelist, royalty, freeze, batch
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./library/token/ERC721/extensions/ERC721MintPausable.sol";
// Additional import
import "./FestivalToken.sol";

contract FestivalNFT is
  ERC721Enumerable,
  ERC721Burnable,
  ERC721Pausable,
  ERC721MintPausable,
  Ownable,
  ReentrancyGuard
{
  //////////////////////////////////////////////////////////////////
  // CONFIGURATION                                                //
  //////////////////////////////////////////////////////////////////
  uint256 public constant PRICE = 10 * 10 ** 18; // Price per Festival NFT, set at 10 FTK
  uint256 public constant MAX_PER_TX = 5; // Limiting to 5 for family purchase of FNFTs
  uint256 public constant MAX_SUPPLY = 1000; // Total amount of FNFTs

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
  mapping(uint256 => TicketDetails) private _ticketDetails; // mapping structure of ticket to each ticket

  // events
  event PublicMint(address buyer, uint256 ticketId);
  event PurchaseListing(address buyer, address seller, uint256 sellingPrice, uint256 commissionPrice);
  event SetListing(address owner, uint256 ticketId, uint256 sellingPrice);
  event RemoveListing(address owner, uint256 ticketId);
  event AdjustListing(address owner, uint256 ticketId, uint256 sellingPrice);

  FestivalToken private _token;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseTokenURI_,
    FestivalToken token_
  ) ERC721(name_, symbol_) {
    _baseTokenURI = baseTokenURI_;
    _organiser = payable(_msgSender());
    _token = token_;
  }

  //////////////////////////////////////////////////////////////////
  // CORE FUNCTIONS                                               //
  //////////////////////////////////////////////////////////////////

  function setBaseURI(string memory baseTokenURI_) public onlyOwner  {
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
  ) internal override(ERC721) {
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
    require(count <= MAX_PER_TX, "Exceeds max per transaction");
    require(balanceOf(_msgSender()) + count <= MAX_PER_TX, "Exceeds maximum public minting");
    _token.transferFrom(_msgSender(),_organiser, count * PRICE); // Error will throw if insufficient funds

    for (uint256 i; i < count; i++) {
      _mint(_msgSender(), ++_tokenId);
      _ticketDetails[_tokenId] = TicketDetails({ // initialise structure to ticket
        ticketOwner: _msgSender(),
        currentPrice: PRICE,
        sellingPrice: 0,
        forSale: false
      });
      emit PublicMint(_msgSender(),_tokenId);
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

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    return
      interfaceId == type(Ownable).interfaceId ||
      interfaceId == type(ERC721Burnable).interfaceId ||
      interfaceId == type(ERC721Enumerable).interfaceId ||
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
    Modifier - Validate that the selling price does not exceed 110% (1.1x) more than the
    current price.
  */

  modifier checkSellingPrice(uint256 ticketId, uint256 sellingPrice) {
    uint256 currentPrice = _ticketDetails[ticketId].currentPrice;
    require(
      sellingPrice <= ((currentPrice * 110) / 100),
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
    require(value >= _ticketDetails[ticketId].sellingPrice, "Insufficient token for purchase.");
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

  function setListing(uint256 ticketId, uint256 sellingPrice_)
    public
    checkSellingPrice(ticketId, sellingPrice_)
    checkTicketIsOwner(ticketId, _msgSender())
    checkTicketNotOnSale(ticketId)
  {
    // Approving organiser
    approve(_organiser,ticketId);
    // Transferring of FNFT
    transferFrom(_msgSender(),_organiser, ticketId);
    // Setting ticket details
    _ticketDetails[ticketId].sellingPrice = sellingPrice_;
    _ticketDetails[ticketId].forSale = true;

    emit SetListing(_msgSender(),ticketId,sellingPrice_);
  }

  /*
    Remove ticket listing on secondary market.
    - Checks ticket owner is msg sender
    - Checks if ticket is on sale
  */

  function removeListing(uint256 ticketId)
    public
    checkTicketIsOwner(ticketId, _msgSender())
    checkTicketOnSale(ticketId)
  {
    // Transferring of FNFT
    transferFrom(_organiser,_msgSender(), ticketId);
    // Setting ticket details
    _ticketDetails[ticketId].sellingPrice = 0;
    _ticketDetails[ticketId].forSale = false;

    emit RemoveListing(_msgSender(),ticketId);
  }

  /*
    Adjust ticket listing on secondary market.
    - Checks selling price validity
    - Checks ticket owner is msg sender
    - Checks if ticket is on sale
  */

  function adjustListing(uint256 ticketId, uint256 sellingPrice_)
    public
    checkSellingPrice(ticketId, sellingPrice_)
    checkTicketIsOwner(ticketId, _msgSender())
    checkTicketOnSale(ticketId)
  {
    _ticketDetails[ticketId].sellingPrice = sellingPrice_;

    emit AdjustListing(_msgSender(),ticketId,sellingPrice_);
  }

  /*
    Buy ticket listing on secondary market.
    - Check sufficient buying power
    - Check ticket owner is not msg sender
    - Checks if ticket is on sale
  */

  function purchaseListing(uint256 ticketId, uint256 value)
    public
    payable
    checkSufficientValue(ticketId, value)
    checkTicketIsNotOwner(ticketId, _msgSender())
    checkTicketOnSale(ticketId)
  {
    address seller = _ticketDetails[ticketId].ticketOwner;
    uint256 sellingPrice = _ticketDetails[ticketId].sellingPrice;
    uint256 commissionPrice = (sellingPrice * commission) / 100;
    // Transferring of Tokens
    _token.transferFrom(_msgSender(), seller, sellingPrice - commissionPrice);
    if (commissionPrice > 0) {
      _token.transferFrom(_msgSender(), _organiser, commissionPrice);
    }

    // Transferring of NFT
    transferFrom(_organiser, _msgSender(), ticketId);

    // Adjust ticket details
    _ticketDetails[ticketId].ticketOwner = _msgSender();
    _ticketDetails[ticketId].currentPrice = sellingPrice;
    _ticketDetails[ticketId].forSale = false;

    emit PurchaseListing(_msgSender(),seller,sellingPrice,commissionPrice);
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
  // Getter Functions                                             //
  //////////////////////////////////////////////////////////////////

  function getCurrentPrice(uint256 ticketId) public view returns (uint256) {
    return _ticketDetails[ticketId].currentPrice;
  }

  function getSellingPrice(uint256 ticketId) public view returns (uint256) {
    return _ticketDetails[ticketId].sellingPrice;
  }

  function getForSale(uint256 ticketId) public view returns (bool) {
    return _ticketDetails[ticketId].forSale;
  }

}
