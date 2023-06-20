// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VaultToken is ERC20, Ownable {
    constructor() ERC20("VaultToken", "VT") {}

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burnAccount(address account) public onlyOwner {
        _burn(account, balanceOf(account));
    }
}

contract Vault is ReentrancyGuard {
    VaultToken public vaultToken;

    constructor() {
        vaultToken = new VaultToken();
    }

    function deposit() public payable nonReentrant {
        vaultToken.mint(msg.sender, msg.value);
    }

    function withdrawAll() public nonReentrant {
        require(vaultToken.balanceOf(msg.sender) > 0);
        (bool success,) = msg.sender.call{value: vaultToken.balanceOf(msg.sender)}("");
        require(success);
        vaultToken.burnAccount(msg.sender);
    }
}

contract Setup {
    Vault public vault;
    uint256 initialDeposit;

    constructor() payable {
        vault = new Vault();
        vault.deposit{value: msg.value}();
        initialDeposit = msg.value;
    }

    function isSolved() public view returns (bool) {
        return address(vault).balance == 0 && msg.sender.balance >= initialDeposit;
    }
}
