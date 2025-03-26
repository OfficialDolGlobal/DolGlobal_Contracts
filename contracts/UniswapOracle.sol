// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol';

contract UniswapOracle {
    address public poolDolUsdt;
    address public owner;
    address public dolToken;
    address public usdt;
    uint32 public secondsAgo = 30;
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, 'Not the contract owner');
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), owner);
    }

    function setSecondsAgo(uint32 newSeconds) external onlyOwner {
        secondsAgo = newSeconds;
    }

    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), 'New owner cannot be the zero address');
        address oldOwner = owner;
        owner = newOwner;
        emit OwnerChanged(oldOwner, newOwner);
    }

    function setDol(address _dolToken) external onlyOwner {
        require(_dolToken != address(0), 'DOL cannot be the zero address');
        require(dolToken == address(0), 'Token is already set');
        dolToken = _dolToken;
    }

    function setUsdt(address _usdt) external onlyOwner {
        require(_usdt != address(0), 'USDT cannot be the zero address');
        require(usdt == address(0), 'Usdt is already set');

        usdt = _usdt;
    }

    function setPoolDolUsdt(uint24 _fee) external onlyOwner {
        require(poolDolUsdt == address(0), 'Pool is already set');
        require(dolToken != address(0), 'DOL address not set');
        require(usdt != address(0), 'USDT address not set');

        address _pool = IUniswapV3Factory(
            0x1F98431c8aD98523631AE4a59f267346ea31F984
        ).getPool(dolToken, usdt, _fee);
        require(_pool != address(0), 'Pool does not exist');

        poolDolUsdt = _pool;
    }

    function returnPrice(uint128 amountIn) external view returns (uint) {
        require(poolDolUsdt != address(0), 'DOL/USDT pool not set');

        (int24 tickDolUsdt, ) = OracleLibrary.consult(poolDolUsdt, secondsAgo);
        uint amountOut = OracleLibrary.getQuoteAtTick(
            tickDolUsdt,
            amountIn,
            dolToken,
            usdt
        );

        return amountOut;
    }
}
