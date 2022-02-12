// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
//*
import "ds-test/test.sol";
import "./blacksmith/Tasks.bs.sol";

interface Hevm {
    function addr(uint256 privateKey) external returns (address);

    function expectRevert(bytes memory revertMsg) external;
}

contract TasksTest is DSTest {
    Tasks target;
    Hevm hevm = Hevm(HEVM_ADDRESS);

    struct User {
        address addr;
        Blacksmith base;
        TasksBS task;
    }

    uint256[] uintArray = [0, 1, 2];
    User foo;
    User bar;

    function setUp() public {
        target = new Tasks();
        foo = createUser(address(0), 123);
        bar = createUser(address(123), 0);
    }

    function createUser(address _addr, uint256 _privateKey)
        public
        returns (User memory)
    {
        Blacksmith base = new Blacksmith(_addr, _privateKey);
        TasksBS tasks = new TasksBS(
            _addr,
            _privateKey,
            payable(address(target))
        );
        base.deal(100);
        return User(base.addr(), base, tasks);
    }

    function testAddr() public {
        address _addr = hevm.addr(123);
        assertEq(foo.addr, _addr);
        assertEq(bar.addr, address(123));
    }

    function testCodeLength() public {
        assertEq(foo.addr.code.length, 0);
    }

    function testBalance() public {
        assertEq(foo.addr.balance, 100);
    }

    function testSend() public {
        assertEq(foo.addr.balance, 100);
        foo.base.call{value: 50}(bar.addr, "");
        assertEq(foo.addr.balance, 50);
        assertEq(bar.addr.balance, 150);
    }

    function testRevert() public {
        foo.task.revertCall(false);
        hevm.expectRevert("Requested Revet");
        foo.task.revertCall(true);
    }

    function testInvalidSend() public {
        hevm.expectRevert("BS ERROR : Insufficient balance");
        foo.base.call{value: 101}(bar.addr, "");
    }

    function testSign() public {
        bytes32 _hash = keccak256("blacksmith");
        (uint8 v, bytes32 r, bytes32 s) = foo.base.sign(_hash);
        foo.task.verifySig(v, r, s, _hash);

        hevm.expectRevert("Invalid signature");
        bar.task.verifySig(v, r, s, _hash);
    }

    function testMsgObj() public {
        (address sender, address origin, uint256 value) = foo.task.msgObject{
            value: 50
        }();
        assertEq(sender, foo.addr);
        assertEq(origin, foo.addr);
        assertEq(value, 50);
        assertEq(foo.addr.balance, 50);
    }

    function testValueArgs() public {
        (uint256 _uint256, bytes32 _bytes32) = foo.task.valueArgs(
            100,
            bytes32("blacksmith")
        );
        assertEq(_uint256, 100);
        assertEq(_bytes32, bytes32("blacksmith"));
    }

    function testDynamicArgs() public {
        bool[2] memory boolArray = [true, false];

        (
            string memory _string,
            bytes memory _bytes,
            uint256[] memory _uintArray,
            bool[2] memory _boolArray
        ) = foo.task.dynamicArgs(
                "blacksmith",
                abi.encode("blacksmith"),
                uintArray,
                boolArray
            );

        assertEq(_string, "blacksmith");
        assertEq(abi.decode(_bytes, (string)), "blacksmith");
        assertEq(_uintArray[2], 2);
        assert(_boolArray[0]);
    }

    function testEnum() public {
        Tasks.Enum[2] memory enumArray = [Tasks.Enum.A, Tasks.Enum.B];
        (Tasks.Enum _enum, Tasks.Enum[2] memory _enumArray) = foo.task.enumArgs(
            Tasks.Enum.A,
            enumArray
        );
        assertEq(uint256(_enum), uint256(Tasks.Enum.A));
        assertEq(uint256(_enumArray[1]), uint256(Tasks.Enum.B));
    }

    function testStruct() public {
        Tasks.Struct[2] memory structArray = [
            Tasks.Struct(0, false),
            Tasks.Struct(1, true)
        ];
        (Tasks.Struct memory _struct, Tasks.Struct[2] memory _structArray) = foo
            .task
            .structArgs(Tasks.Struct(1, true), structArray);
        assertEq(_struct._uint256, 1);
        assert(_structArray[1]._bool);
    }
}
//*/
