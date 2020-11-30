// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./BagglCreditTokenBase.sol";

contract BagglCreditToken is BagglCreditTokenBase {

    constructor (string memory name, string memory symbol, uint8 decimals) BagglCreditTokenBase(name, symbol, decimals) {
        
    }

    function transfer(address recipient, uint256 amount) public override onlyTransferable(recipient) returns (bool) {
        return super.transfer(recipient, amount);
    }

    function mint(address to, uint256 amount) external onlyMaster {
        require(amount > 0, "cant mint 0 tk");
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external onlyOwner(to) {
        require(amount > 0, "cant burn 0 tk");
        _burn(to, amount);
    }
}