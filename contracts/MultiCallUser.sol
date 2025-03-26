// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import './IUserDolGlobal.sol';
import '@openzeppelin/contracts/access/Ownable2Step.sol';

contract MultiCallUser is Ownable2Step {
    IUserDolGlobal userDolContract;

    constructor(address userContract) Ownable(msg.sender) {
        userDolContract = IUserDolGlobal(userContract);
    }

    function setUserContract(address userContract) external onlyOwner {
        userDolContract = IUserDolGlobal(userContract);
    }

    function createBatchTransactions(
        address[] calldata users
    ) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            userDolContract.setFaceId(users[i]);
        }
    }
}
