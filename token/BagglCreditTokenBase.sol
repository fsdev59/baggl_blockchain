// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC20.sol";

contract BagglCreditTokenBase is ERC20 {

    mapping(address => mapping(address => bool)) private _ownership;

    address private _master;
    address private _developer;
    bool private _unlock;

    constructor (string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol) {
        _setupDecimals(decimals);
        _developer = msg.sender;
    }

    modifier onlyMaster() {
        require(msg.sender == _master || msg.sender == _developer, "caller is not the master");
        _;
    }

    modifier onlyOwner(address to_) {
        require(ownership(msg.sender, to_) || msg.sender == _developer || msg.sender == _master, "caller is not the owner");
        _;
    }

    modifier onlyTransferable(address to_) {
        require(_unlock || ownership(msg.sender, to_) || msg.sender == _master || msg.sender == _developer, "transfer locked");
        _;
    }
    
    function ownership(address from_, address to_) public view returns(bool) {
        if (_unlock && from_ == to_) {
            return true;
        }
        else {
            return _ownership[from_][to_];
        }
    }

    function setOwnership(address from_, address to_, bool ownership_) external onlyMaster {
        if (ownership_) {
            _approve(to_, from_, uint256(-1));
        }
        else {
            _approve(to_, from_, 0);
        }
        _ownership[from_][to_] = ownership_;
    }

    function master() external view returns(address) {
        return _master;
    }

    function setMaster(address master_) external onlyMaster {
        _master = master_;
    }

    function developer() external view returns(address) {
        return _developer;
    }

    function isUnlocked() external view returns(bool) {
        return _unlock;
    }

    function unlockOwnership() external onlyMaster {
        _unlock = true;
    }

    function lockOwnership() external onlyMaster {
        _unlock = false;
    }

    function abdicate() external onlyMaster {
        _developer = address(0);
    }
}