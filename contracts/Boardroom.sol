// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IMinter.sol";

// MasterChef is the master of Reward. He can make Reward and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once REWARD is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract Boardroom is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lockTime;
        //
        // We do some fancy math here. Basically, any point in time, the amount of REWARDs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. REWARDs to distribute per block.
        uint256 lastRewardTimestamp; // Last block number that REWARDs distribution occurs.
        uint256 accRewardPerShare; // Accumulated REWARDs per share, times 1e12. See below.
    }

    struct BoardSnapshot {
        uint256 time;
        uint256 rewardReceived;
    }
    BoardSnapshot[] private boardHistory;


    // The REWARD TOKEN!
    IERC20 public reward;
    // Dev address.
    address public devaddr;
    // Dev balance
    uint256 public devbal;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // manage pool point
    address public pointManager;
    // lock period
    uint256 public lockPeriod;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        IERC20 _reward
    ) public {
        reward = _reward;
        devaddr = msg.sender;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardTimestamp: block.timestamp,
                accRewardPerShare: 0
            })
        );
    }

    // Update the given pool's REWARD allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public {
        require(msg.sender == owner() || msg.sender == pointManager, "on owner or manager");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to timestamp.
    function getRewardRate(uint256 _from, uint256 _to)
        public
        view
        returns (uint256) 
    {
        if (_to.sub(_from) == 0 || boardHistory.length == 0) {
            return 0;
        }

        uint256 rewardAmount = 0;
        uint256 idx = boardHistory.length;
        while (idx > 0) {
            BoardSnapshot storage snap = boardHistory[idx.sub(1)];
            if (_from >= snap.time) {
                break;
            }
            if (_to >= snap.time) {
                rewardAmount = rewardAmount.add(snap.rewardReceived);
            }
            idx = idx.sub(1);
        }
        return rewardAmount;
    }

    // View function to see pending REWARDs on frontend.
    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 rewardReward =
                getRewardRate(pool.lastRewardTimestamp, block.timestamp).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accRewardPerShare = accRewardPerShare.add(
                rewardReward.mul(9).div(10).mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 rewardReward =
                getRewardRate(pool.lastRewardTimestamp, block.timestamp).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
        devbal = devbal.add(rewardReward.div(10));
        pool.accRewardPerShare = pool.accRewardPerShare.add(
            rewardReward.mul(9).div(10).mul(1e12).div(lpSupply)
        );
        pool.lastRewardTimestamp = block.timestamp;
    }

    // Deposit LP tokens to MasterChef for REWARD allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accRewardPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeRewardTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        user.lockTime = block.timestamp;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(_amount == 0 || user.lockTime.add(lockPeriod) <= block.timestamp, "locked");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accRewardPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeRewardTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.lockTime.add(lockPeriod) <= block.timestamp, "locked");
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe reward transfer function, just in case if rounding error causes pool to not have enough REWARDs.
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = reward.balanceOf(address(this));
        if (_amount > rewardBal) {
            reward.transfer(_to, rewardBal);
        } else {
            reward.transfer(_to, _amount);
        }
    }

    // =============== GOV ==================
    // allocate reward
    function allocateReward(uint256 amount)
        external
    {
        require(msg.sender == owner() || msg.sender == pointManager, "on owner or manager");
        require(amount > 0, 'Boardroom: Cannot allocate 0');
        
        BoardSnapshot memory newSnapshot = BoardSnapshot({
            time: block.timestamp,
            rewardReceived: amount
        });
        boardHistory.push(newSnapshot);
        IMinter(address(reward)).mint(address(this), amount);
    }

    // set lock period
    function setLockPeriod(uint256 _period) public onlyOwner {
        lockPeriod = _period;
    }

    // set point manager
    function setPointManager(address _pointManager) public onlyOwner {
        pointManager = _pointManager;
    }

    // dev
    function dev(address _dev) public {
        require(msg.sender == devaddr || msg.sender == owner(), "dev: wut?");
        devaddr = _dev;
    }

    // dev claim reward
    function devReward(address _to, uint256 _amount) public {
        require(msg.sender == devaddr, "dev: wut?");
        devbal = devbal.sub(_amount);
        reward.safeTransfer(_to, _amount);
    }
}
