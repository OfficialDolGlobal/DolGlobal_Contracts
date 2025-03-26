// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface IDolGlobalCollection is IERC1155 {
    function increaseGain(address user, uint amount) external;
    function availableUnilevel(address user) external view returns (uint);
    function mintNftGlobal(uint amount) external;
}
