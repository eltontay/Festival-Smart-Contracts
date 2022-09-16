// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./FestivalNFT.sol";
import "./FestivalToken.sol";

contract FestivalMarketplace {
  FestivalNFT private _festivalNFT;
  FestivalToken private _festivalToken;

  address private _festivalOwner;

  constructor(FestivalNFT festivalNFT, FestivalToken festivalToken) {
    _festivalNFT = festivalNFT;
    _festivalToken = festivalToken;
    _festivalOwner = _festivalNFT.wallet();
  }

  function purchaseTicket(uint256 count) public payable {
    _festivalToken.transferFrom(msg.sender,_festivalOwner,count*_festivalNFT.getPRICE())
    _festivalNFT.publicMint(count);
  }

  function secondaryPurchase()
}
