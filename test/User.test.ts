import {
    loadFixture,
    time,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { expect } from "chai";
  import { ethers } from "hardhat";
import { token } from "../typechain-types/@openzeppelin/contracts";
import dotenv from "dotenv";

dotenv.config();
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


      const DevPool = await ethers.getContractFactory("DevPool");
      const devPool = await DevPool.deploy();
      const devPoolAddress = await devPool.getAddress();
      await devPool.addToken(usdtAddress,"USDT")

      const MarketingPool = await ethers.getContractFactory("MarketingPool");
      const marketing = await MarketingPool.deploy();
      const marketingAddress = await marketing.getAddress();
      await marketing.addToken(usdtAddress,"USDT")

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
      await g10.setUserContract(userRefferalAddress)

      await g100.setPoolManager(poolManagerAddress)
      await g10.setPoolManager(poolManagerAddress)

      await poolManager.setPools(2,devPoolAddress)
      await poolManager.setPools(3,marketingAddress)

      await userRefferal.setPoolManager(poolManagerAddress)
      await userRefferal.setBotWallet(owner.address)
      await top1.setPoolManager(poolManagerAddress)
      await top2.setPoolManager(poolManagerAddress)
      await top3.setPoolManager(poolManagerAddress)
      await top4.setPoolManager(poolManagerAddress)
      await top5.setPoolManager(poolManagerAddress)

      return {
        owner,
        otherAccount,
        usdt,another,
        dolGlobal,devPoolAddress,collectionAddress,collection,
userRefferal,userRefferalAddress,top1Address,top2Address,top3Address,top4Address,top5Address,top1,top2,top3,top4,top5,g100,g100Address,g10,g10Address
      };
    }
  
    // it("Should distribute to top5", async function () {
    //   const {
    //     owner,
    //     otherAccount,
    //     usdt,
    //     dolGlobal,devPoolAddress,
    //     userRefferal,userRefferalAddress,top1Address,top2Address,top3Address,top4Address,top5Address,collection,top1,top2,top3,top4,top5,g100,g100Address,g10,g10Address
    //   } = await loadFixture(deployFixture);

    //   await usdt.mint(ethers.parseUnits("100000",6))
    //   await usdt.approve(userRefferalAddress,ethers.parseUnits("100000",6))
    //   await usdt.connect(otherAccount).mint(ethers.parseUnits("1000",6))
    //   await usdt.connect(otherAccount).approve(top1Address,ethers.parseUnits("1000",6))
    //   await userRefferal.createUser(owner.address,g10Address)

    //   await userRefferal.distributeUnilevelIguality(owner.address,ethers.parseUnits("1000",6))
    //   expect(await usdt.balanceOf(g100Address)).to.be.equal(ethers.parseUnits("25",6))
    //   expect(await usdt.balanceOf(g10Address)).to.be.equal(ethers.parseUnits("25",6))
    //   expect(await top1.availableToBuy()).to.be.equal(false)
    //   await expect(top1.buyTop5()).to.be.revertedWith("Unavailable now")
    //   await top1.setConfig(ethers.parseUnits("40",6),ethers.parseUnits("10",6))
    //   await time.increase(24*60*60)
    //   await userRefferal.distributeUnilevelIguality(owner.address,ethers.parseUnits("1000",6))
    //   expect(await usdt.balanceOf(g100Address)).to.be.equal(ethers.parseUnits("50",6))
    //   expect(await usdt.balanceOf(g10Address)).to.be.equal(ethers.parseUnits("50",6))
    //   expect(await top1.availableToBuy()).to.be.equal(true)

    //   await top1.connect(otherAccount).buyTop5()
      
    //   await userRefferal.distributeUnilevelIguality(owner.address,ethers.parseUnits("1000",6))

    //   await expect(top1.buyTop5()).to.be.revertedWith("Unavailable now")

    //   expect(await usdt.balanceOf(top1Address)).to.be.equal(0)
    //   expect(await usdt.balanceOf(otherAccount.address)).to.be.equal(ethers.parseUnits("1015",6))
    //   await userRefferal.distributeUnilevelIguality(owner.address,ethers.parseUnits("1000",6))
    //   expect(await usdt.balanceOf(otherAccount.address)).to.be.equal(ethers.parseUnits("1030",6))
    //   await userRefferal.distributeUnilevelIguality(owner.address,ethers.parseUnits("1000",6))
    //   expect(await usdt.balanceOf(otherAccount.address)).to.be.equal(ethers.parseUnits("1030",6))
    //   await top1.setConfig(ethers.parseUnits("40",6),ethers.parseUnits("10",6))
    //   await expect(top1.buyTop5()).to.be.revertedWith("Purchase allowed after 24h or if you are a top 5 user.")
    //   await top1.connect(otherAccount).buyTop5()



    // }); 

    // it("Should distribute to g100", async function () {
    //   const {
    //     owner,
    //     otherAccount,
    //     usdt,
    //     dolGlobal,devPoolAddress,another,
    //     userRefferal,userRefferalAddress,top1Address,top2Address,top3Address,top4Address,top5Address,collection,top1,top2,top3,top4,top5,g100,g100Address,g10,g10Address
    //   } = await loadFixture(deployFixture);

    //   await usdt.mint(ethers.parseUnits("2000000",6))
    //   await usdt.approve(userRefferalAddress,ethers.parseUnits("2000000",6))
    //   await usdt.connect(otherAccount).mint(ethers.parseUnits("1000",6))
    //   await usdt.connect(otherAccount).approve(g100Address,ethers.parseUnits("1000",6))
    //   await usdt.approve(g100Address,ethers.parseUnits("1000",6))

    //   await userRefferal.createUser(owner.address,g10Address)

      
    //   await expect(g100.connect(otherAccount).buyPosition()).to.be.revertedWith("Unavailable")

    //   await g100.setConfig(ethers.parseUnits("10",6),ethers.parseUnits("30",6))
    //   await g100.connect(otherAccount).buyPosition()
    //   expect(await usdt.balanceOf(otherAccount.address)).to.be.equal(ethers.parseUnits("990",6))
    //   await expect(g100.connect(otherAccount).buyPosition()).to.be.revertedWith("You can only buy one position")
    //   expect(await usdt.balanceOf(otherAccount.address)).to.be.equal(ethers.parseUnits("990",6))

    //   expect(await g100.viewAddressByIndex(1)).to.be.equal(otherAccount.address)

    //   await userRefferal.distributeUnilevelIguality(owner.address,ethers.parseUnits("1000",6))
    //   expect(await g100.balanceFree()).to.be.equal(ethers.parseUnits("25",6))
    //   await g100.connect(otherAccount).claim()
    //   expect(await usdt.balanceOf(userRefferalAddress)).to.be.equal(0)
    //   expect(await g100.balanceFree()).to.be.equal(0)
    //   expect(await usdt.balanceOf(otherAccount.address)).to.be.equal(ethers.parseUnits("990.25",6))
    //   await userRefferal.distributeUnilevelIguality(owner.address,ethers.parseUnits("200000",6))
    //   expect(await g100.balanceFree()).to.be.equal(ethers.parseUnits("5000",6))
    //   await g100.claim()
    //   await g100.setConfig(ethers.parseUnits("1000",6),ethers.parseUnits("3000",6))
    //   await g100.buyPosition()
    //   expect(await g100.viewAddressByIndex(1)).to.be.equal(owner.address)

    // }); 

    // it("Should not buy G100 filled", async function () {
    //   const {
    //     owner,
    //     otherAccount,
    //     usdt,
    //     dolGlobal,devPoolAddress,
    //     userRefferal,userRefferalAddress,top1Address,top2Address,top3Address,top4Address,top5Address,collection,top1,top2,top3,top4,top5,g100,g100Address,g10,g10Address
    //   } = await loadFixture(deployFixture);

    //   await usdt.mint(ethers.parseUnits("2000000",6))
    //   await usdt.connect(otherAccount).mint(ethers.parseUnits("2000000",6))

    //   await usdt.approve(g100Address,ethers.parseUnits("2000000",6))
    //   await usdt.connect(otherAccount).approve(g100Address,ethers.parseUnits("2000000",6))

    //   await g100.setConfig(ethers.parseUnits("10",6),ethers.parseUnits("20",6))
    //   for (let index = 0; index < 100; index++) {
    //     const wallet = ethers.Wallet.createRandom().connect(ethers.provider);
    //     await owner.sendTransaction({to:wallet.address,value:ethers.parseEther("1")})
    //     await usdt.connect(wallet).mint(100*10**6)
    //     await usdt.connect(wallet).approve(g100Address,100*10**6)
    //     await g100.connect(wallet).buyPosition()
    //   }
    //   await expect(         g100.buyPosition()
    // ).to.be.revertedWith("No positions to buy")
    // await g100.removePosition(50)


    // expect(await g100.viewAddressByIndex(50)).to.be.equal(ethers.ZeroAddress)

    // await g100.connect(otherAccount).buyPosition()
    
    // expect(await g100.viewAddressByIndex(50)).to.be.equal(otherAccount.address)

    // }); 
    // it("Should start with initial position", async function () {
    //   const {
    //     owner,
    //     otherAccount,
    //     usdt,
    //     dolGlobal,devPoolAddress,
    //     userRefferal,userRefferalAddress,top1Address,top2Address,top3Address,top4Address,top5Address,collection,top1,top2,top3,top4,top5,g100,g100Address,g10,g10Address
    //   } = await loadFixture(deployFixture);

    //   expect((await userRefferal.getUser(top1Address)).totalLevels).to.be.equal(0)    
    //   expect(((await userRefferal.getUser(top1Address)).referrals[0])).to.be.equal(top2Address)      
  
    //   expect((await userRefferal.getUser(top2Address)).totalLevels).to.be.equal(1)   
    //   expect((await userRefferal.getUser(top2Address)).referrals[0]).to.be.equal(top3Address)      

    //   expect((await userRefferal.getUser(top3Address)).totalLevels).to.be.equal(2)     
    //   expect((await userRefferal.getUser(top3Address)).referrals[0]).to.be.equal(top4Address)      
 
    //   expect((await userRefferal.getUser(top4Address)).totalLevels).to.be.equal(3)   
    //   expect((await userRefferal.getUser(top4Address)).referrals[0]).to.be.equal(top5Address)      
   
    //   expect((await userRefferal.getUser(top5Address)).totalLevels).to.be.equal(4)   
    //   expect((await userRefferal.getUser(top5Address)).referrals[0]).to.be.equal(g100Address)      
 
    //   expect((await userRefferal.getUser(g100Address)).totalLevels).to.be.equal(5)  
    //   expect((await userRefferal.getUser(g100Address)).referrals[0]).to.be.equal(g10Address)      
    
    //   expect((await userRefferal.getUser(g10Address)).totalLevels).to.be.equal(6)   
    //   expect((await userRefferal.getUser(g10Address)).referrals.length).to.be.equal(0)      
   
  

    // }); 

    it("Should distribute percentage of multinivel", async function () {
      const {
        owner,
        otherAccount,
        usdt,
        dolGlobal,devPoolAddress,collectionAddress,
        userRefferal,userRefferalAddress,top1Address,top2Address,top3Address,top4Address,top5Address,collection,top1,top2,top3,top4,top5,g100,g100Address,g10,g10Address
      } = await loadFixture(deployFixture);

      const mnemonicPhrase = process.env.mnemonic!;


          const wallets = [owner];
          
      
          const mnemonic = ethers.Mnemonic.fromPhrase(mnemonicPhrase);
          const hdWallet = ethers.HDNodeWallet.fromSeed(mnemonic.computeSeed());
        await userRefferal.createUser(owner.address,g10Address)
        await collection.marketingBonus(owner.address,ethers.parseUnits("10000",6))

          for (let i = 0; i < 40; i++) {
              const derivedNode = hdWallet.derivePath(`m/44'/60'/0'/0/${i}`);
              const wallet :any = new ethers.Wallet(derivedNode.privateKey, ethers.provider);
              await owner.sendTransaction({to:wallet.address,value:ethers.parseEther("1")})
              wallets.push(wallet);
              await userRefferal.connect(wallet).createUser(wallet.address,wallets[i].address)
              await collection.marketingBonus(wallet.address,ethers.parseUnits("10000",6))
          }
          const donateWallet = wallets[wallets.length-1]
          await usdt.connect(donateWallet).mint(ethers.parseUnits("10000",6))
          await usdt.connect(donateWallet).approve(userRefferalAddress,ethers.parseUnits("10000",6))

          



    }); 
 
    // it("Should exceed max of multinivel bought", async function () {
    //   const {
    //     owner,
    //     otherAccount,
    //     usdt,
    //     dolGlobal,devPoolAddress,collectionAddress,
    //     userRefferal,userRefferalAddress,top1Address,top2Address,top3Address,top4Address,top5Address,collection,top1,top2,top3,top4,top5,g100,g100Address,g10,g10Address
    //   } = await loadFixture(deployFixture);

    //   await userRefferal.createUser(owner.address,g10Address)
    //   await userRefferal.setFaceId(owner.address)

    //   const wallets:any = [owner]
    //   await usdt.mint(ethers.parseUnits("50",6))
    //   await usdt.approve(collectionAddress,ethers.parseUnits("50",6))
    //   await collection.mintNftGlobal(ethers.parseUnits("50",6))
    //   for (let index = 1; index <= 40; index++) {
    //     const wallet:any = ethers.Wallet.createRandom().connect(ethers.provider);
    //     wallets.push(wallet)
    //     await owner.sendTransaction({to:wallet.address,value:ethers.parseEther("1")})
    //     await usdt.connect(wallet).mint(ethers.parseUnits("1000",6))
    //     await usdt.connect(wallet).approve(userRefferalAddress,ethers.parseUnits("1000",6))

    //     await userRefferal.createUser(wallet.address,wallets[index-1])
    //     await userRefferal.setFaceId(wallet.address)
    //   }
      
    //   await userRefferal.connect(wallets[2]).distributeUnilevelUsdt(wallets[2].address,ethers.parseUnits("380",6));
    //   expect(await usdt.balanceOf(owner.address)).to.be.equal(ethers.parseUnits("50",6))
    //   await userRefferal.connect(wallets[3]).distributeUnilevelUsdt(wallets[3].address,ethers.parseUnits("760",6));
    //   expect(await usdt.balanceOf(owner.address)).to.be.equal(ethers.parseUnits("90",6))
    //   await userRefferal.connect(wallets[4]).distributeUnilevelUsdt(wallets[4].address,ethers.parseUnits("380",6));
    //   expect(await usdt.balanceOf(owner.address)).to.be.equal(ethers.parseUnits("100",6))
    //   await userRefferal.connect(wallets[4]).distributeUnilevelUsdt(wallets[4].address,ethers.parseUnits("380",6));
    //   expect(await usdt.balanceOf(owner.address)).to.be.equal(ethers.parseUnits("100",6))

 

    // }); 
 
    // it("Should exceed max of daily multinivel", async function () {
    //   const {
    //     owner,
    //     otherAccount,
    //     usdt,
    //     dolGlobal,devPoolAddress,collectionAddress,
    //     userRefferal,userRefferalAddress,top1Address,top2Address,top3Address,top4Address,top5Address,collection,top1,top2,top3,top4,top5,g100,g100Address,g10,g10Address
    //   } = await loadFixture(deployFixture);

    //   await userRefferal.createUser(owner.address,g10Address)
    //   await userRefferal.setFaceId(owner.address)
    //   await userRefferal.createUser(otherAccount.address,owner.address)
    //   await userRefferal.setFaceId(otherAccount.address)

    //   await usdt.mint(ethers.parseUnits("10000",6))
    //   await usdt.approve(collectionAddress,ethers.parseUnits("10000",6))
    //   await collection.mintNftGlobal(ethers.parseUnits("10000",6))

    //   await usdt.connect(otherAccount).mint(ethers.parseUnits("39000",6))
    //   await usdt.connect(otherAccount).approve(userRefferalAddress,ethers.parseUnits("39000",6))
    //   await userRefferal.connect(otherAccount).distributeUnilevelUsdt(otherAccount.address,ethers.parseUnits("39000",6))

    //   expect(await usdt.balanceOf(owner.address)).to.be.equal(ethers.parseUnits("10000",6))

    //   await usdt.connect(otherAccount).mint(ethers.parseUnits("39000",6))
    //   await usdt.connect(otherAccount).approve(userRefferalAddress,ethers.parseUnits("39000",6))
    //   await userRefferal.connect(otherAccount).distributeUnilevelUsdt(otherAccount.address,ethers.parseUnits("39000",6))
 
    //   expect(await usdt.balanceOf(owner.address)).to.be.equal(ethers.parseUnits("10000",6))

    //   await time.increase(24*60*60)

    //   await usdt.connect(otherAccount).mint(ethers.parseUnits("39000",6))
    //   await usdt.connect(otherAccount).approve(userRefferalAddress,ethers.parseUnits("39000",6))
    //   await userRefferal.connect(otherAccount).distributeUnilevelUsdt(otherAccount.address,ethers.parseUnits("39000",6))

    //   expect(await usdt.balanceOf(owner.address)).to.be.equal(ethers.parseUnits("20000",6))

    // }); 


  });