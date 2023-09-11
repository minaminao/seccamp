// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Token {
    string public name = "Token";
    uint256 public totalSupply = 10000;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 tokens);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 amount) public returns (bool success) {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
        ////////// YOUR CODE HERE //////////
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        ////////// YOUR CODE HERE //////////
    }
}
