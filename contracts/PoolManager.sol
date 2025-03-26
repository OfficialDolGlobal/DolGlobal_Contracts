// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable2Step.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import './INonfungiblePositionManager.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './IUNCX_LiquidityLocker_UniV3.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import './ITreasuryPool.sol';
import './IUserDolGlobal.sol';
import './IManager.sol';
import './IUniswapOracle.sol';
enum PoolType {
    TREASURY,
    RECHARGE,
    DEVS,
    MARKETING
}
contract PoolManager is Ownable2Step {
    using SafeERC20 for IERC20;
    IERC20 immutable dolToken;
    IERC20 immutable usdt;
    INonfungiblePositionManager public immutable nonfungiblePositionManager;
    IUNCX_LiquidityLocker_UniV3 public immutable unicryptLocker;
    ITreasuryPool public treasuryPool;
    IUserDolGlobal public immutable userDolGlobal;
    IManager public devPool;
    IManager public marketingPool;
    address public rechargePool;
    address public secondaryOwner;
    address public reservePool = 0x1dbd97b0d2bc78d9B4dE3188180FAA44D9217f1D;
    address public reservePool2 = 0x6e595E0d3Fa79a4a056e5875f8752225b57A0c9a;
    uint public percentage = 80;
    uint public percentage2 = 20;

    ISwapRouter public immutable swapRouter;
    IUniswapOracle public oracle;

    uint public liquidityPoolUniswapId;
    uint public lockPoolId;

    event SetPoolLock(uint lockId);
    event SetPoolUniswap(uint poolId);

    constructor(
        address _dolToken,
        address _usdt,
        address _userDolGlobal
    ) Ownable(msg.sender) {
        require(_usdt != address(0), 'Invalid usdt contract');
        require(_userDolGlobal != address(0), 'Invalid user contract');
        require(_dolToken != address(0), 'Invalid dol contract');
        nonfungiblePositionManager = INonfungiblePositionManager(
            0xC36442b4a4522E871399CD717aBDD847Ab11FE88
        );
        unicryptLocker = IUNCX_LiquidityLocker_UniV3(
            0x40f6301edb774e8B22ADC874f6cb17242BaEB8c4
        );
        swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        dolToken = IERC20(_dolToken);
        userDolGlobal = IUserDolGlobal(_userDolGlobal);

        usdt = IERC20(_usdt);
        secondaryOwner = 0x478A4958BE2506f30c14773d96c6c8Df4d9a2E41;
    }

    function renounceSecondary() external onlySecondary {
        secondaryOwner = address(0);
    }

    modifier onlySecondary() {
        require(msg.sender == secondaryOwner, 'Not authorized');
        _;
    }
    function setReservePercentages(
        uint newPercentage1,
        uint newPercentage2
    ) external onlySecondary {
        require(
            newPercentage1 + newPercentage2 == 100,
            'Percentages must sum 100'
        );
        percentage = newPercentage1;
        percentage2 = newPercentage2;
    }
    function setReserveAddresses(
        address newReserve1,
        address newReserve2
    ) external onlySecondary {
        require(newReserve1 != address(0), 'Zero Address');
        require(newReserve2 != address(0), 'Zero Address');

        reservePool = newReserve1;
        reservePool2 = newReserve2;
    }
    function increaseLiquidityReservePool(uint amount) external {
        usdt.safeTransferFrom(msg.sender, address(this), amount);
        uint amount1 = (amount * percentage) / 100;
        uint amount2 = (amount * percentage2) / 100;

        usdt.safeTransfer(reservePool, amount1);
        usdt.safeTransfer(reservePool2, amount2);
    }
    function setUniswapOracle(address _oracle) external onlyOwner {
        oracle = IUniswapOracle(_oracle);
    }

    function increaseLiquidityPool1(uint amount) public {
        dolToken.safeTransferFrom(msg.sender, address(this), amount);
        dolToken.approve(address(treasuryPool), amount);
        treasuryPool.addDistributionFunds(amount);
    }
    function increaseLiquidityPool2(uint amount) external {
        dolToken.safeTransferFrom(msg.sender, address(this), amount);
        dolToken.safeTransfer(rechargePool, amount);
    }

    function increaseLiquidityDevPool(
        uint amount,
        address tokenContract
    ) external {
        IERC20(tokenContract).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        IERC20(tokenContract).approve(address(devPool), amount);
        devPool.incrementBalance(amount, tokenContract);
    }
    function increaseLiquidityMarketingPool(
        uint amount,
        address tokenContract
    ) external {
        IERC20(tokenContract).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        IERC20(tokenContract).approve(address(marketingPool), amount);

        marketingPool.incrementBalance(amount, tokenContract);
    }

    function setLiquidityPoolUniswapId(uint poolId) external onlyOwner {
        liquidityPoolUniswapId = poolId;
        emit SetPoolUniswap(poolId);
    }
    function isFaceIdVerified(address _user) external view returns (bool) {
        UserStruct memory user = userDolGlobal.getUser(_user);
        return user.registered && user.faceId;
    }

    function setLockPoolUniswapId(uint lockId) external onlyOwner {
        lockPoolId = lockId;
        emit SetPoolLock(lockId);
    }

    function isUserActive(address user) external view returns (bool) {
        return treasuryPool.isUserActive(user);
    }

    function collectUniswapFee() external {
        unicryptLocker.collect(
            lockPoolId,
            address(this),
            type(uint128).max,
            type(uint128).max
        );
        dolToken.approve(address(devPool), dolToken.balanceOf(address(this)));
        usdt.approve(address(devPool), usdt.balanceOf(address(this)));

        devPool.incrementBalance(
            dolToken.balanceOf(address(this)),
            address(dolToken)
        );
        devPool.incrementBalance(usdt.balanceOf(address(this)), address(usdt));
    }

    function setPools(PoolType pool, address _contract) external onlyOwner {
        require(_contract != address(0), 'Address cannot be zero');

        if (pool == PoolType.TREASURY) {
            treasuryPool = ITreasuryPool(_contract);
        } else if (pool == PoolType.RECHARGE) {
            rechargePool = _contract;
        } else if (pool == PoolType.DEVS) {
            devPool = IManager(_contract);
        } else if (pool == PoolType.MARKETING) {
            marketingPool = IManager(_contract);
        } else {
            revert('Invalid pool type');
        }
    }

    function getAmountValue(uint128 amount) external view returns (uint value) {
        return oracle.returnPrice(amount);
    }

    function distributeUnilevelUsdt(address user, uint amount) external {
        usdt.safeTransferFrom(msg.sender, address(this), amount);
        usdt.approve(address(userDolGlobal), amount);
        userDolGlobal.distributeUnilevelUsdt(user, amount);
    }
    function distributeUnilevelIguality(address user, uint amount) external {
        usdt.safeTransferFrom(msg.sender, address(this), amount);
        usdt.approve(address(userDolGlobal), amount);
        userDolGlobal.distributeUnilevelIguality(user, amount);
    }

    function swap(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint amount,
        address recipient
    ) public returns (uint amountOut) {
        ISwapRouter.ExactInputSingleParams memory params;
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(tokenIn).approve(address(address(swapRouter)), amount);

        params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: recipient,
            deadline: block.timestamp + 60,
            amountIn: amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        amountOut = swapRouter.exactInputSingle(params);
    }
    function swapOut(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        address recipient,
        uint amountOut,
        uint amountInMaximum
    ) public returns (uint amountIn) {
        ISwapRouter.ExactOutputSingleParams memory params;
        IERC20(tokenIn).safeTransferFrom(
            msg.sender,
            address(this),
            amountInMaximum
        );
        IERC20(tokenIn).approve(address(swapRouter), amountInMaximum);

        params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: recipient,
            deadline: block.timestamp + 60,
            amountOut: amountOut,
            amountInMaximum: amountInMaximum,
            sqrtPriceLimitX96: 0
        });

        amountIn = swapRouter.exactOutputSingle(params);
        if (amountIn < amountInMaximum) {
            IERC20(tokenIn).approve(address(swapRouter), 0);

            IERC20(tokenIn).safeTransfer(
                msg.sender,
                amountInMaximum - amountIn
            );
        }
    }

    function increaseLiquidityPoolUniswap(
        uint256 amountUsdt,
        uint amountDol
    ) external {
        TransferHelper.safeTransferFrom(
            address(usdt),
            msg.sender,
            address(this),
            amountUsdt
        );

        TransferHelper.safeTransferFrom(
            address(dolToken),
            msg.sender,
            address(this),
            amountDol
        );
        uint amountToken0;
        uint amountToken1;

        INonfungiblePositionManager.Position
            memory position = nonfungiblePositionManager.positions(
                liquidityPoolUniswapId
            );

        if (position.token0 == address(usdt)) {
            amountToken0 = amountUsdt;
            amountToken1 = amountDol;
        } else {
            amountToken0 = amountDol;
            amountToken1 = amountUsdt;
        }

        dolToken.approve(address(nonfungiblePositionManager), amountDol);
        usdt.approve(address(nonfungiblePositionManager), amountUsdt);
        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .IncreaseLiquidityParams({
                    tokenId: liquidityPoolUniswapId,
                    amount0Desired: amountToken0,
                    amount1Desired: amountToken1,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });
        (
            uint newLiquidity,
            uint amountToken0Added,
            uint amountToken1Added
        ) = nonfungiblePositionManager.increaseLiquidity(params);
    }
}
