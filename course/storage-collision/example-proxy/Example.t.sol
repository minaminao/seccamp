// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Example.sol";

contract ExampleTest is Test {
    Setup setup;
    address public playerAddress;

    function setUp() public {
        playerAddress = makeAddr("player");
        setup = new Setup();
        vm.deal(playerAddress, 1 ether);
    }

    function test() public {
        vm.startPrank(playerAddress, playerAddress);

        setup.counter().setNumber(100);
        address owner = Proxy(address(setup.counter())).owner();
        assertEq(owner, address(setup));

        vm.stopPrank();
    }
}
