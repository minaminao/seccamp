// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MintableERC20 is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}

contract AMM {
    ERC20 public immutable tokenA;
    ERC20 public immutable tokenB;

    constructor(address tokenAAddress, address tokenBAddress) {
        tokenA = ERC20(tokenAAddress);
        tokenB = ERC20(tokenBAddress);
    }

    function swap(address tokenInAddress, address tokenOutAddress, uint256 amountIn) external {
        ERC20 tokenIn = ERC20(tokenInAddress);
        ERC20 tokenOut = ERC20(tokenOutAddress);
        require(tokenIn == tokenA || tokenIn == tokenB, "invalid tokenIn");
        require(tokenOut == tokenA || tokenOut == tokenB, "invalid tokenOut");
        require(tokenIn != tokenOut, "tokenIn == tokenOut");
        uint256 balanceIn = tokenIn.balanceOf(address(this));
        uint256 balanceOut = tokenOut.balanceOf(address(this));
        uint256 amountOut = balanceOut - balanceIn * balanceOut * 1000 / (balanceIn + amountIn) / 997; // 0.3% fee
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenOut.transfer(msg.sender, amountOut);
    }
}

contract LendingPool {
    ERC20 public immutable tokenA;
    ERC20 public immutable tokenB;
    AMM public immutable amm;
    mapping(address => mapping(address => int256)) public deposits;

    constructor(address tokenAAddress, address tokenBAddress, address ammAddress) {
        tokenA = ERC20(tokenAAddress);
        tokenB = ERC20(tokenBAddress);
        amm = AMM(ammAddress);
    }

    function supply(address asset, uint256 amount) external {
        ERC20 token = ERC20(asset);
        require(token == tokenA || token == tokenB, "invalid asset");
        deposits[asset][msg.sender] += int256(amount);
        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address asset, uint256 amount) external {
        // NOTE:
        // - require: depositsIn[msg.sender] * price * 75% >= amount + -depositsOut[msg.sender]
        // - price = tokenOut.balanceOf(address(amm)) / tokenIn.balanceOf(address(amm))
        ERC20 token = ERC20(asset);
        require(token == tokenA || token == tokenB, "invalid asset");
        if (token == tokenA) {
            require(
                deposits[address(tokenB)][msg.sender] * int256(tokenA.balanceOf(address(amm))) * 3
                    >= (int256(amount) + -deposits[asset][msg.sender]) * int256(tokenB.balanceOf(address(amm))) * 4,
                "insufficient deposit"
            );
        } else {
            require(
                deposits[address(tokenA)][msg.sender] * int256(tokenB.balanceOf(address(amm))) * 3
                    >= (int256(amount) + -deposits[asset][msg.sender]) * int256(tokenA.balanceOf(address(amm))) * 4,
                "insufficient deposit"
            );
        }
        deposits[asset][msg.sender] -= int256(amount);
        token.transfer(msg.sender, amount);
    }

    /* A liquidation function is omitted. */
}

contract Setup {
    MintableERC20 public tokenA;
    MintableERC20 public tokenB;
    AMM public amm;
    LendingPool public lendingPool;
    bool claimed = false;

    constructor() {
        tokenA = new MintableERC20("A", "A");
        tokenB = new MintableERC20("B", "B");
        amm = new AMM(address(tokenA), address(tokenB));
        tokenA.mint(address(amm), 20_000_000 ether);
        tokenB.mint(address(amm), 10_000 ether);
        lendingPool = new LendingPool(address(tokenA), address(tokenB), address(amm));
        tokenA.mint(address(lendingPool), 900_000 ether);
    }

    function claim() external {
        require(!claimed);
        claimed = true;
        tokenA.mint(msg.sender, 9_000_000 ether);
    }

    function isSolved() public view returns (bool) {
        return tokenA.balanceOf(msg.sender) >= (9_100_000 ether) && tokenA.balanceOf(address(lendingPool)) == 0;
    }
}
