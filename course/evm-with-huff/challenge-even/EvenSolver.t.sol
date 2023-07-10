// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {HuffUtils} from "../huff-utils/HuffUtils.sol";
import "forge-std/Test.sol";

contract SolverTest is Test {
    function test() public {
        address solverAddress = new HuffUtils().deploy("course/evm-with-huff/challenge-even/EvenSolver.huff");
        _test(solverAddress, 11);
    }

    function _test(address solverAddress, uint256 requiredSize) private {
        for (uint256 i = 0; i < 100; i++) {
            (bool success, bytes memory data) = solverAddress.call(abi.encode(i));
            require(success);
            uint256 isEven = abi.decode(data, (uint256));
            assertEq(isEven, uint256((i + 1) % 2));
        }
        uint256 size = solverAddress.code.length;
        emit log_named_uint("Solver code length", size);
        assertTrue(size <= requiredSize);
    }
}
