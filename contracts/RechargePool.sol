// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable2Step.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './IPoolManager.sol';

contract RechargePool is Ownable2Step {
    using SafeERC20 for IERC20;
    IERC20 private immutable token;
    IPoolManager private immutable poolManager;

    constructor(
        address _dolContract,
        address poolManagerContract
    ) Ownable(msg.sender) {
        require(_dolContract != address(0), 'Invalid dol contract');
        require(
            poolManagerContract != address(0),
            'Invalid pool manager contract'
        );

        token = IERC20(_dolContract);
        poolManager = IPoolManager(poolManagerContract);
    }

    function fillTreasuryPool(uint amount) external onlyOwner {
        token.approve(address(poolManager), amount);
        poolManager.increaseLiquidityPool1(amount);
    }

    function getTotalTokens() external view returns (uint) {
        return token.balanceOf(address(this));
    }
}
