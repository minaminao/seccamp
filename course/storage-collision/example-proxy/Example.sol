// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ProxyStorage {
    address public owner;
    address public implAddr;
}

contract Counter is ProxyStorage {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        require(newNumber < type(uint256).max / 2);
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}

contract Proxy is ProxyStorage {
    constructor(address implAddr_) {
        owner = msg.sender;
        implAddr = implAddr_;
    }

    function upgrade(address newImplAddr) public {
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
        counter = Counter(address(new Proxy(address(new Counter()))));
    }
}
