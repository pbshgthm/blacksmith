// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./blacksmith/FooToken.bs.sol";
import "./blacksmith/BarToken.bs.sol";

interface Hevm {
    function addr(uint256 privateKey) external returns (address);

    function expectRevert(bytes memory revertMsg) external;
}

contract TokenTest is DSTest {
    FooToken foo;
    BarToken bar;
    Hevm hevm = Hevm(HEVM_ADDRESS);

    struct User {
        address addr;
        Blacksmith base;
        FooTokenBS foo;
        BarTokenBS bar;
    }

    User alice;
    User bob;

    function setUp() public {
        foo = new FooToken();
        bar = new BarToken();
        alice = createUser(address(0), 111);
        bob = createUser(address(111), 0);
    }

    function createUser(address _addr, uint256 _privateKey)
        public
        returns (User memory)
    {
        Blacksmith base = new Blacksmith(_addr, _privateKey);
        FooTokenBS _foo = new FooTokenBS(_addr, _privateKey, address(foo));
        BarTokenBS _bar = new BarTokenBS(_addr, _privateKey, address(bar));
        base.deal(100);
        emit log_address(base.addr());
        return User(base.addr(), base, _foo, _bar);
    }

    function testBalance() public {
        foo.transfer(bob.addr, 100);
        bar.transfer(alice.addr, 50);
        assertEq(foo.balanceOf(bob.addr), 100);
        assertEq(bar.balanceOf(alice.addr), 50);
    }

    function testTransfer() public {
        foo.transfer(bob.addr, 100);
        bob.foo.transfer(alice.addr, 50);
        assertEq(foo.balanceOf(bob.addr), 50);
        assertEq(foo.balanceOf(alice.addr), 50);
    }

    function testTransferFail() public {
        hevm.expectRevert("ERC20: transfer amount exceeds balance");
        bob.foo.transfer(alice.addr, 50);
    }

    function testTransferFrom() public {
        foo.transfer(bob.addr, 100);
        bob.foo.approve(alice.addr, 10);
        alice.foo.transferFrom(bob.addr, alice.addr, 10);
        assertEq(foo.balanceOf(bob.addr), 90);
        assertEq(foo.balanceOf(alice.addr), 10);
    }

    function testTransferFromFail() public {
        foo.transfer(bob.addr, 100);
        bob.foo.approve(alice.addr, 10);
        hevm.expectRevert("ERC20: insufficient allowance");
        alice.foo.transferFrom(bob.addr, alice.addr, 20);
    }

    function testAllowanceChange() public {
        foo.transfer(bob.addr, 100);
        bob.foo.approve(alice.addr, 50);
        alice.foo.transferFrom(bob.addr, alice.addr, 40);
        assertEq(foo.allowance(bob.addr, alice.addr), 10);
        hevm.expectRevert("ERC20: insufficient allowance");
        alice.foo.transferFrom(bob.addr, alice.addr, 20);
    }
}
