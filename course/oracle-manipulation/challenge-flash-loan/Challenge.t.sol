// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Challenge.sol";

contract ChallengeTest is Test {
    Setup setup;
    address public playerAddress;

    function setUp() public {
        vm.createSelectFork("mainnet", 17600000);

        playerAddress = makeAddr("player");
        vm.deal(playerAddress, 4 ether);
        setup = new Setup();
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
