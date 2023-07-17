// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        require(newNumber < type(uint256).max / 2);
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}

contract BadProxy {
    address public owner;
    address public implAddr;

    constructor(address implAddr_) {
        owner = msg.sender;
        implAddr = implAddr_;
    }

    function upgradeTo(address newImplAddr) public {
        require(owner == msg.sender);
        implAddr = newImplAddr;
    }

    fallback(bytes calldata input) external returns (bytes memory) {
        (bool success, bytes memory res) = implAddr.delegatecall(input);
        if (success) {
            return res;
        } else {
            revert(string(res));
        }
    }
}

contract Setup {
    Counter public counter;

    constructor() payable {
        counter = Counter(address(new BadProxy(address(new Counter()))));
    }

    function isSolved() public view returns (bool) {
        return counter.number() == type(uint256).max;
    }
}
