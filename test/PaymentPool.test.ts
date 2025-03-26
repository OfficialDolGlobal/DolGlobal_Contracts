import {
    loadFixture,
    time,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { expect } from "chai";
  import { ethers } from "hardhat";
import { token } from "../typechain-types/@openzeppelin/contracts";

  describe("Payment Pool", function () {
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
      await devPool.addToken(dolGlobalAddress,"DOL")

      await devPool.addRecipient(owner.address,200000n)
      await devPool.addRecipient(otherAccount.address,300000n)
      await devPool.addRecipient(another.address,500000n)

      await devPool.addImmutableWallet(owner.address)


      return {
        owner,
        otherAccount,
        usdt,another,
        dolGlobal,devPoolAddress,devPool,usdtAddress,dolGlobalAddress
    };
    }
  
 
    it("Should distribute values", async function () {
      const {
        owner,
        otherAccount,
        usdt,another,
        dolGlobal,devPoolAddress,devPool,usdtAddress,dolGlobalAddress
    } = await loadFixture(deployFixture);
    expect(await devPool.totalRecipients()).to.be.equal(3)
    expect(await devPool.totalPercentage()).to.be.equal(1000000)
    await expect(devPool.addRecipient(dolGlobalAddress,10000)).to.be.revertedWith("Total percentage exceeds 100%")

    await usdt.mint(ethers.parseUnits("10000",6))
    await dolGlobal.approve(devPoolAddress,ethers.parseUnits("20000"))

    await usdt.approve(devPoolAddress,ethers.parseUnits("10000",6))
    await devPool["incrementBalance(uint256,address)"](ethers.parseUnits("10000",6),usdtAddress)
    await devPool.removeToken(dolGlobalAddress)
    await expect(devPool["incrementBalance(uint256,address)"](ethers.parseUnits("10000"),dolGlobalAddress)).to.be.revertedWith("Token contract not registered")
    await devPool.addToken(dolGlobalAddress,"DOL")
    await devPool["incrementBalance(uint256,address)"](ethers.parseUnits("10000"),dolGlobalAddress)

    expect(await usdt.balanceOf(devPoolAddress)).to.be.equal(ethers.parseUnits("10000",6))
    expect(await dolGlobal.balanceOf(devPoolAddress)).to.be.equal(ethers.parseUnits("10000"))

    await devPool.connect(otherAccount).claim()
    expect(await usdt.balanceOf(otherAccount.address)).to.be.equals(ethers.parseUnits("3000",6))
    expect(await dolGlobal.balanceOf(otherAccount.address)).to.be.equals(ethers.parseUnits("3000"))
    expect(await devPool.recipientsClaim(owner.address,usdtAddress)).to.be.equal(ethers.parseUnits("2000",6))
    expect(await devPool.recipientsClaim(otherAccount.address,usdtAddress)).to.be.equal(0)
    expect(await devPool.recipientsClaim(another.address,usdtAddress)).to.be.equal(ethers.parseUnits("5000",6))
    expect(await devPool.recipientsClaim(owner.address,dolGlobalAddress)).to.be.equal(ethers.parseUnits("2000"))
    expect(await devPool.recipientsClaim(otherAccount.address,dolGlobalAddress)).to.be.equal(0)
    expect(await devPool.recipientsClaim(another.address,dolGlobalAddress)).to.be.equal(ethers.parseUnits("5000"))

    await devPool["incrementBalance(address,uint24)"](another.address,300000)

    await devPool["incrementBalance(address,uint24)"](otherAccount.address,500000)

    await expect(devPool["incrementBalance(address,uint24)"](owner.address,100000)).to.be.revertedWith("This recipient is immutable and cannot have their percentage updated")
    await expect(devPool.addRecipient(owner.address,100000)).revertedWith("Recipient already exists")
    await devPool["incrementBalance(uint256,address)"](ethers.parseUnits("10000"),dolGlobalAddress)

    }); 
 

  });