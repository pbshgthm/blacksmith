#!/usr/bin/env node

const fs = require('fs')
const { exec } = require('child_process')

const cmd = process.argv[2]
switch (cmd) {
    case 'create': {
        console.log('running :: forge build')
        exec('forge build', (err, stdout, stderr) => {
            if (stdout) {
                const nochange = stdout.split('\n')[1]?.indexOf('No files changed') === 0
                const success = stdout.split('\n')[3]?.indexOf('Compiler run successful') === 0
                if (success || nochange) {
                    console.log('\x1b[32m%s\x1b[0m', "build   :: completed")
                } else {
                    console.log('\x1b[31m%s\x1b[0m', "build   :: failed")
                }
                createBlacksmiths()
            } else {
                console.log('\x1b[31m%s\x1b[0m', "build   :: failed badly")
                createBlacksmiths()
            }
        })
        break
    }
    case 'clean': cleanBlacksmith()
        break
    default: console.log('unknown command')
}

////////////////////////////////////////////////////////////////////////////////

function getABI({ name, source }) {
    const path = `./out/${source.split('/').slice(-1)[0]}/${name}.json`
    return JSON.parse(fs.readFileSync(path, 'utf8')).abi
}

function createFunction(abi, name, fn) {

    function fmtType(type) {
        if (type === 'bytes') return `${type} memory`
        if (type === 'string') return `${type} memory`
        if (type.indexOf('struct ') === 0) return `${type.slice(7)} memory`
        if (type.indexOf("contract ") === 0 && type.indexOf("]") === type.length - 1) return `${type.slice(9)} memory`;
        if (type.indexOf('contract ') === 0) return `${type.slice(9)}`

        if (type.indexOf('enum ') === 0) type = type.slice(5)
        if (type.indexOf(']') === type.length - 1) return `${type} memory`
        return type
    }

    function fmtArgs(args, withType, withName) {
        const argFmt = args.map((arg, i) => {
            const _type = withType ? fmtType(arg.internalType) : ''
            const _name = withName ? (arg.name || `arg${i}`) : ''
            return `${_type}${_type && _name ? ' ' : ''}${_name}`
        })
        return argFmt.join(', ')
    }

    function fmtValue() {
        if (fn.stateMutability === 'payable') return '{value: msg.value}'
        return ''
    }

    function fmtPayable() {
        if (fn.stateMutability === 'payable') return 'payable '
        return ''
    }

    function fmtReturn(abi, name) {
        if (fn.outputs.length === 0 && abi.slice(-1)[0].type.indexOf("receive") === 0)
        return `${name}(payable(target))`;
        if (fn.outputs.length === 0) return `${name}(target)`;
        if (abi.slice(-1)[0].type.indexOf("receive") === 0) return `return ${name}(payable(target))`;
        return `return ${name}(target)`;
    }

    function fmtOutput() {
        if (fn.outputs.length === 0) return ''
        return `returns (${fmtArgs(fn.outputs, withType = true, withName = false)})`
    }

    function fmtInput(withType = true) {
        return `(${fmtArgs(fn.inputs, withType, withName = true)})`
    }

    return `function ${fn.name}${fmtInput()} public ${fmtPayable()}prank ${fmtOutput()} {
        ${fmtReturn(abi,name)}.${fn.name}${fmtValue()}${fmtInput(false)};
    }`
}

function blacksmithCode() {
    return (
        `// SPDX-License-Identifier: Unlicense
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
`
    )
}

function createCode({ name, source, abi }) {
    const code =
        `// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./Blacksmith.sol";
import "../../${source.slice(4)}";

contract ${name}BS {
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

    ${abi.filter(x => x.type === 'function').map(x => createFunction(abi, name, x)).join('\n\n\t')}

}
`
    return code
}

function writeFile({ name, code }) {
    const path = './src/test/blacksmith'
    if (!fs.existsSync(path)) fs.mkdirSync(path)
    fs.writeFileSync(`${path}/${name}.bs.sol`, code)
    fs.writeFileSync(`./${path}/Blacksmith.sol`, blacksmithCode())
}

function getFiles() {
    const cache = JSON.parse(fs.readFileSync('./cache/solidity-files-cache.json', 'utf8'))
    const files = Object.values(cache.files)
    let contractPaths = []
    files.forEach(file => {
        const contracts = Object.keys(file.artifacts)
        contracts.forEach(contract => {
            const dir = file.sourceName.split('/')
            if (dir[0] !== 'src') return
            if (dir[0] === 'src' && dir[1] === 'test') return
            contractPaths.push({
                name: contract,
                source: file.sourceName
            })
        })
    })
    return contractPaths
}

function createBlacksmiths() {
    try {
        files = getFiles()
        console.log(`found   :: ${files.length} contracts\n`)
    } catch (e) {
        console.log('\x1b[31m%s\x1b[0m', "error   :: couldn't read cache")
        process.exit()
    }
    files.forEach(file => {
        const abi = getABI(file)
        const code = createCode({ ...file, abi })
        writeFile({ name: file.name, code })
        console.log(`created :: ${file.name}.bs.sol`)
    })
}

function cleanBlacksmith() {
    fs.rmdirSync('./src/test/blacksmith', { recursive: true })
    console.log('\x1b[32m%s\x1b[0m', 'clean   :: completed')
}


