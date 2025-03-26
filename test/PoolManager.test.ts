import {
    loadFixture,
    time,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { expect } from "chai";
  import { ethers } from "hardhat";
import { token } from "../typechain-types/@openzeppelin/contracts";

  describe("PoolManager", function () {
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
  
      const PoolManager = await ethers.getContractFactory("PoolManager");
      const poolManager = await PoolManager.deploy(dolGlobalAddress,usdtAddress,userRefferalAddress);
      const poolManagerAddress = await poolManager.getAddress();


      return {
        owner,
        otherAccount,
        usdt,another,
        dolGlobal,
        usdtAddress,
        dolGlobalAddress,
        poolManager,
        poolManagerAddress
    };
    }
  
 
    it("Should distribute values", async function () {
      const {
        owner,
        otherAccount,
        usdt,another,
        dolGlobal,
        usdtAddress,
        dolGlobalAddress,
        poolManager,
        poolManagerAddress
    } = await loadFixture(deployFixture);
      await usdt.mint(ethers.parseUnits("1000",6))
      await usdt.approve(poolManagerAddress,ethers.parseUnits("1000",6))
      await poolManager.increaseLiquidityReservePool(ethers.parseUnits("100",6))
      console.log(await usdt.balanceOf("0x1dbd97b0d2bc78d9B4dE3188180FAA44D9217f1D"));
      console.log(await usdt.balanceOf("0x6e595E0d3Fa79a4a056e5875f8752225b57A0c9a"));
      await poolManager.setReservePercentages(30,70)
      await poolManager.increaseLiquidityReservePool(ethers.parseUnits("100",6))
      console.log(await usdt.balanceOf("0x1dbd97b0d2bc78d9B4dE3188180FAA44D9217f1D"));
      console.log(await usdt.balanceOf("0x6e595E0d3Fa79a4a056e5875f8752225b57A0c9a"));
      await poolManager.setReserveAddresses(owner.address,otherAccount.address)
      await poolManager.increaseLiquidityReservePool(ethers.parseUnits("100",6))
      console.log(await usdt.balanceOf(owner.address));
      console.log(await usdt.balanceOf(otherAccount.address));
      await poolManager.renounceSecondary()
      await poolManager.setReserveAddresses(owner.address,otherAccount.address)

    }); 
 

  });