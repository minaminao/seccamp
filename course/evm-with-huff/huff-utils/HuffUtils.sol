// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {Vm} from "forge-std/Vm.sol";

contract HuffUtils {
    Vm public constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    function deploy(string memory fileName) public payable returns (address addr) {
        bytes memory code = compile(fileName);
        uint256 value = msg.value;

        vm.prank(msg.sender);
        assembly {
            addr := create(value, add(code, 0x20), mload(code))
        }
    }

    function compile(string memory fileName) public payable returns (bytes memory code) {
        string[] memory cmds = new string[](3);
        cmds[0] = "huffc";
        cmds[1] = string(fileName);
        cmds[2] = "-b";
        code = vm.ffi(cmds);
    }

    function compileRuntime(string memory fileName) public payable returns (bytes memory code) {
        string[] memory cmds = new string[](3);
        cmds[0] = "huffc";
        cmds[1] = string(fileName);
        cmds[2] = "-r";
        code = vm.ffi(cmds);
    }
}
