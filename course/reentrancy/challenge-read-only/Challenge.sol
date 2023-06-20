// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Rabbit is ReentrancyGuard, Ownable {
    Rabbit public other;
    uint256 public initialBalance;
    bool public isCatched = false;

    constructor() payable {
        initialBalance = msg.value;
    }

    function setOther(address otherAddress) public onlyOwner {
        other = Rabbit(otherAddress);
    }

    function catched() public payable nonReentrant {
        require(msg.value == initialBalance && !isCatched);
        if (other.isCatched()) {
            other.escape{value: initialBalance}();
        } else {
            (bool success,) = msg.sender.call{value: msg.value + initialBalance}("");
            require(success);
            isCatched = true;
        }
    }

    function escape() public payable nonReentrant {
        require(msg.sender == address(other) && msg.value == initialBalance);
        require(isCatched && !other.isCatched());
        isCatched = false;
    }
}

contract Setup {
    Rabbit public rabbitA;
    Rabbit public rabbitB;
    uint256 initialDeposit;

    constructor() payable {
        rabbitA = new Rabbit{value: msg.value / 2}();
        rabbitB = new Rabbit{value: msg.value / 2}();
        rabbitA.setOther(address(rabbitB));
        rabbitB.setOther(address(rabbitA));
        initialDeposit = msg.value;
    }

    function isSolved() public view returns (bool) {
        // If you chase two rabbits, you will not catch either one.
        return rabbitA.isCatched() && rabbitB.isCatched() && msg.sender.balance >= initialDeposit;
    }
}
