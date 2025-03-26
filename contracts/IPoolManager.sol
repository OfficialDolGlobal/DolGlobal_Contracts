// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IPoolManager {
    function isUserActive(address user) external view returns (bool);
    function getAmountValue(uint128 amount) external view returns (uint value);
    function increaseLiquidityPool2(uint amount) external;
    function increaseLiquidityPool1(uint amount) external;
    function swap(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint amount,
        address recipient
    ) external returns (uint amountOut);
    function increaseLiquidityPoolUniswap(
        uint256 amountUsdt,
        uint amountDol
    ) external;
    function distributeUnilevelUsdt(address user, uint amount) external;
    function distributeUnilevelToken(address user, uint amount) external;
    function increaseLiquidityDevPool(
        uint amount,
        address tokenContract
    ) external;
    function increaseLiquidityReservePool(uint amount) external;

    function distributeUnilevelIguality(address user, uint amount) external;
    function increaseLiquidityMarketingPool(
        uint amount,
        address tokenContract
    ) external;

    function isFaceIdVerified(address _user) external view returns (bool);
    function swapOut(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        address recipient,
        uint amountOut,
        uint amountInMaximum
    ) external returns (uint amountIn);
}
