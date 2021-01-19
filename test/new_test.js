const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("overall testing", function () {
    let owner
    let dai

    it("deploy test dai contract", async () => {
        [owner] = await ethers.getSigners(); //access all default accounts (so this only works for localhost)

        const DaiContract = await ethers.getContractFactory("Dai"); //looks at contract name only, isn't the filename
        dai = await DaiContract.connect(owner).deploy(ethers.BigNumber.from("0")); //BigNumber.toString()
        
        expect(dai, "Contract failed to deploy") //essentially acts as a require function 
    });

    it("test minting and wallet value call", async () => {
        await dai.connect(owner).mint(owner.getAddress(),ethers.BigNumber.from("10000000")) //mint to mint(address, amount)
        const daibalance = await dai.balanceOf(owner.getAddress()) //for view functions
        console.log(`Balance of ${await owner.getAddress()}: ${daibalance.toString()}`) //toString changes bignumber to string
        console.log(dai)
        
        expect(daibalance.toString()=="1000000", "didn't mint correctly")
    });
})