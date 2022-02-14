// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./Blacksmith.sol";
import "../../Token.sol";

contract BarTokenBS {
    Bsvm constant bsvm = Bsvm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    address addr;
    uint256 privateKey;
    address payable target;
    
    constructor( address _addr, uint256 _privateKey, address _target) {
        addr = _privateKey == 0 ? _addr : bsvm.addr(_privateKey);
        privateKey = _privateKey;
        target = payable(_target);
    }

    modifier prank() {
        bsvm.startPrank(addr, addr);
        _;
    }

    function allowance(address owner, address spender) public prank returns (uint256) {
        return BarToken(target).allowance(owner, spender);
    }

	function approve(address spender, uint256 amount) public prank returns (bool) {
        return BarToken(target).approve(spender, amount);
    }

	function balanceOf(address account) public prank returns (uint256) {
        return BarToken(target).balanceOf(account);
    }

	function decimals() public prank returns (uint8) {
        return BarToken(target).decimals();
    }

	function decreaseAllowance(address spender, uint256 subtractedValue) public prank returns (bool) {
        return BarToken(target).decreaseAllowance(spender, subtractedValue);
    }

	function increaseAllowance(address spender, uint256 addedValue) public prank returns (bool) {
        return BarToken(target).increaseAllowance(spender, addedValue);
    }

	function name() public prank returns (string memory) {
        return BarToken(target).name();
    }

	function symbol() public prank returns (string memory) {
        return BarToken(target).symbol();
    }

	function totalSupply() public prank returns (uint256) {
        return BarToken(target).totalSupply();
    }

	function transfer(address to, uint256 amount) public prank returns (bool) {
        return BarToken(target).transfer(to, amount);
    }

	function transferFrom(address from, address to, uint256 amount) public prank returns (bool) {
        return BarToken(target).transferFrom(from, to, amount);
    }

}
