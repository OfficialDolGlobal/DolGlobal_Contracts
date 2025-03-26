// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable2Step.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import './IPoolManager.sol';

contract G15 is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint128 public dailyPayment = 500e6;
    uint8 public constant MAX_QUANTITY_OF_USERS = 15;

    bool private roofReachedDaily;
    address[MAX_QUANTITY_OF_USERS] public addresses;
    IERC20 immutable usdt;
    IPoolManager poolManager;
    uint public totalLosted;
    address userContract;

    uint public balanceFree;

    mapping(address => uint) public claimAvailable;
    mapping(address => mapping(uint => bool)) public bought;

    event AddressChanged(
        uint indexed index,
        address indexed previousAddress,
        address indexed newAddress
    );

    constructor(address _usdt) Ownable(msg.sender) {
        require(_usdt != address(0), 'USDT address cannot be zero');
        usdt = IERC20(_usdt);
    }
    modifier onlyUserContract() {
        require(msg.sender == userContract, 'Only user contract');
        _;
    }

    function getDayStartTimestamp(uint timestamp) public pure returns (uint) {
        return timestamp - (timestamp % 1 days);
    }

    function setUserContract(address _userContract) external onlyOwner {
        userContract = _userContract;
    }
    function isRoofActivated() external view returns (bool) {
        return roofReachedDaily;
    }
    function activeRoof() external onlyUserContract {
        roofReachedDaily = true;
    }

    function setPoolManager(address _poolManager) external onlyOwner {
        poolManager = IPoolManager(_poolManager);
    }

    function increaseBalance(uint amount) external {
        usdt.safeTransferFrom(msg.sender, address(this), amount);
        balanceFree += amount;
    }
    function changeAddressByIndex(
        uint index,
        address newAddress
    ) external onlyOwner {
        require(index >= 1 && index <= MAX_QUANTITY_OF_USERS, 'Invalid index');
        if (balanceFree > 0) {
            distribute();
        }
        emit AddressChanged(index, addresses[index - 1], newAddress);
        addresses[index - 1] = newAddress;
    }

    function claim() external nonReentrant {
        if (balanceFree > 0) {
            distribute();
        }
        uint valueToClaim = claimAvailable[msg.sender];
        claimAvailable[msg.sender] = 0;
        usdt.safeTransfer(msg.sender, valueToClaim);
    }

    function distribute() internal {
        uint individualValue = balanceFree / MAX_QUANTITY_OF_USERS;
        uint excess;
        for (uint i = 0; i < addresses.length; i++) {
            if (roofReachedDaily) {
                if (
                    bought[addresses[i]][getDayStartTimestamp(block.timestamp)]
                ) {
                    claimAvailable[addresses[i]] += individualValue;
                } else {
                    excess += individualValue;
                }
                balanceFree -= individualValue;
            } else {
                if (addresses[i] != address(0)) {
                    claimAvailable[addresses[i]] += individualValue;
                } else {
                    excess += individualValue;
                }
                balanceFree -= individualValue;
            }
        }
        if (excess > 0) {
            usdt.approve(address(poolManager), excess);
            totalLosted += excess;
            poolManager.increaseLiquidityReservePool(excess);
        }
    }

    function setDailyPayment(uint128 newDailyPayment) external onlyOwner {
        dailyPayment = newDailyPayment;
    }
    function buyDailyRoof() external nonReentrant {
        require(
            !bought[msg.sender][getDayStartTimestamp(block.timestamp)],
            'Already Purchased'
        );
        distribute();
        usdt.safeTransferFrom(msg.sender, address(this), dailyPayment);
        bought[msg.sender][getDayStartTimestamp(block.timestamp)] = true;
        usdt.approve(address(poolManager), dailyPayment);
        poolManager.increaseLiquidityReservePool(dailyPayment);
    }

    function isUserInG15(address user) public view returns (bool) {
        for (uint i = 0; i < MAX_QUANTITY_OF_USERS; i++) {
            if (addresses[i] == user) {
                return true;
            }
        }
        return false;
    }
}
