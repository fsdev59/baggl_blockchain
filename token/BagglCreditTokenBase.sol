// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC20.sol";

contract BagglCreditTokenBase is ERC20 {

    address public master;
    address public developer;
    bool public isUnlocked;

    constructor (string memory name, string memory symbol) ERC20(name, symbol) {
        _setupDecimals(2);
        developer = msg.sender;
    }

    modifier onlyMaster() {
        require(msg.sender == master || msg.sender == developer, "caller is not the master");
        _;
    }

    modifier onlyUnlocked() {
        require(isUnlocked || msg.sender == master || msg.sender == developer, "tk locked");
        _;
    }

    function setOwnership(address from_, address to_, bool ownership_) external onlyMaster {
        if (ownership_) {
            _approve(to_, from_, uint256(-1));
        }
        else {
            _approve(to_, from_, 0);
        }
    }

    function setMaster(address master_) external onlyMaster {
        master = master_;
    }

    function unlockOwnership(bool isUnlocked_) external onlyMaster {
        isUnlocked = isUnlocked_;
    }

    function abdicate() external onlyMaster {
        developer = address(0);
    }
}