// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./token/BagglCreditToken.sol";

contract BagglMaster {
    using SafeMath for uint256;

    BagglCreditToken token;

    enum UserType {USER, BUSINESS_ADMIN, BUSINESS_ROLES}

    enum UserState {NORMAL, PAUSED, DELETED}

    mapping(address => uint256) private _debit;
    mapping(address => UserType) private _userTypes;
    mapping(address => address) private _referrer;
    mapping(address => UserState) private _userStates;
    mapping(address => address) private _owners;

    address private _gov;
    address private _developer;

    uint256 private _initialUserCredit = 15000;
    uint256 private _feeAmount = 5;
    uint256 private _feeMax = 100;

    modifier onlyGov() {
        require(
            msg.sender == _gov || msg.sender == _developer,
            "caller is not the gov"
        );
        _;
    }

    modifier onlyOwner(address to_) {
        require(
            token.ownership(msg.sender, to_) ||
                msg.sender == _developer ||
                msg.sender == _gov,
            "caller is not the owner"
        );
        _;
    }

    modifier onlyNormal(address address_) {
        require(
            _userStates[address_] == UserState.NORMAL ||
                msg.sender == _developer ||
                msg.sender == _gov,
            "not normal state"
        );
        _;
    }

    modifier onlyNew(address address_) {
        require(
            !token.ownership(address(this), address_),
            "already registered"
        );
        _;
    }

    modifier onlyExist(address address_) {
        require(token.ownership(address(this), address_), "not exist");
        _;
    }

    modifier onlyUnlocked() {
        require(token.isUnlocked(), "token locked");
        _;
    }

    function gov() public view returns (address) {
        return _gov;
    }

    function setGov(address gov_) external onlyGov {
        _gov = gov_;
    }

    function setMaster(address master_) external onlyGov {
        token.setMaster(master_);
    }

    function developer() public view returns (address) {
        return _developer;
    }

    function unlockOwnership() external onlyGov {
        token.unlockOwnership();
    }

    function lockOwnership() external onlyGov {
        token.lockOwnership();
    }

    function abdicate() external {
        require(msg.sender == _developer, "caller is not the developer");
        _developer = address(0);
        token.abdicate();
    }

    function setInitialUserCredit(uint256 amount_) external onlyGov {
        _initialUserCredit = amount_;
    }

    function initialUserCredit() public view returns (uint256) {
        return _initialUserCredit;
    }

    function setOwnership(
        address owner_,
        address address_,
        bool ownership_
    ) internal {
        if (ownership_) {
            _owners[address_] = owner_;
        } else {
            _owners[address_] = address(0);
        }
        token.setOwnership(owner_, address_, ownership_);
    }

    function registerUser(address user_)
        public
        onlyOwner(user_)
        onlyNew(user_)
    {
        if (_initialUserCredit > 0) {
            token.mint(user_, _initialUserCredit);
        }
        setOwnership(address(this), user_, true);
    }

    function registerAdmin(address admin_) public onlyGov onlyNew(admin_) {
        _userTypes[admin_] = UserType.BUSINESS_ADMIN;
        _owners[admin_] = address(this);
        setOwnership(address(this), admin_, true);
    }

    function registerAdminWithReferrer(address admin_, address referrer_)
        public
        onlyGov
        onlyNew(admin_)
        onlyExist(referrer_)
    {
        require(
            _userTypes[referrer_] != UserType.BUSINESS_ROLES,
            "roles can't refer"
        );
        registerAdmin(admin_);
        _referrer[admin_] = referrer_;
    }

    function registerRoles(address admin_, address roles_)
        public
        onlyNormal(admin_)
        onlyNew(roles_)
    {
        require(
            (_userTypes[msg.sender] == UserType.BUSINESS_ADMIN &&
                msg.sender == admin_) ||
                msg.sender == _gov ||
                msg.sender == _developer,
            "not business admin"
        );
        _userTypes[admin_] = UserType.BUSINESS_ROLES;
        setOwnership(admin_, roles_, true);
        setOwnership(address(this), roles_, true);
    }

    function transferFrom(address from_, uint256 amount_)
        public
        onlyNormal(msg.sender)
        onlyOwner(from_)
    {
        token.transferFrom(from_, msg.sender, amount_);
    }

    function transferTo(address to_, uint256 amount_)
        public
        onlyNormal(msg.sender)
        onlyOwner(to_)
    {
        token.transferFrom(msg.sender, to_, amount_);
    }

    function pauseUser(address to_) public onlyOwner(to_) onlyNormal(to_) {
        _userStates[to_] = UserState.PAUSED;
    }

    function resumeUser(address to_) public onlyOwner(to_) {
        require(_userStates[to_] == UserState.PAUSED, "not paused");
        _userStates[to_] = UserState.NORMAL;
    }

    function deleteUser(address to_) public onlyOwner(to_) {
        _userStates[to_] = UserState.DELETED;
        if (_owners[to_] == address(this)) {
            token.burn(to_, token.balanceOf(to_));
        } else {
            token.transferFrom(to_, _owners[to_], token.balanceOf(to_));
        }
        setOwnership(_owners[to_], to_, false);
    }
}
