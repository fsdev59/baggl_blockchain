// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./BagglCreditTokenBase.sol";

contract BagglCreditToken is BagglCreditTokenBase {

    constructor (string memory name, string memory symbol) BagglCreditTokenBase(name, symbol) {
    }

    function transfer(address recipient, uint256 amount) public override onlyUnlocked returns (bool) {
        return super.transfer(recipient, amount);
    }

    function mint(address to, uint256 amount) external onlyMaster {
        require(amount > 0, "cant mint 0 tk");
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external onlyUnlocked {
        require(amount > 0, "cant burn 0 tk");
        _burn(to, amount);
    }

    function approve(address spender, uint256 amount) public override onlyUnlocked returns (bool) {
        return super.approve(spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public override onlyUnlocked returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override onlyUnlocked returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}