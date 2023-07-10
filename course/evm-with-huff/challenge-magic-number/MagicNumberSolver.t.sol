// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {HuffUtils} from "../huff-utils/HuffUtils.sol";
import "forge-std/Test.sol";
import {MagicNumberSolverNaive} from "./MagicNumberSolverNaive.sol";

contract SolverTest is Test {
    string constant HUFF_FILE = "course/evm-with-huff/challenge-magic-number/MagicNumberSolver.huff";

    function test10Bytes() public {
        address solverAddress = new HuffUtils().deploy(HUFF_FILE);
        _test(solverAddress, 10);
    }

    function test7Bytes() public {
        address solverAddress = new HuffUtils().deploy(HUFF_FILE);
        _test(solverAddress, 7);
    }

    function testNaive() public {
        address solverAddress = address(new MagicNumberSolverNaive());
        _test(solverAddress, type(uint256).max);
    }

    function _test(address solverAddress, uint256 requiredSize) private {
        Solver solver = Solver(solverAddress);

        uint256 magic = solver.whatIsTheMeaningOfLife();
        assertEq(magic, 0x2a);

        uint256 size = solverAddress.code.length;
        emit log_named_uint("Solver code length", size);
        assertTrue(size <= requiredSize);
    }
}

interface Solver {
    function whatIsTheMeaningOfLife() external returns (uint256);
}
