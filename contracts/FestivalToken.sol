// SPDX-License-Identifier: MIT
// SettleMint.com

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title GenericToken
 * @notice This contract is a generic token adhering to the ERC20 standard,
 *  using the OpenZeppelin template libary for battletested functionality.
 *
 *  It incorporates the standard ERC20 functions, enhanced with Minting
 *  and Burning, Pausable in case of emergencies and AccessControl for locking
 *  down the administrative functions.
 *
 *  For demonstrative purposes, 1 million GT tokens are pre-mined to the address
 *  deploying this contract.
 */
contract FestivalToken is ERC165, ERC20, ERC20Burnable, Pausable, AccessControl {
  constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _mint(msg.sender, 1000000 * 10**decimals());
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, AccessControl) returns (bool) {
    return
      interfaceId == type(IERC20).interfaceId ||
      interfaceId == type(ERC20Burnable).interfaceId ||
      interfaceId == type(Pausable).interfaceId ||
      super.supportsInterface(interfaceId); // ERC165, AccessControl
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   * - The sender of the transaction must have the DEFAULT_ADMIN_ROLE
   */
  function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   * - The sender of the transaction must have the DEFAULT_ADMIN_ROLE
   */
  function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing the total supply.
   *
   * Emits a Transfer event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `msg.sender` needs the DEFAULT_ADMIN_ROLE.
   *
   * @param to           The address to mint the new tokens into
   * @param amount       The amount of tokens to mint, denominated by the decimals() function
   */
  function mint(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _mint(to, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the total supply.
   *
   * Emits a Transfer event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   *
   * @param amount       The amount of tokens to burn from the sender of the transaction, denominated by the decimals() function
   */
  function burn(uint256 amount) public virtual override {
    _burn(_msgSender(), amount);
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens will be transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of `from`'s tokens will be burned.
   * - `from` and `to` are never both zero.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}
