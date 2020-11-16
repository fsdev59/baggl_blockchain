// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

import "./BagglCreditTokenBase.sol";

contract BagglCreditToken is BagglCreditTokenBase {

    constructor (string memory name, string memory symbol, uint8 decimals) BagglCreditTokenBase(name, symbol, decimals) {
        
    }

    function transfer(address recipient, uint256 amount) public override onlyOwner(msg.sender) returns (bool) {
        super.transfer(recipient, amount);
    }

    function mint(address to, uint256 amount) public onlyAdmin {
        require(amount > 0, "can't mint 0 token");
        _mint(to, amount);
    }
}