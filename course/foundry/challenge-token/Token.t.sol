// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Token.sol";

contract TokenTest is Test {
    Token public token;
    address public alice;
    address public bob;
    address public charlie;

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        token = new Token();
    }

    function testTransfer() public {
        assertTrue(token.transfer(alice, 100));
        assertEq(token.balanceOf(alice), 100);
        assertTrue(token.transfer(bob, 200));
        assertEq(token.balanceOf(bob), 200);
        assertTrue(token.transfer(alice, 100));
        assertEq(token.balanceOf(alice), 200);

        // alice: 200, bob: 200

        vm.prank(alice);
        assertTrue(token.transfer(bob, 100));
        assertEq(token.balanceOf(alice), 100);
        assertEq(token.balanceOf(bob), 300);

        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, 101);
        assertEq(token.balanceOf(alice), 100);
    }

    function testApprove() public {
        assertEq(token.allowance(alice, bob), 0);
        vm.prank(alice);
        assertTrue(token.approve(bob, 100));
        assertEq(token.allowance(alice, bob), 100);
        assertEq(token.allowance(alice, address(0x100)), 0);
    }

    function testApproveAndTransfer() public {
        testApprove();
        assertTrue(token.transfer(alice, 100));
        vm.prank(alice);
        assertTrue(token.transfer(bob, 100));
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.allowance(alice, bob), 100);
    }

    function testTransferFrom() public {
        assertTrue(token.transfer(alice, 100));
        assertEq(token.allowance(alice, bob), 0);
        vm.prank(alice);
        assertTrue(token.approve(bob, 100));
        assertEq(token.allowance(alice, bob), 100);
        vm.prank(bob);
        assertTrue(token.transferFrom(alice, bob, 100));
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(bob), 100);
        assertEq(token.allowance(alice, bob), 0);
    }

    function testTransferFrom2() public {
        assertTrue(token.transfer(alice, 100));
        assertEq(token.allowance(alice, bob), 0);
        vm.prank(alice);
        assertTrue(token.approve(charlie, 100));
        assertEq(token.allowance(alice, charlie), 100);
        vm.prank(bob);
        vm.expectRevert();
        token.transferFrom(alice, bob, 100);
        vm.prank(charlie);
        assertTrue(token.transferFrom(alice, bob, 100));
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(bob), 100);
        assertEq(token.allowance(alice, charlie), 0);
    }

    function testInfiniteApprove() public {
        assertTrue(token.transfer(alice, 1000));
        vm.prank(alice);
        assertTrue(token.approve(bob, type(uint256).max));
        assertEq(token.allowance(alice, bob), type(uint256).max);
        vm.prank(bob);
        assertTrue(token.transferFrom(alice, bob, 100));
        assertEq(token.balanceOf(alice), 900);
        assertEq(token.allowance(alice, bob), type(uint256).max, "allowance must not change");
    }
}
