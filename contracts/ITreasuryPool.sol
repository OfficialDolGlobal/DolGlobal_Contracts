// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface ITreasuryPool {
    function addDistributionFunds(uint256 amount) external;
    function isUserActive(address user) external view returns (bool);
}
