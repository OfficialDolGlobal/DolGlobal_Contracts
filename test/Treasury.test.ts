import {
    loadFixture,
    time,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { expect } from "chai";
  import { ethers } from "hardhat";
import { token } from "../typechain-types/@openzeppelin/contracts";
  
  enum PoolType {
    TREASURY,
    RECHARGE,
    DEVS,
    MARKETING
  }

  describe("Treasury", function () {
    this.timeout(600000); 
    async function deployFixture() {
      const [owner, otherAccount] = await ethers.getSigners();
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



      const DolGlobalCollection = await ethers.getContractFactory("DolGlobalCollection");
      const collection = await DolGlobalCollection.deploy(usdtAddress,poolManagerAddress,userRefferalAddress,dolGlobalAddress);
      const collectionAddress = await collection.getAddress();

      await userRefferal.setDolGlobalCollection(collectionAddress)
      await userRefferal.setPoolManager(poolManagerAddress) 
      await userRefferal.setBotWallet(owner.address)

      await g100.setPoolManager(poolManagerAddress)
      await g10.setPoolManager(poolManagerAddress)
      await g10.setUserContract(userRefferalAddress)

      const RechargePool = await ethers.getContractFactory("RechargePool");
      const rechargePool = await RechargePool.deploy(
        dolGlobalAddress,
        poolManagerAddress,
      );
      const rechargePoolAddress = await rechargePool.getAddress();


      const DevPool = await ethers.getContractFactory("DevPool");
      const devPool = await DevPool.deploy();
      const devPoolAddress = await devPool.getAddress();
      await devPool.addToken(usdtAddress,"USDT")
      await devPool.addToken(dolGlobalAddress,"DOL")

      const MarketingPool = await ethers.getContractFactory("MarketingPool");
      const marketing = await MarketingPool.deploy();
      const marketingAddress = await marketing.getAddress();
      await marketing.addToken(usdtAddress,"USDT")

      const TreasuryPool = await ethers.getContractFactory("TreasuryPoolMocked");
      const treasuryPool = await TreasuryPool.deploy(
        dolGlobalAddress,
        usdtAddress,
        poolManagerAddress
      );
      const treasuryPoolAddress = await treasuryPool.getAddress();

      await poolManager.setPools(PoolType.TREASURY,treasuryPoolAddress)
      await poolManager.setPools(PoolType.RECHARGE,rechargePoolAddress)
      await poolManager.setPools(PoolType.DEVS,devPoolAddress)
      await poolManager.setPools(PoolType.MARKETING,marketingAddress)
      
      
      await dolGlobal.approve(poolManagerAddress, ethers.parseUnits("49500000", "ether"));
      await poolManager.increaseLiquidityPool1(ethers.parseUnits("49500000", "ether"));
      await usdt.mint(ethers.parseUnits("1000000",6))
      await usdt.connect(otherAccount).mint(ethers.parseUnits("3000000",6))
      const balance = await dolGlobal.balanceOf(owner.address)
      await userRefferal.createUser(owner.address,g10Address)
      await userRefferal.setFaceId(owner.address)
      await userRefferal.connect(otherAccount).createUser(otherAccount.address,owner.address)
      await userRefferal.setFaceId(otherAccount.address)

      return {
        owner,
        otherAccount,
        treasuryPool,
        dolGlobal,
        treasuryPoolAddress,
        usdt,
        balance,
        poolManager,poolManagerAddress,
        rechargePool,userRefferal,userRefferalAddress,collection,collectionAddress,rechargePoolAddress,g10,g10Address
      };
    }
  

    it("Should create donation usdt", async function () {
      const {
        owner,
        otherAccount,
        treasuryPool,
        dolGlobal,
        treasuryPoolAddress,
        usdt,
        balance,
        poolManager,
        rechargePool,userRefferalAddress
      } = await loadFixture(deployFixture);
      expect(await dolGlobal.balanceOf(treasuryPoolAddress)).to.be.equal(ethers.parseUnits("49500000", "ether"))
      expect(await treasuryPool.distributionBalance()).to.be.equal(ethers.parseUnits("49500000", "ether"))
      console.log(ethers.formatUnits(await treasuryPool.usdtAccumulated(),6));

      await usdt.approve(treasuryPoolAddress,ethers.parseUnits("1000000",6))
      await usdt.connect(otherAccount).approve(treasuryPoolAddress,ethers.parseUnits("3000000",6))

      expect(await rechargePool.getTotalTokens()).to.be.equal(0)
      
      await treasuryPool.contribute(ethers.parseUnits("1000000",6))   

      for (let index = 1; index <= 50; index++) {
        await time.increase(24*60*60)
        await treasuryPool.connect(otherAccount).contribute(ethers.parseUnits(String(2000*index),6))
      }   
      
      for (let index = 1; index <= 44; index++) {
        console.log(index);
        await treasuryPool.connect(otherAccount).claimContribution(index)
        
      }
      console.log(ethers.formatUnits(await treasuryPool.usdtAccumulated(),6));
      await treasuryPool.claimContribution(1)
      console.log(ethers.formatUnits(await treasuryPool.usdtAccumulated(),6));


  


      
    }); 




  });