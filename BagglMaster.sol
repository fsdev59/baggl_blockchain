// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

// import "./token/BagglCreditToken.sol";
// import "./token/ERC20.sol";
import "./library/SafeMath.sol";

interface BagglCreditToken {
    function mint(address, uint256) external;
    function ownership(address, address) external view returns(bool);
    function setMaster(address) external;
    function unlockOwnership(bool) external;
    function abdicate() external;
    function setOwnership(address, address, bool) external;
    function balanceOf(address) external returns(uint256);
    function burn(address, uint256) external;
    function transferFrom(address, address, uint256) external;
}

contract BagglMaster {
    using SafeMath for uint256;

    BagglCreditToken public token;

    enum UserType {USER, BUSINESS_ADMIN, BUSINESS_ROLES}

    enum UserState {NORMAL, PAUSED, DELETED}

    mapping(address => uint256) public debit;
    mapping(address => UserType) public userTypes;
    mapping(address => address) public referrer;
    mapping(address => UserState) public userStates;
    mapping(address => address) public owners;

    address public gov;
    address public developer;

    uint256 public initialUserCredit = 15000;
    uint256 public referralBonus = 5000;
    uint32 public combinedFeeRatio = 200;
    uint32 public tradeFeeRatio = 100;
    uint32 public constant feeMax = 10000;

    event MadeTransaction(
        uint256 transaction_id
    );

    event RefundedTransaction(
        uint256 transaction_id
    );

    modifier onlyGov() {
        require(
            msg.sender == gov || msg.sender == developer,
            "only gov"
        );
        _;
    }

    modifier onlyNormal(address address_) {
        require(
            userStates[address_] == UserState.NORMAL,
            "only normal"
        );
        _;
    }

    modifier onlyNew(address address_) {
        require(
            owners[address_] == address(0) &&
            userStates[address_] == UserState.NORMAL,
            "only new"
        );
        _;
    }

    modifier onlyExist(address address_) {
        require(owners[address_] != address(0), "only exist");
        _;
    }

    constructor(address token_) {
        developer = msg.sender;
        token = BagglCreditToken(token_);
    }

    function setToken(address token_) external onlyGov {
        token = BagglCreditToken(token_);
    }

    function setGov(address gov_) external onlyGov {
        gov = gov_;
    }

    function setMaster(address master_) external onlyGov {
        token.setMaster(master_);
    }

    function unlockOwnership(bool isUnlocked_) external onlyGov {
        token.unlockOwnership(isUnlocked_);
    }

    function abdicate() external {
        require(msg.sender == developer, "only dev");
        developer = address(0);
        token.abdicate();
    }

    function setInitialUserCredit(uint256 amount_) external onlyGov {
        initialUserCredit = amount_;
    }

    function setReferralBonus(uint256 amount_) external onlyGov {
        referralBonus = amount_;
    }

    function setCombinedFeeRatio(uint32 feeRatio_) external onlyGov {
        require(feeRatio_ < feeMax, "too high f_ratio");
        combinedFeeRatio = feeRatio_;
    }

    function setTradeFeeRatio(uint32 feeRatio_) external onlyGov {
        require(feeRatio_ < feeMax, "too high f_ratio");
        tradeFeeRatio = feeRatio_;
    }

    function setOwnership(
        address owner_,
        address address_,
        bool ownership_
    ) internal {
        if (ownership_) {
            owners[address_] = owner_;
            token.setOwnership(address(this), address_, true);
        } else {
            owners[address_] = address(0);
        }
        if (owner_ != address(this)) {
            token.setOwnership(owner_, address_, ownership_);
        }
    }

    function registerUser(address user_) external onlyGov onlyNew(user_) {
        if (initialUserCredit > 0) {
            token.mint(user_, initialUserCredit);
        }
        setOwnership(address(this), user_, true);
    }

    function registerAdmin(address admin_) public onlyGov onlyNew(admin_) {
        userTypes[admin_] = UserType.BUSINESS_ADMIN;
        if (initialUserCredit > 0) {
            token.mint(admin_, initialUserCredit);
        }
        setOwnership(address(this), admin_, true);
    }

    function registerAdminWithReferrer(address admin_, address referrer_)
        external
        onlyExist(referrer_)
        onlyNormal(referrer_)
    {
        require(
            userTypes[referrer_] != UserType.BUSINESS_ROLES,
            "roles can't refer"
        );
        registerAdmin(admin_);
        referrer[admin_] = referrer_;
        if (referralBonus > 0) {
            token.mint(referrer_, referralBonus);
        }
    }

    function registerRoles(address admin_, address roles_)
        external
        onlyExist(admin_)
        onlyNormal(admin_)
        onlyNew(roles_)
    {
        require(
            (userTypes[msg.sender] == UserType.BUSINESS_ADMIN &&
                msg.sender == admin_) ||
                msg.sender == gov ||
                msg.sender == developer,
            "not business admin"
        );
        userTypes[roles_] = UserType.BUSINESS_ROLES;
        setOwnership(admin_, roles_, true);
        token.setOwnership(address(this), roles_, true);
    }

    function pauseUser(address to_)
        external
        onlyGov
        onlyExist(to_)
        onlyNormal(to_)
    {
        userStates[to_] = UserState.PAUSED;
    }

    function resumeUser(address to_)
        external
        onlyGov
        onlyExist(to_)
    {
        require(userStates[to_] == UserState.PAUSED, "not paused");
        userStates[to_] = UserState.NORMAL;
    }

    function deleteUser(address to_)
        external
        onlyGov
        onlyExist(to_)
    {
        require(userStates[to_] != UserState.DELETED, "not deleted");
        userStates[to_] = UserState.DELETED;
        if (token.balanceOf(to_) > 0) {
            if (owners[to_] == address(this)) {
                token.burn(to_, token.balanceOf(to_));
            } else {
                token.transferFrom(to_, owners[to_], token.balanceOf(to_));
            }
        }
        setOwnership(owners[to_], to_, false);
    }

    function makeCombinedTransaction(
        address buyer,
        address seller,
        uint256 fullAmount,
        uint256 creditAmount,
        uint256 transaction_id
    ) external onlyGov {
        require(creditAmount > 0, "can't make 0 tk txn");
        uint256 feeAmount = fullAmount.mul(combinedFeeRatio).div(feeMax);
        if (creditAmount < feeAmount) {
            uint256 realAmount = feeAmount.sub(creditAmount);
            token.burn(buyer, creditAmount);
            token.burn(seller, realAmount);
        }
        else {
            uint256 realAmount = creditAmount.sub(feeAmount);
            token.burn(buyer, creditAmount);
            token.mint(seller, realAmount);
        }
        emit MadeTransaction(transaction_id);
    }

    function makeTradeOnlyTransaction(
        address buyer,
        address seller,
        uint256 amount,
        uint256 transaction_id
    ) external onlyGov {
        require(amount > 0, "can't make 0 tk txn");
        uint256 feeAmount = amount.mul(tradeFeeRatio).div(feeMax);
        uint256 realAmount = amount.add(feeAmount);
        token.burn(buyer, realAmount);
        token.mint(seller, amount);
        emit MadeTransaction(transaction_id);
    }

    function refundCombinedTransaction(
        address buyer,
        address seller,
        uint256 fullAmount,
        uint256 creditAmount,
        uint256 transaction_id
    ) external onlyGov {
        require(creditAmount > 0, "can't make 0 tk txn");
        uint256 feeAmount = fullAmount.mul(combinedFeeRatio).div(feeMax);
        if (creditAmount < feeAmount) {
            uint256 realAmount = feeAmount.sub(creditAmount);
            token.mint(buyer, creditAmount);
            token.mint(seller, realAmount);
        }
        else {
            uint256 realAmount = creditAmount.sub(feeAmount);
            token.mint(buyer, creditAmount);
            token.burn(seller, realAmount);
        }
        emit RefundedTransaction(transaction_id);
    }

    function refundTradeOnlyTransaction(
        address buyer,
        address seller,
        uint256 amount,
        uint256 transaction_id
    ) external onlyGov {
        require(amount > 0, "can't make 0 tk txn");
        uint256 feeAmount = amount.mul(tradeFeeRatio).div(feeMax);
        uint256 realAmount = amount.add(feeAmount);
        token.mint(buyer, realAmount);
        token.burn(seller, amount);
        emit RefundedTransaction(transaction_id);
    }

    function mintToken(address buyer, uint256 amount) external onlyGov { // sendCommission
        token.mint(buyer, amount);
    }

    function burnToken(address seller, uint256 amount) external onlyGov {
        token.burn(seller, amount);
    }

    function transferToken(address from, address to, uint256 amount) external onlyGov {
        token.transferFrom(from, to, amount);
    }

    function loanCredit(address admin, uint256 amount) external onlyGov {
        require(userTypes[admin] == UserType.BUSINESS_ADMIN, "only admin can loan");
        token.mint(admin, amount);
        debit[admin] = debit[admin].add(amount);
    }

    function paybackCredit(address admin, uint256 amount) external onlyGov {
        if (amount < debit[admin]) {
            token.burn(admin, amount);
            debit[admin] = debit[admin].sub(amount);
        }
        else {
            token.burn(admin, debit[admin]);
            debit[admin] = 0;
        }
    }
}
