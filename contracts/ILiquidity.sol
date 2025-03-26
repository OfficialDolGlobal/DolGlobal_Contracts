// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface ILiquidity {
    function increaseLiquidity(
        address token0,
        address token1,
        uint256 amount0ToAdd,
        uint256 amount1ToAdd
    ) external;
}
