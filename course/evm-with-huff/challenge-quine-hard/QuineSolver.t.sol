// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {HuffUtils} from "../huff-utils/HuffUtils.sol";
import "forge-std/Test.sol";

contract SolverTest is Test {
    function test() public {
        bytes memory code = new HuffUtils().compileRuntime("course/evm-with-huff/challenge-quine-hard/QuineSolver.huff");

        assertTrue(code.length > 0, "code.length == 0");
        assertTrue(check(code), "disallowed instruction");

        address addr;
        assembly {
            addr := create(0, add(code, 0x20), mload(code))
        }
        assertTrue(keccak256(code) == addr.codehash, "code != addr.codehash");

        (bool success, bytes memory result) = addr.staticcall("");
        assertTrue(success, "staticcall failed");
        assertTrue(keccak256(result) == addr.codehash, "return data != addr.codehash");

        emit log_named_uint("Solver code length", code.length);
        assertTrue(code.length <= 33);
    }

    function check(bytes memory code) private pure returns (bool) {
        for (uint256 i = 0; i < code.length; i++) {
            uint8 op = uint8(code[i]);

            if (op >= 0x30 && op <= 0x48) {
                return false;
            }

            if (
                op == 0x54 // SLOAD
                    || op == 0x55 // SSTORE
                    || op == 0xF0 // CREATE
                    || op == 0xF1 // CALL
                    || op == 0xF2 // CALLCODE
                    || op == 0xF4 // DELEGATECALL
                    || op == 0xF5 // CREATE2
                    || op == 0xFA // STATICCALL
                    || op == 0xFF // SELFDESTRUCT
            ) {
                return false;
            }

            // PUSH
            if (op >= 0x60 && op < 0x80) {
                i += (op - 0x60) + 1;
            }
        }

        return true;
    }
}
