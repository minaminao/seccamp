// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {HuffUtils} from "../huff-utils/HuffUtils.sol";
import "forge-std/Test.sol";

contract SolverTest is Test {
    function test() public {
        bytes memory code = new HuffUtils().compileRuntime("course/evm-with-huff/challenge-quine/QuineSolver.huff");

        assertTrue(code.length > 0, "code.length == 0");

        address addr;
        assembly {
            addr := create(0, add(code, 0x20), mload(code))
        }
        assertTrue(keccak256(code) == addr.codehash, "code != addr.codehash");

        (bool success, bytes memory result) = addr.staticcall("");
        assertTrue(success, "staticcall failed");
        assertTrue(keccak256(result) == addr.codehash, "return data != addr.codehash");

        emit log_named_uint("Solver code length", code.length);
    }
}
