// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable2Step.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import './IPoolManager.sol';

contract G100 is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address[100] private addresses;
    IERC20 immutable usdt;
    IPoolManager poolManager;
    uint public totalLosted;

    uint public balanceFree;
    uint public price;
    uint public actualMaxRoof;
    bool public availableToBuy;

    mapping(address => uint) public maxRoof;
    mapping(address => uint) public roofReached;
    mapping(address => uint) public claimAvailable;
    mapping(address => bool) public hasPosition;

    event AddressChanged(
        uint indexed index,
        address indexed previousAddress,
        address indexed newAddress
    );

    constructor(address _usdt) Ownable(msg.sender) {
        require(_usdt != address(0), 'USDT address cannot be zero');
        usdt = IERC20(_usdt);
    }
    function viewAddressByIndex(uint index) external view returns (address) {
        return addresses[index - 1];
    }
    function setPoolManager(address _poolManager) external onlyOwner {
        poolManager = IPoolManager(_poolManager);
    }

    function increaseBalance(uint amount) external {
        usdt.safeTransferFrom(msg.sender, address(this), amount);
        balanceFree += amount;
    }
    function setConfig(uint _price, uint _maxRoof) external onlyOwner {
        availableToBuy = true;
        price = _price;
        actualMaxRoof = _maxRoof;
    }
    function claim() external nonReentrant {
        if (balanceFree > 0) {
            distribute();
        }
        if (roofReached[msg.sender] == maxRoof[msg.sender]) {
            roofReached[msg.sender] = 0;
            maxRoof[msg.sender] = 0;
            hasPosition[msg.sender] = false;
        }
        uint valueToClaim = claimAvailable[msg.sender];
        claimAvailable[msg.sender] = 0;
        usdt.safeTransfer(msg.sender, valueToClaim);
    }

    function buyPosition() external nonReentrant {
        require(availableToBuy, 'Unavailable');
        require(!hasPosition[msg.sender], 'You can only buy one position');

        if (balanceFree > 0) {
            distribute();
        }
        for (uint i = 0; i < addresses.length; i++) {
            if (
                addresses[i] == address(0) ||
                roofReached[addresses[i]] >= maxRoof[addresses[i]]
            ) {
                addresses[i] = msg.sender;
                hasPosition[msg.sender] = true;
                roofReached[addresses[i]] = 0;
                maxRoof[addresses[i]] = actualMaxRoof;
                break;
            }
            if (i == 99) {
                revert('No positions to buy');
            }
        }
        usdt.safeTransferFrom(msg.sender, address(this), price);
        usdt.approve(address(poolManager), price);
        poolManager.increaseLiquidityReservePool(price);
    }
    function getAllAddresses() external view returns (address[100] memory) {
        return addresses;
    }
    function removePosition(uint index) external onlyOwner {
        require(index <= 100, 'Invalid index');
        address removedAddress = addresses[index - 1];
        if (removedAddress != address(0)) {
            addresses[index - 1] = address(0);
            hasPosition[removedAddress] = false;
            emit AddressChanged(index, removedAddress, address(0));

            maxRoof[removedAddress] = 0;
            roofReached[removedAddress] = 0;
            claimAvailable[removedAddress] = 0;
        }
    }

    function distribute() internal {
        uint individualValue = balanceFree / 100;
        uint excess;
        balanceFree = 0;
        for (uint i = 0; i < addresses.length; i++) {
            if (
                roofReached[addresses[i]] + individualValue >=
                maxRoof[addresses[i]]
            ) {
                uint value = maxRoof[addresses[i]] - roofReached[addresses[i]];
                roofReached[addresses[i]] += value;
                claimAvailable[addresses[i]] += value;
                excess += individualValue - value;
            } else {
                roofReached[addresses[i]] += individualValue;
                claimAvailable[addresses[i]] += individualValue;
            }
        }
        if (excess > 0) {
            usdt.approve(address(poolManager), excess);
            totalLosted += excess;
            poolManager.increaseLiquidityReservePool(excess);
        }
    }
}
