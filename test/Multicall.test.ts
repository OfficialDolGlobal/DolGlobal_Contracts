import {
    loadFixture,
    time,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { expect } from "chai";
  import { ethers } from "hardhat";
import { token } from "../typechain-types/@openzeppelin/contracts";

  describe("User", function () {
    this.timeout(60000000); 
    async function deployFixture() {
      const [owner, otherAccount,another] = await ethers.getSigners();
      const DolGlobal = await ethers.getContractFactory("DolGlobal");
      const dolGlobal = await DolGlobal.deploy();
      const dolGlobalAddress = await dolGlobal.getAddress();

      
  

      const USDT = await ethers.getContractFactory("USDT");
      const usdt = await USDT.deploy();
      const usdtAddress = await usdt.getAddress();



      const Top5 = await ethers.getContractFactory("Top5");
      const top1 = await Top5.deploy(usdtAddress);
      const top1Address = await top1.getAddress();
      const top2 = await Top5.deploy(usdtAddress);
      const top2Address = await top2.getAddress();
      const top3 = await Top5.deploy(usdtAddress);
      const top3Address = await top3.getAddress();
      const top4 = await Top5.deploy(usdtAddress);
      const top4Address = await top4.getAddress();
      const top5 = await Top5.deploy(usdtAddress);
      const top5Address = await top5.getAddress();

      const G100 = await ethers.getContractFactory("G100");
      const g100 = await G100.deploy(usdtAddress);
      const g100Address = await g100.getAddress();
      const G10 = await ethers.getContractFactory("G15");
      const g10 = await G10.deploy(usdtAddress);
      const g10Address = await g10.getAddress();



      const UserRefferal = await ethers.getContractFactory("UserDolGlobal");
      const userRefferal = await UserRefferal.deploy(usdtAddress,dolGlobalAddress,top1Address,top2Address,top3Address,top4Address,top5Address,g100Address,g10Address);
      const userRefferalAddress = await userRefferal.getAddress();
      const MultiCallUser = await ethers.getContractFactory("MultiCallUser");
      const multicall = await MultiCallUser.deploy(userRefferalAddress);
      const multicallAddress = await multicall.getAddress();
      const PoolManager = await ethers.getContractFactory("PoolManager");
      const poolManager = await PoolManager.deploy(dolGlobalAddress,usdtAddress,userRefferalAddress);
      const poolManagerAddress = await poolManager.getAddress();

        await userRefferal.setBotWallet(multicallAddress)

      await userRefferal.setPoolManager(poolManagerAddress)
 
      await top1.setPoolManager(poolManagerAddress)
      await top2.setPoolManager(poolManagerAddress)
      await top3.setPoolManager(poolManagerAddress)
      await top4.setPoolManager(poolManagerAddress)
      await top5.setPoolManager(poolManagerAddress)



      return {
        owner,
        otherAccount,
        usdt,another,
        dolGlobal,multicall,
userRefferal,userRefferalAddress,top1Address,top2Address,top3Address,top4Address,top5Address,top1,top2,top3,top4,top5,g100,g100Address,g10,g10Address
      };
    }
  
    it("Should distribute to top5", async function () {
      const {
        owner,
        otherAccount,
        usdt,multicall,
        dolGlobal,
        userRefferal,userRefferalAddress,top1Address,top2Address,top3Address,top4Address,top5Address,top1,top2,top3,top4,top5,g100,g100Address,g10,g10Address
      } = await loadFixture(deployFixture);
      await multicall.createBatchTransactions([owner.address],[g10Address])
      console.log(await userRefferal.getUser(owner.address));
      
      await multicall.createBatchTransactions([owner.address,otherAccount.address],[g10Address,owner.address])
      console.log(await multicall.teste());
      console.log(await userRefferal.getUser(otherAccount.address));

    }); 


  });