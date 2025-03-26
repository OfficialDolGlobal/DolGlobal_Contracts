// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface ITop5 {
    function increaseValue(uint amount) external;
    function viewRemainingBalance() external view returns (uint remaining);
}
