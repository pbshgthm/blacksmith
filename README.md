# User based testing pattern
A common pattern used in dapptools and foundry projects is a 'User Contract'. It is an abstraction over the contract interaction that looks something like this (from [DSToken](https://github.com/dapphub/ds-token/blob/16f187acc15dd839589be60173ad1ebd0716eb82/src/token.t.sol#L24))

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
    //...
}
```
And in the test contract, we can use it like this

```solidity
user1 = new TokenUser(token);
user1.doApprove(user2);
```

This is an interesting pattern as it lets you wrap contracts and test them like how a user would interact with them. Its advantage shines really well when you need to test with multiple user addresses.

# Blacksmiths to use the foundry
I took this pattern a step further and created a full-fledged contract generator that will create these 'User Contracts', along with a bunch of UX niceties. You can create a user with a particular address or private key and it can perform all operations an EOA can.  All this can be automated by running the [blacksmith.js](https://github.com/pbshgthm/blacksmith/blob/main/blacksmith.js) script (sorry, not in rust yet). It automatically creates User contracts for all contracts in your foundry project directory.

## Features

### Wrap multiple target contracts
```solidity
user1.dex.swap(100);
user1.factory.pause(true);
user1.token.transfer(user2.addr, 100);
```

### Sign using private key
```solidity
(uint8 v, bytes32 r, bytes32 s) = user1.sign("blacksmith");
```

### Call arbiraty contracts
```solidity
user1.call{value:10}(contract_address, "calldata");
```

### Set user address's balance
```solidity
user1.deal(100);
```

### Zero code size at address
```solidity
user1.addr.code.length // is zero
```

The blacksmith.js script creates the base`Blacksmith.sol` that contains basic functions like `call`, `sign` and `deal`. It also creates `TargetBS.sol` for all `Target` contracts in the project directory.  To Base User contract (Blacksmith) takes in an address and a private key as constructor params. If the private key is zero, the provided address is used as the user's address, else the address is calculated from the private key. 

```solidity
constructor( address _addr, uint256 _privateKey, address _target) {
    addr = _privateKey == 0 ? _addr : bsvm.addr(_privateKey);
    privateKey = _privateKey;
    target = payable(_target);
}
```

To create a User contract to interact with a `Target` contract, you import `TargetBS` contract. Along with the address and private key, it also takes in the target contract's address

```solidity
constructor( address _addr, uint256 _privateKey, address _target) {
    addr = _privateKey == 0 ? _addr : bsvm.addr(_privateKey);
    privateKey = _privateKey;
    target = payable(_target);
}
```

To create a user object, you can create a struct and add the required interface. The below code is all you'll need to write to get started with testing. Rest is taken care of by blacksmith script. 

```solidity
struct User {
    address addr;  // to avoid external call, we save it in the struct
    Blacksmith base;  // contains call(), sign(), deal()
    FooTokenBS foo;  // interacts with FooToken contract
    BarTokenBS bar;  // interacts with BarToken contract
}

function createUser(address _addr, uint256 _privateKey) public returns (User memory) {
    Blacksmith base = new Blacksmith(_addr, _privateKey);
    FooTokenBS _foo = new FooTokenBS(_addr, _privateKey, address(foo));
    BarTokenBS _bar = new BarTokenBS(_addr, _privateKey, address(bar));
    base.deal(100);
    return User(base.addr(), base, _foo, _bar);
}

function setUp() public {
    foo = new FooToken();
    bar = new BarToken();
    alice = createUser(address(0), 111);  // addrss will be 0x052b91ad9732d1bce0ddae15a4545e5c65d02443
    bob = createUser(address(111), 0);  // address will be 0x000000000000000000000000000000000000006f
    eve = createUser(address(0), 0);  // address will be 0x0000000000000000000000000000000000000000
}
```

Now you can use it directly in your test functions

```solidity
function testSomething() public {
    bob.foo.approve(alice.addr, 10);
    alice.foo.transferFrom(bob.addr, alice.addr, 10);
    alice.bar.approve(eve.addr, 100);
    eve.transferFrom(bob.addr, eve.addr, 50);
    eve.call{value:10}(alice.ddr, "");
    (uint8 v, bytes32 r, bytes32 s) = alice.sign("blacksmith");
}
```

# Usage

To get started with blacksmith, download blacksmith.js to the *foundry project’s root directory*.
```bash
curl -O https://raw.githubusercontent.com/pbshgthm/blacksmith/main/blacksmith.js
node blacksmith.js create #in foundry project's root directory
```
This will run `forge build` and then create `/src/test/blacksmith` directory with user contracts in `Target.bs.sol`.