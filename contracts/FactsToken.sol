// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract FactsToken is ERC20, ERC20Burnable {
  uint256 private burnPercent = 5000; // in bips

  uint256 private constant _INITIAL_SUPPLY = 2000000000000 * 10**18;

  constructor() ERC20("FACTIIV", "FACTS") {
    _mint(msg.sender, _INITIAL_SUPPLY);
  }
}
