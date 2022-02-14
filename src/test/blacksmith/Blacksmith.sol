// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Bsvm {
    function addr(uint256 privateKey) external returns (address addr);

    function deal(address who, uint256 amount) external;

    function startPrank(address sender, address origin) external;

    function sign(uint256 privateKey, bytes32 digest)
        external
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        );
        
}

contract Blacksmith {
    Bsvm constant bsvm = Bsvm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    address _address;
    uint256 privateKey;

    constructor(address _addr, uint256 _privateKey) {
        _address = _privateKey == 0 ? _addr : bsvm.addr(_privateKey);
        privateKey = _privateKey;
    }

    modifier prank() {
        bsvm.startPrank(_address, _address);
        _;
    }

    function addr() external view returns (address) {
        return _address;
    }

    function deal(uint256 _amount) public {
        bsvm.deal(_address, _amount);
    }

    function call(address _addr, bytes memory _calldata)
        public
        payable
        prank
        returns (bytes memory)
    {
        require(_address.balance >= msg.value, "BS ERROR : Insufficient balance");
        (bool success, bytes memory data) = _addr.call{value: msg.value}(
            _calldata
        );
        require(success, "BS ERROR : Call failed");
        return data;
    }

    function sign(bytes32 _digest)
        external
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(privateKey != 0, "BS Error : No Private key");
        return bsvm.sign(privateKey, _digest);
    }

    receive() external payable {}
}
