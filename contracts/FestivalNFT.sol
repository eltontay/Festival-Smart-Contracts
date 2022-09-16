// SPDX-License-Identifier: MIT
// SettleMint.com , Elton Tay

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "./library/token/ERC721/extensions/ERC721Freezable.sol";
import "./library/token/ERC721/extensions/ERC721MintPausable.sol";
import "./library/token/ERC721/extensions/ERC721Batch.sol";

// Removed opensea import , reserves for owner, whitelist

contract FestivalNFT is
  ERC721Enumerable,
  ERC721Burnable,
  ERC721Pausable,
  ERC721Freezable,
  ERC721MintPausable,
  ERC721Batch,
  ERC721Royalty,
  Ownable,
  ReentrancyGuard
{
  //////////////////////////////////////////////////////////////////
  // CONFIGURATION                                                //
  //////////////////////////////////////////////////////////////////
  uint256 public constant PRICE = 10; // Price per Festival NFT
  uint96 public constant ROYALTIES_IN_BASIS_POINTS = 500; // 5% royalties , leaving this as default
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

  address payable private immutable _festivalWallet; // address of the festival owner
  mapping(address => uint256) private _addressToMinted; // the amount of tokens an address has minted
  bool private _publicSaleOpen = false; // is the public sale open?

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseTokenURI_,
    address payable wallet_
  ) ERC721(name_, symbol_) {
    _baseTokenURI = baseTokenURI_;
    _festivalWallet = wallet_;
    _setDefaultRoyalty(wallet_, ROYALTIES_IN_BASIS_POINTS);
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

  function startPublicSale() external onlyOwner {
    _publicSaleOpen = true;
  }

  // Changing function to external for Festival Marketplace
  function publicMint(uint256 count) external payable nonReentrant {
    require(_publicSaleOpen, "Public sale not active");
    require(_tokenId > 0, "Reserves not taken yet");
    require(_tokenId + count <= MAX_SUPPLY, "Exceeds max supply");
    require(count < MAX_PER_TX, "Exceeds max per transaction");
    require(count * PRICE == msg.value, "Invalid funds provided");

    for (uint256 i; i < count; i++) {
      _mint(_msgSender(), ++_tokenId);
    }
  }

  //////////////////////////////////////////////////////////////////
  // POST SALE MANAGEMENT                                         //
  //////////////////////////////////////////////////////////////////

  function withdraw() public {
    _festivalWallet.transfer(address(this).balance);
  }

  function wallet() public view returns (address) {
    return _festivalWallet;
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
    super._burn(tokenId);
  }

  function burn(uint256 tokenId) public override {
    _burn(tokenId);
  }

  function freeze() external onlyOwner {
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
    override(ERC721, ERC721Enumerable, ERC721Royalty)
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
}
