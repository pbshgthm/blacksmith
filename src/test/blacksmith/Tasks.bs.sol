// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./Blacksmith.sol";
import "../../Tasks.sol";

contract TasksBS is Blacksmith {
    address payable target;
    
    constructor(
        address _addr,
        uint256 _privateKey,
        address _target
    ) Blacksmith(_addr, _privateKey) {
        target = payable(_target);
    }

    function addressUint256BoolMap(address arg0, uint256 arg1) public prank returns (bool) {
        return Tasks(target).addressUint256BoolMap(arg0, arg1);
    }

	function dynamicArgs(string memory _string, bytes memory _bytes, uint256[] memory _uint256Array, bool[2] memory _boolArray) public prank returns (string memory, bytes memory, uint256[] memory, bool[2] memory) {
        return Tasks(target).dynamicArgs(_string, _bytes, _uint256Array, _boolArray);
    }

	function enumArgs(Tasks.Enum _enum, Tasks.Enum[2] memory _enumArray) public prank returns (Tasks.Enum, Tasks.Enum[2] memory) {
        return Tasks(target).enumArgs(_enum, _enumArray);
    }

	function msgObject() public payable prank returns (address, address, uint256) {
        return Tasks(target).msgObject{value: msg.value}();
    }

	function revertCall(bool _bool) public prank  {
        Tasks(target).revertCall(_bool);
    }

	function structArgs(Tasks.Struct memory _struct, Tasks.Struct[2] memory _structArray) public prank returns (Tasks.Struct memory, Tasks.Struct[2] memory) {
        return Tasks(target).structArgs(_struct, _structArray);
    }

	function valueArgs(uint256 _uint256, bytes32 _bytes32) public prank returns (uint256, bytes32) {
        return Tasks(target).valueArgs(_uint256, _bytes32);
    }

	function verifySig(uint8 v, bytes32 r, bytes32 s, bytes32 hash) public prank  {
        Tasks(target).verifySig(v, r, s, hash);
    }

}
