// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Challenge.sol";

contract ChallengeTest is Test {
    Setup setup;
    address public playerAddress;

    function setUp() public {
        playerAddress = makeAddr("player");
        setup = new Setup();
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
