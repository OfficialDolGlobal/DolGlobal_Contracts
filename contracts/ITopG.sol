// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface ITopG {
    function increaseBalance(uint amount) external;
    function activeRoof() external;
    function isRoofActivated() external view returns (bool);
}
