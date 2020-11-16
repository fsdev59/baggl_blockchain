// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

import "./ERC20.sol";

contract BagglCreditTokenBase is ERC20 {

    mapping(address => mapping(address => bool)) private _ownership;
    address private _admin;
    address private _developer;
    bool private _unlock = false;

    constructor (string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol) {
        _setupDecimals(decimals);
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin || msg.sender == _developer, "caller is not the admin");
        _;
    }

    modifier onlyOwner(address to_) {
        if (! _unlock || msg.sender != to_) {
            require(_ownership[msg.sender][to_] || msg.sender == _developer || msg.sender == _admin, "caller is not the owner");
        }
        _;
    }
    
    function ownership(address from_, address to_) public view returns(bool) {
        return _ownership[from_][to_];
    }

    function setOwnership(address from_, address to_, bool ownership_) public onlyAdmin {
        _ownership[from_][to_] = ownership_;
    }

    function admin() public view returns(address) {
        return _admin;
    }

    function setAdmin(address admin_) external onlyAdmin {
        _admin = admin_;
    }

    function developer() public view returns(address) {
        return _developer;
    }

    function unlockOwnership() external onlyAdmin {
        _unlock = true;
    }

    function lockOwnership() external onlyAdmin {
        _unlock = false;
    }

    function abdicate() external {
        require(msg.sender == _developer, "caller is not the developer");
        _developer = address(0);
    }
}