// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Flag {
    ERC20 immutable weth;
    bool public solved = false;

    constructor(ERC20 weth_) {
        weth = weth_;
    }

    function solve() external {
        require(weth.balanceOf(msg.sender) >= 1_000 ether, "not enough WETH");
        solved = true;
    }
}

contract Setup {
    ERC20 public weth = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    bool claimed = false;
    Flag public flag;

    constructor() {
        flag = new Flag(weth);
    }

    function isSolved() public view returns (bool) {
        return flag.solved();
    }
}
