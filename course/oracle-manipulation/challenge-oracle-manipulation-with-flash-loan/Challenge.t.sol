// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./Challenge.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ChallengeTest is Test {
    Setup setup;
    address public playerAddress;

    function setUp() public {
        vm.createSelectFork("mainnet", 17600000);

        playerAddress = makeAddr("player");
        ERC20 usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        ERC20 weth = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        setup = new Setup(address(usdc), address(weth));
        deal(address(usdc), address(setup), 20_900_000 * (10 ** usdc.decimals()));
        deal(address(weth), address(setup), 10_000 ether);
        setup.init();
    }

    function testExploit() public {
        vm.startPrank(playerAddress, playerAddress);

        ////////// YOUR CODE GOES HERE //////////

        ////////// YOUR CODE END //////////

        emit log_named_decimal_uint("user tokenA", setup.tokenA().balanceOf(playerAddress), setup.tokenA().decimals());
        emit log_named_decimal_uint("user tokenB", setup.tokenB().balanceOf(playerAddress), setup.tokenB().decimals());
        assertTrue(setup.isSolved(), "challenge not solved");
        vm.stopPrank();
    }
}

////////// YOUR CODE GOES HERE //////////

////////// YOUR CODE END //////////
