# Blacksmith

## Forging in heat and sweat

Testing smart contracts have been made very easy with Foundry. With blazing speed and fuzzers, it's a no brainer to use it for every smart contract project. It also uses VM cheat codes to change `msg.sender` , `tx.origin` and other EVM properties. The fact that you can write tests using solidity is a huge advantage as it avoids context switching while developing. Although this is clearly a great thing, it also means it's not possible to advantage of testing patterns that exist in high-level libraries directly. 

For example, it's very easy to create user objects in hardhat and test from different accounts.

```solidity
 token.connect(addr1).transfer(addr2.address, 50);
```

To do the same in Forge, we can use the `prank()` cheat code. To change the `msg.sender` we would do something like this

```solidity
vm.prank(addr1);
addr1.transfer(addr2, 50);
```

While this seems pretty good, it might get a but messy when trying to use multiple addresses while testing. Testing a sequence of function calls might require multiple usages of cheatcodes.

```solidity
vm.prank(addr1);
token.approve(addr2, 50);
vm.prank(addr2);
token.transferFrom(addr1, addr2, 50);
(uint8 v, bytes32 r, bytes32 s) = vm.sign(add1PK, msgDigest);
token.permit(addr1, addr3, 50, deadline, v, r, s);
vm.prank(addr3);
token.transferFrom(addr1, addr3, 50);
```

Even though there are only 3 calls happening, the inclusion of cheat codes increases the code size. Apart from the extra lines of codes, it also is a bit hard to keep track of `msg.sender` and other cheat code dependant variables compared to an OOP like pattern, like in hardhat. 

To handle this, dapptools and foundry users adopt  ‘User Object’ models that look something like this.

```solidity
contract TokenUser {
    DSToken  token;

    constructor(DSToken token_) public {
        token = token_;
    }

    function doApprove(address spender, uint amount)
        public
        returns (bool)
    {
        return token.approve(spender, amount);
    }

    function doBurn(address owner, uint amount)
        public
        returns (bool)
    {
        return token.burn(owner, amount);
    }

    //...
}

contract DSTokenTest is DSTest {
    
    DSToken token;
    address user1;
    address user2;

    function setUp() public {
        token = new DSToken("TST");
        token.mint(100);
        user1 = address(new TokenUser(token));
        user2 = address(new TokenUser(token));
    }

    function testFailBurnGuyNoAuth() public {
        token.transfer(user2, 10);
        TokenUser(user2).doApprove(user1);
        TokenUser(user1).doBurn(user2, 10);
    }
    function testBurnGuyAuth() public {
        token.transfer(user2, 10);
        token.setOwner(user1);
        TokenUser(user2).doApprove(user1);
        TokenUser(user1).doBurn(user2, 10);
    }

   //...
}
```

Here, a new contract `TokenUser` is used to interface with the token contract and call various functions. When calling `TokenUser(user2).doApprove(user1)` the sender will the `TokenUser` contract address. With this pattern, you could abstract away the implementation details and use a clean interface like `TokenUser(user2)` to interact with your contract. 

## Bringing in the Blacksmith

Blacksmith helps take this user-based testing model to the next steps. Blacksmith is a node script (sorry, not in rust yet) that generates user contracts that can interface with the contracts you are testing. The user contracts can interact with multiple contracts in an OOP like way. In practice, the code would look something like this.

```solidity
//calling transfer on token contract from user1
user1.token.transfer(user2.addr, 50);

//calling pause on factory contract from user1
user1.factory.pause(true);

//calling swap on dex contract from user2
user2.dex.swap(400);

//setting user2 balance to 100
user2.deal(100);

//signing using user2's private key
(uint8 v, bytes32 r, bytes32 s) = user2.sign("blacksmith")
```

To make the user contract simulate an actual EOA blacksmith also offers a few features by default

- Can sign data with the address’s private key
- Can receive ether
- Can call arbitrary contracts
- Can set the account balance
- Code size at the user’s address will be zero (for contracts that check if the caller is contract or EOA)

Blacksmith uses `vm.prank()`, `vm.deal()` and `vm.sign()` under the hood so you don’t have to worry about it. The previously discussed code would look like this using blacksmith.  

## Employing Blacksmith

To get started with blacksmith, download blacksmith.js to the foundry project’s root directory.

```bash
curl -O https://raw.githubusercontent.com/pbshgthm/blacksmith/main/blacksmith.js
node blacksmith.js create #in foundry project's root directly
```

 

This will create `/src/test/blacksmith` directory with user contracts in `[TaretContract].bs.sol`

In the `src/test/blacksmith` directory, you’ll find `Blacksmith.sol`. This contract contains the core functions of Blacksmith. It’s constructor takes in an address and a private key. If the private key is zero, then the address of the user contract is set to the address provided. Else the address is computed from the private key.

```solidity
constructor( address _addr, uint256 _privateKey, address _target) {
    addr = _privateKey == 0 ? _addr : bsvm.addr(_privateKey);
    privateKey = _privateKey;
    target = payable(_target);
}
```

The `Backsmith` contract contains the following functions.

```solidity
//get user's address. (based on private key or input address)
function addr() external returns(address); 

//sets user balance to 
function deal(uint256 _amount) external;

//call contract/address from user address
function call(address _address, bytes memory _calldata) external payable returns (bytes memory);

//sign digest using private key (revert if no private key)
function sign(bytes32 _digest) external returns (uint8, bytes32, bytes32);
```

`[Target].bs.sol` contains user contracts that interact with `[Target]` contracts. The contract names will be as `[Target]BS`. They won’t contain the previously mentioned methods, but only those of the `[Target]`. It’s constructor takes in an address and a private key, but also the contract address with with it will interact.

```solidity
constructor( address _addr, uint256 _privateKey, address _target) {
    addr = _privateKey == 0 ? _addr : bsvm.addr(_privateKey);
    privateKey = _privateKey;
    target = payable(_target);
}
```

This contract will contain all the functions from `Target` contracts.

## Blacksmith in action

In our testing contract, we will start with creating a `User` struct. It will contain all the user contracts that needs to be interacted with.

```solidity
struct User {
    address addr;
    Blacksmith base; //contains call(), sign(), deal()
    FooTokenBS foo; //interacts with foo contract
    BarTokenBS bar; //interacts with bar contract
}
```

We can also create a `createUser` function to create users according to our prefrence. We can add ETH to users’s address in this step.

```solidity
function createUser(address _addr, uint256 _privateKey)
        public
        returns (User memory)
    {
        Blacksmith base = new Blacksmith(_addr, _privateKey);
        FooTokenBS _foo = new FooTokenBS(_addr, _privateKey, address(foo));
        BarTokenBS _bar = new BarTokenBS(_addr, _privateKey, address(bar));
        base.deal(100);
        return User(base.addr(), base, _foo, _bar);
    }
```

In our `setUp()` function, we can then create user instances.

```solidity
function setUp() public {
    foo = new FooToken();
    bar = new BarToken();
    alice = createUser(address(0), 111); //addrss will be 0x052b91ad9732d1bce0ddae15a4545e5c65d02443
    bob = createUser(address(111), 0); // address will be 0x000000000000000000000000000000000000006f
}
```

Creating a user with private key will be particularly useful while testing with mainnet forking. You can now use the `User` contracts like this

```solidity
function testTransferFrom() public {
    foo.transfer(bob.addr, 100);
    bob.foo.approve(alice.addr, 10);
    alice.foo.transferFrom(bob.addr, alice.addr, 10);
    assertEq(foo.balanceOf(bob.addr), 90);
    assertEq(foo.balanceOf(alice.addr), 10);
}
```