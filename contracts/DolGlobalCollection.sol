// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ERC1155 } from '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable2Step.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import './IPoolManager.sol';
struct NftGlobalStruct {
    uint maxUnilevel;
    uint unilevelReached;
}

contract DolGlobalCollection is
    ERC1155,
    Ownable2Step,
    ERC1155Holder,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    IERC20 private immutable usdt;
    IERC20 private immutable dol;

    mapping(address => NftGlobalStruct) public users;
    IPoolManager private immutable poolManager;
    address private immutable userContract;

    constructor(
        address _usdt,
        address _poolManager,
        address _userContract,
        address _dol
    )
        ERC1155(
            'https://ipfs.io/ipfs/bafkreibrn7kjqh3mh7nhvu3thvcks4nr2nwbt4lol3xwhtqffxh7ljf6ge'
        )
        Ownable(msg.sender)
    {
        require(_poolManager != address(0), 'Invalid pool manager contract');
        require(_usdt != address(0), 'Invalid usdt contract');
        require(_userContract != address(0), 'Invalid user contract');
        require(_dol != address(0), 'Invalid dol contract');

        usdt = IERC20(_usdt);
        poolManager = IPoolManager(_poolManager);
        userContract = _userContract;
        dol = IERC20(_dol);
    }

    function mintNftGlobal(uint amount) external nonReentrant {
        require(
            poolManager.isFaceIdVerified(msg.sender),
            'User not verified face id'
        );
        require(poolManager.isUserActive(msg.sender), 'Inactive');
        require(amount >= 10e6, 'Minimum required is 10 USDT');

        if (users[msg.sender].maxUnilevel == 0) {
            _mint(msg.sender, 1, 1, '');
        }
        usdt.safeTransferFrom(msg.sender, address(this), amount);

        usdt.approve(address(poolManager), amount);

        poolManager.increaseLiquidityDevPool(
            (amount * 30) / 100,
            address(usdt)
        );
        poolManager.distributeUnilevelIguality(msg.sender, (amount) / 5);
        poolManager.increaseLiquidityMarketingPool(
            (amount) / 10,
            address(usdt)
        );
        uint amountOut = poolManager.swap(
            address(usdt),
            address(dol),
            10000,
            ((amount) * 3) / 10,
            address(this)
        );
        dol.approve(address(poolManager), amountOut);

        uint rechargeAmount = (amountOut * 2) / 3;
        uint uniswapLiquidityAmount = amountOut - ((amountOut * 2) / 3);

        poolManager.increaseLiquidityPool2(rechargeAmount);
        poolManager.increaseLiquidityPoolUniswap(
            (amount) / 10,
            uniswapLiquidityAmount
        );
        users[msg.sender].maxUnilevel += amount * 2;
    }

    function marketingBonus(address user, uint amount) external onlyOwner {
        users[user].maxUnilevel += amount;
    }

    function availableUnilevel(address user) external view returns (uint) {
        return users[user].maxUnilevel - users[user].unilevelReached;
    }

    function increaseGain(address user, uint amount) external onlyUserContract {
        users[user].unilevelReached += amount;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC1155Holder) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyUserContract() {
        require(
            msg.sender == userContract,
            'Only user contract can call this function'
        );
        _;
    }
}
