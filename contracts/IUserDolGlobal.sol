// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
struct UserStruct {
    bool registered;
    bool faceId;
    uint8 totalLevels;
    address[40] levels;
    address[] referrals;
}
interface IUserDolGlobal {
    function distributeUnilevelUsdt(address user, uint amount) external;
    function distributeUnilevelIguality(address user, uint amount) external;
    function getUser(
        address _address
    ) external view returns (UserStruct memory);
    function createUser(address user, address _sponsor) external;
    function setFaceId(address user) external;
}
