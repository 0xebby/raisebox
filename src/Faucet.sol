//SPDX-Lincense-Identifier: MIT
pragma solidity ^0.8.20;


contract MyFaucet{
    address faucetOwner;
    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply;
    uint256 public constant WITHDRAWAL_AMOUNT = 10 * 10**18;
    uint256 public constant COOLDOWN_PERIOD = 1 days;
    mapping (address => uint256) public lastWithdrawalTime;

    string tokenName;
    string tokenSymbol;
    uint8 public tokenDecimal = 18;

    // EVENTS

    event Minted(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    modifier onlyFaucetOwner {
        require(faucetOwner == msg.sender, "not faucet owner!");
        _;
    }


    constructor(string memory _tokenName, string memory _tokenSymbol) {
        faucetOwner = msg.sender;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
    }

    function mintTokensToFaucet(uint256 amount) external onlyFaucetOwner  {
        //checks
        require(amount > 0, "cannot mint zero amount of token");

        //effects
        balanceOf[address(this)] += amount;
        totalSupply += amount;

        //interactions

        emit Minted(address(this), amount);

    }

    function withdrawTokenFromFaucet(address user) public {
        // checks
        require(block.timestamp >= lastWithdrawalTime[msg.sender] + COOLDOWN_PERIOD, "cannot withdraw twice within 24 hours");
        require(balanceOf[address(this)] > WITHDRAWAL_AMOUNT, "Insufficient token in faucet");

        //effects/interactions

        lastWithdrawalTime[msg.sender] = block.timestamp;
        balanceOf[address(this)] -= WITHDRAWAL_AMOUNT;
        balanceOf[address(user)] += WITHDRAWAL_AMOUNT;

        emit Withdrawn(msg.sender, WITHDRAWAL_AMOUNT);
        
    }


    function getFaucetOwner() public view returns (address) {
        return address(faucetOwner);
    }



}

// import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
// import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
// import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

// contract StakingContract is Ownable, ReentrancyGuard {
//     IERC20 public stakingToken; // token to stake
//     IERC20 public rewardToken; // token used for rewards
//     uint256 public rewardRate; // reward per second of staking
//     uint256 public totalStaked; // total amout of staked tokens in contract


//     struct Stake {
//     uint256 amount;
//     uint256 lastUpdateTime;
//     uint256 pendingRewards;
    
// }

// mapping (address => Stake) public stakes;


// event Staked(address indexed user, uint256 amountStaked);
// event Withdrawn(address indexed user, uint256 amountWithdrawn);
// event RewardsClaimed(address indexed user, uint256 amountClaimed);

// constructor(address _stakingToken, address _rewardToken, uint256 _rewardRate) Ownable(msg.sender) {
//     stakingToken = IERC20(_stakingToken);
//     rewardToken = IERC20(_rewardToken);
//     rewardRate = _rewardRate;

// }

// function myStakeFunction(uint256 userStakeAmount) external {
//     // checks
//     require(userStakeAmount > 0, "cannot stake 0");

//     //effects
    
//     stakes[msg.sender].lastUpdateTime = block.timestamp; // this tracks when user staked so rewards based on timeinterval can be calculated
//     stakes[msg.sender].pendingRewards = calculateRewards(msg.sender); // this calculate rewards on staing and updates as time progresses or untill unstake
//     stakes[msg.sender].amount += userStakeAmount;
//     totalStaked += userStakeAmount;

//     //interactions
//     require(stakingToken.transferFrom(msg.sender, address(this), userStakeAmount), "staking failed");

//     emit Staked(msg.sender, userStakeAmount);

// }

// // calculate pending rewards for a staker

// function calculateRewards(address user) public view returns (uint256) {
//     Stake memory myStake = stakes[user];
//     if(myStake.amount == 0) return myStake.pendingRewards;

//     uint256 timeElapsed = block.timestamp - myStake.lastUpdateTime;
//     uint256 newRewards = myStake.amount * timeElapsed * rewardRate / 1e18; // scaled for precision
//     return myStake.pendingRewards + newRewards;
// }

// // stake tokens
// function stake(uint256 amount) external {
//     require(amount > 0, "cannot stake 0");

//     updateRewards(msg.sender);

//     require(stakingToken.transferFrom(msg.sender, address(this), amount), "transfer failed");

//     stakes[msg.sender].amount += amount;
//     totalStaked += amount;

//     emit Staked(msg.sender, amount);
// }

// // withdraw stakes
// function withdraw(uint256 amount) external nonReentrant {
//     require(amount > 0, "cannot withdraw 0 tokens");
//     require(stakes[msg.sender].amount >= amount, "insufficient stake");

//     updateRewards(msg.sender);

//     stakes[msg.sender].amount -= amount;
//     totalStaked -= amount;

//     require(stakingToken.transfer(msg.sender, amount), "tranfer failed");

//     emit Withdrawn(msg.sender, amount);
// }

// // claim accumulated rewards
// function claimRewards() external nonReentrant {
//     updateRewards(msg.sender);

//     uint256 rewards = stakes[msg.sender].pendingRewards;
//     require(rewards > 0, "no rewards to claim");

//     stakes[msg.sender].pendingRewards = 0;

//     require(rewardToken.transfer(msg.sender, rewards), "rewards transfer failed");

//     emit RewardsClaimed(msg.sender, rewards);
// }

// // internal function to update rewards
// function updateRewards(address user) internal {
//     stakes[user].pendingRewards = calculateRewards(user);
//     stakes[user].lastUpdateTime = block.timestamp;
// }

// // owner and only owner can update rewards rate
// function setRewardRate(uint256 _rewardRate) external onlyOwner {
//     rewardRate = _rewardRate; // this function directly update the reward rates that was declared in constructor during deployment???
// }






