// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SharpToken is ERC20Burnable, Ownable {
    uint256 private constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18;
    uint256 public constant ANNUAL_REWARD_RATE = 10; // 10% annual reward
    uint256 public constant SECONDS_IN_YEAR = 365 days;

    struct Stake {
        uint256 amount;
        uint256 lastStakedTime;
        uint256 rewardDebt;
    }

    mapping(address => Stake) public stakes;

    constructor() ERC20("SHARP", "SHARP") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    // Stake tokens
    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        // Transfer tokens to contract
        _transfer(msg.sender, address(this), amount);

        // Calculate and store previous rewards
        uint256 pendingRewards = calculateRewards(msg.sender);
        stakes[msg.sender].rewardDebt += pendingRewards;

        // Update stake
        stakes[msg.sender].amount += amount;
        stakes[msg.sender].lastStakedTime = block.timestamp;
    }

    // Calculate staking rewards
    function calculateRewards(address user) public view returns (uint256) {
        Stake memory userStake = stakes[user];
        if (userStake.amount == 0) {
            return 0;
        }

        uint256 stakingDuration = block.timestamp - userStake.lastStakedTime;
        uint256 reward = (userStake.amount * ANNUAL_REWARD_RATE * stakingDuration) 
                         / (100 * SECONDS_IN_YEAR);
        return reward;
    }

    // Claim staking rewards
    function claimRewards() external {
        uint256 rewards = calculateRewards(msg.sender) + stakes[msg.sender].rewardDebt;
        require(rewards > 0, "No rewards available");
        require(balanceOf(address(this)) >= rewards, "Insufficient contract balance for rewards");

        // Reset rewards
        stakes[msg.sender].rewardDebt = 0;
        stakes[msg.sender].lastStakedTime = block.timestamp;

        _mint(msg.sender, rewards);
    }

    // Unstake tokens with rewards
    function unstake() external {
        Stake storage userStake = stakes[msg.sender]; 
        require(userStake.amount > 0, "No staked amount");

        uint256 rewards = calculateRewards(msg.sender) + userStake.rewardDebt;
        uint256 amountToUnstake = userStake.amount;

        require(balanceOf(address(this)) >= amountToUnstake + rewards, "Insufficient contract balance");

        // Reset stake
        userStake.amount = 0;
        userStake.rewardDebt = 0;
        userStake.lastStakedTime = 0;

        // Transfer staked tokens back
        _transfer(address(this), msg.sender, amountToUnstake);

        // Mint rewards
        _mint(msg.sender, rewards);
    }
}
