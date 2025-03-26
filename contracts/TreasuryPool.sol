// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable2Step.sol';
import './IBurnable.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import './IPoolManager.sol';
library Donation {
    struct UserDonation {
        uint id;
        uint deposit;
        uint balance;
        uint startedTimestamp;
        uint lastClaimTimestamp;
        uint daysPaid;
        uint[] claimsTimestamp;
        uint[] claimPrice;
        uint[] claims;
    }
}

contract TreasuryPool is ReentrancyGuard, Ownable2Step {
    using SafeERC20 for IBurnable;
    using SafeERC20 for IERC20;

    event UserContributed(address indexed user, uint amount);
    event UserClaimed(address indexed user, uint amount);
    event Burn(uint indexed amount);

    uint24 private constant CLAIM_PERIOD = 1 days;
    uint8 private constant MAX_PERIOD = 150;
    uint8 public percentageSlippage = 110;

    IBurnable private immutable token;
    IPoolManager private immutable poolManager;
    IERC20 private immutable usdt;

    uint256 public distributionBalance;

    mapping(address => mapping(uint => Donation.UserDonation)) private users;
    mapping(address => uint) public userTotalContributions;
    mapping(address => uint) public userTotalContributionsValue;
    mapping(address => uint) public userTotalEarned;
    mapping(address => uint) public activeContributionsQuantity;

    constructor(
        address _token,
        address _usdt,
        address _poolManager
    ) Ownable(msg.sender) {
        token = IBurnable(_token);
        usdt = IERC20(_usdt);
        poolManager = IPoolManager(_poolManager);
    }

    function isUserActive(address user) external view returns (bool) {
        if (userTotalContributions[user] == 0) {
            return false;
        }
        Donation.UserDonation memory donation = users[user][
            userTotalContributions[user]
        ];
        if (
            donation.startedTimestamp + CLAIM_PERIOD * MAX_PERIOD >
            block.timestamp
        ) {
            return true;
        } else {
            return false;
        }
    }

    function addDistributionFunds(uint256 amount) external {
        token.safeTransferFrom(msg.sender, address(this), amount);
        distributionBalance += amount;
    }

    function changeSlippage(uint8 newSlippage) external onlyOwner {
        percentageSlippage = newSlippage;
    }

    function timeUntilNextWithdrawal(
        address user,
        uint index
    ) public view returns (uint256) {
        require(
            index > 0 && index <= userTotalContributions[user],
            'Invalid Index'
        );
        Donation.UserDonation memory userDonation = users[user][index];
        if (userDonation.daysPaid == MAX_PERIOD) {
            return 0;
        }
        uint daysElapsed = calculateDaysElapsedToClaim(user, index);
        if (daysElapsed >= MAX_PERIOD) {
            return 0;
        }
        uint amount = calculateValue(user, index, daysElapsed);
        if (userDonation.daysPaid + daysElapsed == MAX_PERIOD) {
            return 0;
        }
        uint balance = users[user][index].deposit;
        uint roof = 10e6;
        if (balance >= 1000e6) {
            roof = balance / 10;
        }
        if (amount < roof) {
            while (amount < roof) {
                ++daysElapsed;
                if (userDonation.daysPaid + daysElapsed == MAX_PERIOD) {
                    return
                        (daysElapsed * CLAIM_PERIOD) -
                        (block.timestamp - userDonation.lastClaimTimestamp);
                }
                amount = calculateValue(user, index, daysElapsed);
            }

            return
                (daysElapsed * CLAIM_PERIOD) -
                (block.timestamp - userDonation.lastClaimTimestamp);
        } else {
            return 0;
        }
    }

    function contribute(uint amount) external nonReentrant {
        require(
            poolManager.isFaceIdVerified(msg.sender),
            'User not verified face id'
        );
        require(amount >= 10e6, 'Amount must be greater than 10 dollars');

        ++userTotalContributions[msg.sender];
        uint contributionId = userTotalContributions[msg.sender];
        userTotalContributionsValue[msg.sender] += amount;
        ++activeContributionsQuantity[msg.sender];
        users[msg.sender][contributionId].id = contributionId;
        users[msg.sender][contributionId].deposit = amount;

        users[msg.sender][contributionId].balance = (amount * 250) / 100;
        users[msg.sender][contributionId].startedTimestamp = block.timestamp;
        users[msg.sender][contributionId].lastClaimTimestamp = block.timestamp;

        uint burnedAmount;
        uint rechargedPool;
        usdt.safeTransferFrom(msg.sender, address(this), amount);

        usdt.approve(address(poolManager), amount);
        poolManager.increaseLiquidityDevPool(amount / 10, address(usdt));
        poolManager.increaseLiquidityReservePool(amount / 5);

        uint amountToken = poolManager.swap(
            address(usdt),
            address(token),
            10000,
            (amount * 325) / 1000,
            address(this)
        );
        burnedAmount = ((amountToken * 3076) / 10000);
        rechargedPool = ((amountToken * 3076) / 10000);

        token.approve(address(poolManager), amountToken);
        poolManager.increaseLiquidityPoolUniswap(
            (amount * 125) / 1000,
            ((amountToken * 3848) / 10000)
        );
        poolManager.distributeUnilevelUsdt(msg.sender, (amount * 25) / 100);

        emit Burn(burnedAmount);

        emit UserContributed(msg.sender, amount);
        token.burn(burnedAmount);
        poolManager.increaseLiquidityPool2(rechargedPool);
    }

    function getActiveContributions(
        address user,
        uint startIndex
    ) public view returns (Donation.UserDonation[] memory) {
        if (userTotalContributions[user] == 0) {
            Donation.UserDonation[] memory arr;
            return arr;
        }
        require(startIndex > 0, 'Start index > 0');
        require(
            startIndex <= userTotalContributions[user],
            'Start index is out of bounds'
        );

        uint totalContributions = userTotalContributions[user];
        uint maxActiveContributions = 50;
        Donation.UserDonation[]
            memory tempContributions = new Donation.UserDonation[](
                maxActiveContributions
            );

        uint count = 0;
        for (
            uint i = startIndex;
            i <= totalContributions && count < maxActiveContributions;
            i++
        ) {
            if (users[user][i].daysPaid < MAX_PERIOD) {
                tempContributions[count] = users[user][i];
                count++;
            }
        }

        Donation.UserDonation[]
            memory activeContributions = new Donation.UserDonation[](count);
        for (uint j = 0; j < count; j++) {
            activeContributions[j] = tempContributions[j];
        }

        return activeContributions;
    }
    function getInactiveContributions(
        address user,
        uint startIndex
    ) public view returns (Donation.UserDonation[] memory) {
        if (userTotalContributions[user] == 0) {
            Donation.UserDonation[] memory arr;
            return arr;
        }
        require(startIndex > 0, 'Start index > 0');
        require(
            startIndex <= userTotalContributions[user],
            'Start index is out of bounds'
        );

        uint totalContributions = userTotalContributions[user];
        uint maxInactiveContributions = 50;
        Donation.UserDonation[]
            memory tempContributions = new Donation.UserDonation[](
                maxInactiveContributions
            );

        uint count = 0;
        for (
            uint i = startIndex;
            i <= totalContributions && count < maxInactiveContributions;
            i++
        ) {
            if (users[user][i].daysPaid == MAX_PERIOD) {
                tempContributions[count] = users[user][i];
                count++;
            }
        }

        Donation.UserDonation[]
            memory inactiveContributions = new Donation.UserDonation[](count);
        for (uint j = 0; j < count; j++) {
            inactiveContributions[j] = tempContributions[j];
        }

        return inactiveContributions;
    }

    function calculateDaysElapsedToClaim(
        address user,
        uint index
    ) public view returns (uint) {
        require(
            index > 0 && index <= userTotalContributions[user],
            'Invalid Index'
        );
        uint daysElapsed = (block.timestamp -
            users[user][index].lastClaimTimestamp) / CLAIM_PERIOD;
        if (daysElapsed + users[user][index].daysPaid > MAX_PERIOD) {
            return MAX_PERIOD - users[user][index].daysPaid;
        } else {
            return daysElapsed;
        }
    }

    function getNextClaim(
        address user,
        uint startIndex
    ) external view returns (Donation.UserDonation memory contribution) {
        require(
            startIndex > 0 && startIndex <= userTotalContributions[user],
            'Invalid Index'
        );
        if (userTotalContributions[user] == 0) {
            Donation.UserDonation memory auxContribution;
            return auxContribution;
        }
        uint count = 0;
        uint totalContributions = userTotalContributions[user];
        uint maxActiveContributions = 50;

        for (
            uint i = startIndex;
            i <= totalContributions && count < maxActiveContributions;
            i++
        ) {
            if (users[user][i].daysPaid < MAX_PERIOD) {
                uint time = timeUntilNextWithdrawal(user, i);
                if (
                    contribution.id == 0 ||
                    time < timeUntilNextWithdrawal(user, contribution.id)
                ) {
                    contribution = getUser(user, i);
                }
            }
            ++count;
        }
    }

    function previewClaim(
        address user,
        uint index
    ) external view returns (uint valueUsdt) {
        require(
            index > 0 && index <= userTotalContributions[user],
            'Invalid Index'
        );
        if (userTotalContributions[user] == 0) {
            return (0);
        }
        Donation.UserDonation memory userDonation = users[user][index];
        if (userDonation.daysPaid == MAX_PERIOD) {
            return (0);
        }
        uint daysElapsed = calculateDaysElapsedToClaim(user, index);
        uint amount = calculateValue(user, index, daysElapsed);

        if (userDonation.daysPaid + daysElapsed == MAX_PERIOD) {
            return (amount);
        }
        uint roof = 10e6;
        uint balance = users[user][index].deposit;
        if (balance >= 1000e6) {
            roof = balance / 10;
        }
        if (amount < roof) {
            while (amount < roof) {
                ++daysElapsed;
                amount = calculateValue(user, index, daysElapsed);

                if (userDonation.daysPaid + daysElapsed == MAX_PERIOD) {
                    return (amount);
                }
            }
        }
        return (amount);
    }

    function calculateDailyGain(
        address user,
        uint startIndex
    ) external view returns (uint dailyGainUs) {
        require(
            startIndex > 0 && startIndex <= userTotalContributions[user],
            'Invalid Index'
        );
        uint count = 0;
        uint totalContributions = userTotalContributions[user];
        uint maxActiveContributions = 50;
        for (
            uint i = startIndex;
            i <= totalContributions && count < maxActiveContributions;
            i++
        ) {
            uint daysElapsed = calculateDaysElapsedToClaim(user, i);

            if (users[user][i].daysPaid + daysElapsed < MAX_PERIOD) {
                dailyGainUs += users[user][i].balance / MAX_PERIOD;
            }
            ++count;
        }
    }

    function calculateValue(
        address user,
        uint index,
        uint daysElapsed
    ) internal view returns (uint) {
        require(
            index > 0 && index <= userTotalContributions[user],
            'Invalid Index'
        );
        return (users[user][index].balance * daysElapsed) / MAX_PERIOD;
    }

    function claimContribution(uint index) external nonReentrant {
        require(
            poolManager.isFaceIdVerified(msg.sender),
            'User not verified face id'
        );
        require(index <= userTotalContributions[msg.sender], 'Invalid index');

        Donation.UserDonation memory userDonation = users[msg.sender][index];
        require(userDonation.daysPaid < MAX_PERIOD, 'Already claimed');

        uint daysElapsed = calculateDaysElapsedToClaim(msg.sender, index);
        require(daysElapsed > 0, 'Tokens are still locked');

        users[msg.sender][index].daysPaid += daysElapsed;
        users[msg.sender][index].lastClaimTimestamp =
            users[msg.sender][index].startedTimestamp +
            (users[msg.sender][index].daysPaid * CLAIM_PERIOD);
        uint totalValueInUSD = calculateValue(msg.sender, index, daysElapsed);
        uint balance = users[msg.sender][index].deposit;
        if (balance >= 1000e6) {
            require(
                totalValueInUSD >= balance / 10 ||
                    users[msg.sender][index].daysPaid == MAX_PERIOD,
                'Minimum accumulated to claim is 10% of participation'
            );
        } else {
            require(
                totalValueInUSD >= 10e6 ||
                    users[msg.sender][index].daysPaid == MAX_PERIOD,
                'Minimum accumulated to claim is 10 dollars'
            );
        }

        userTotalEarned[msg.sender] += totalValueInUSD;
        uint currentPrice = poolManager.getAmountValue(1 ether);
        uint totalTokensToSend = (totalValueInUSD * 1e18) / currentPrice;
        require(
            distributionBalance >= totalTokensToSend,
            'Insufficient token balance for distribution'
        );

        if (users[msg.sender][index].daysPaid == MAX_PERIOD) {
            --activeContributionsQuantity[msg.sender];
        }
        uint tokensToSwap = (totalTokensToSend * percentageSlippage) / 100;
        token.approve(address(poolManager), tokensToSwap);
        uint amountIn = poolManager.swapOut(
            address(token),
            address(usdt),
            10000,
            address(this),
            totalValueInUSD,
            tokensToSwap
        );
        distributionBalance -= amountIn;

        users[msg.sender][index].claims.push((totalTokensToSend));
        users[msg.sender][index].claimPrice.push((currentPrice));
        users[msg.sender][index].claimsTimestamp.push(block.timestamp);
        uint fee = totalValueInUSD / 20;
        usdt.approve(address(poolManager), fee);
        poolManager.increaseLiquidityDevPool(fee, address(usdt));
        usdt.safeTransfer(msg.sender, (totalValueInUSD - fee));

        emit UserClaimed(msg.sender, totalValueInUSD);
    }

    function getUser(
        address _user,
        uint index
    ) public view returns (Donation.UserDonation memory) {
        require(
            index > 0 && index <= userTotalContributions[_user],
            'Invalid Index'
        );
        Donation.UserDonation memory userDonation = users[_user][index];
        return userDonation;
    }
}
