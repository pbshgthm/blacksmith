// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Tasks {
    enum Enum {
        A,
        B,
        C
    }

    struct Struct {
        uint256 _uint256;
        bool _bool;
    }

    mapping(address => mapping(uint256 => bool)) public addressUint256BoolMap;

    function msgObject()
        public
        payable
        returns (
            address,
            address,
            uint256
        )
    {
        return (msg.sender, tx.origin, msg.value);
    }

    function revertCall(bool _bool) public pure {
        if (_bool) {
            revert("Requested Revet");
        }
    }

    function valueArgs(uint256 _uint256, bytes32 _bytes32)
        public
        pure
        returns (uint256, bytes32)
    {
        return (_uint256, _bytes32);
    }

    function dynamicArgs(
        string memory _string,
        bytes memory _bytes,
        uint256[] memory _uint256Array,
        bool[2] memory _boolArray
    )
        public
        pure
        returns (
            string memory,
            bytes memory,
            uint256[] memory,
            bool[2] memory
        )
    {
        return (_string, _bytes, _uint256Array, _boolArray);
    }

    function structArgs(Struct memory _struct, Struct[2] memory _structArray)
        public
        pure
        returns (Struct memory, Struct[2] memory)
    {
        return (_struct, _structArray);
    }

    function enumArgs(Enum _enum, Enum[2] memory _enumArray)
        public
        pure
        returns (Enum, Enum[2] memory)
    {
        return (_enum, _enumArray);
    }

    function verifySig(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 hash
    ) external view {
        address signer = ecrecover(hash, v, r, s);
        require(signer == msg.sender, "Invalid signature");
    }
}
