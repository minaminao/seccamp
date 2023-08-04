// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {TypedMemView} from "./TypedMemView.sol";

contract NomadBridgeInvestigationTest is Test {
    using TypedMemView for bytes;
    using TypedMemView for bytes29;

    IReplica constant replica = IReplica(0x5D94309E5a0090b165FA4181519701637B6DAEBA);

    function setUp() public {
        // vm.createSelectFork("mainnet", 15259100);
        vm.createSelectFork("mainnet", 14629758 + 1);
    }

    function test() public {
        bytes memory _message =
            hex"6265616d000000000000000000000000d3dfd3ede74e0dcebc1aa685e151332857efce2d000013d60065746800000000000000000000000088a69b4e698a4b090df6cf5bd7b2d47325ad30a3006574680000000000000000000000002260fac5e5542a773aa44fbcfedf7c193bc2c59903000000000000000000000000f57113d8f6ff35747737f026fe0b37d4d7f4277700000000000000000000000000000000000000000000000000000002540be400e6e85ded018819209cfb948d074cb65de145734b5b0852e4a5db25cac2b8c39a";
        bytes29 _m = _message.ref(0);
        bytes32 _messageHash = _m.keccak();
        bytes32 _root = replica.messages(_messageHash);
        uint256 _time = replica.confirmAt(_root);

        emit log_named_bytes32("_messageHash", _messageHash);
        emit log_named_bytes32("_root", _root);
        emit log_named_uint("_time", _time);
    }
}

interface IReplica {
    function messages(bytes32) external view returns (bytes32);
    function confirmAt(bytes32) external view returns (uint256);
}
