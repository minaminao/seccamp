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
        vm.deal(playerAddress, 1 ether);
    }

    function testExploit() public {
        vm.startPrank(playerAddress, playerAddress);

        ////////// YOUR CODE GOES HERE //////////

        ////////// YOUR CODE END //////////

        assertTrue(setup.isSolved(), "challenge not solved");
        vm.stopPrank();
    }
}

////////// YOUR CODE GOES HERE //////////

////////// YOUR CODE END //////////
