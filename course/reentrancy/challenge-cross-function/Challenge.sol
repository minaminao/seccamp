// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Vault is ReentrancyGuard {
    mapping(address => uint256) public balanceOf;

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
    }

    function transfer(address to, uint256 amount) public {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }

    function withdrawAll() public nonReentrant {
        require(balanceOf[msg.sender] > 0);
        (bool success,) = msg.sender.call{value: balanceOf[msg.sender]}("");
        require(success);
        balanceOf[msg.sender] = 0;
    }
}

contract Setup {
    Vault public vault;
    uint256 initialDeposit;

    constructor() payable {
        vault = new Vault();
        vault.deposit{value: msg.value}();
        initialDeposit = msg.value;
    }

    function isSolved() public view returns (bool) {
        return address(vault).balance == 0 && msg.sender.balance >= initialDeposit;
    }
}
