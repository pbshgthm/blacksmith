// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FooToken is ERC20 {
    constructor() ERC20("FooToken", "FOO") {
        _mint(msg.sender, 1000);
    }
}

contract BarToken is ERC20 {
    constructor() ERC20("BarToken", "BAR") {
        _mint(msg.sender, 1000);
    }
}
