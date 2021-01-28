const { expect } = require("chai");
const { abi: abiCFTest } = require("../artifacts/contracts/CFTest.sol/CFTest.json");
const { abi: abiSF } = require("../superfluidartifacts/Superfluid.json");
const { abi: abiSFT } = require("../superfluidartifacts/ERC20WithTokenInfo.json");
const { abi: abiSFCF } = require("../superfluidartifacts/ConstantFlowAgreementV1.json");
const { abi: abiCT } = require("../artifacts/contracts/ConditionalToken.sol/ConditionalTokens.json");
// const SuperfluidSDK = require("@superfluid-finance/js-sdk");
// const keccak256 = require('keccak256')
const fs = require("fs"); 
const { ethers } = require("hardhat");

function mnemonic() {
  return fs.readFileSync("./test/mnemonic.txt").toString().trim();
}

describe("Internet Bid Lucidity Full Feature Test", function () {
  let CFTest, fDai, CT, SFCF;
  let owner, bidder, auditor;
  
  it("connect owner and set contracts", async () => {
    provider = new ethers.providers.InfuraProvider("rinkeby", {
        projectId: "d635ea6eddda4720824cc8b24380e4a9",
        projectSecret: "b4ea2b15f0614105a64f0e8ba1f2bffa"
      });

    owner = ethers.Wallet.fromMnemonic(mnemonic()); //(Step 1) connect your mnemonic
    owner = await owner.connect(provider);
    
    bidder = owner; //just to make things easier for test case. 

    SF = new ethers.Contract(
      "0xeD5B5b32110c3Ded02a07c8b8e97513FAfb883B6",
      abiSF,
      owner)
    
    CT = new ethers.Contract(
      "0x36bede640D19981A82090519bC1626249984c908",
      abiCT,
      owner)

    SFCF = new ethers.Contract(
      "0xF4C5310E51F6079F601a5fb7120bC72a70b96e2A",
      abiSFCF,
      owner)

    fDai = new ethers.Contract(
      "0x745861aed1eee363b4aaa5f1994be40b1e05ff90",
      abiSFT,
      owner)    
    
    // console.log(CT.functions)
    // console.log(SF.functions)
    // console.log(SFCF.functions)
    // console.log(fDai.functions)

    const nowBalance = await fDai.connect(owner).balanceOf(owner.getAddress())
    console.log("fDai balance: ", nowBalance.toString());

    const newBalance = await fDai.connect(owner).balanceOf("0x482Cc18326aBe364DA1E149A2815Ad62dBCa61E8")
    console.log("fDai balance contract: ", newBalance.toString());

    // const CFTestContract = await ethers.getContractFactory(
    //     "CFTest"
    //   );

    // CFTest = await CFTestContract.connect(owner).deploy(
    // "0xeD5B5b32110c3Ded02a07c8b8e97513FAfb883B6", //sf
    // "0xF4C5310E51F6079F601a5fb7120bC72a70b96e2A", //CFAv1
    // "0x745861AeD1EEe363b4AaA5F1994Be40b1e05Ff90", //fDai
    // ethers.BigNumber.from("200")
    // );
  });

  xit("run approval for transfer funds", async function () {
    CFTest = new ethers.Contract(
        "0x482Cc18326aBe364DA1E149A2815Ad62dBCa61E8",
        abiCFTest,
        owner
    )
    console.log(CFTest.functions);
    await fDai.connect(owner).approve(
        CFTest.address, 
        ethers.BigNumber.from("38580246913580000") //deposit and some stream amount
    );
    // await CFTest.connect(owner).recieveERC20(ethers.BigNumber.from("38580246913580000")) //this may fail the first time as the approval takes time to mine
  });

  xit("try cashflow", async function () {
      CFTest = new ethers.Contract(
          "0x482Cc18326aBe364DA1E149A2815Ad62dBCa61E8",
          abiCFTest,
          owner
      )
      // console.log(CFTest.functions);
      
      const overrides = {
          gasLimit: ethers.BigNumber.from("10000000"),
        };

      // await CFTest.connect(owner).startFromHost(
      //   fDai.address,
      //   owner.getAddress(),
      //   ethers.BigNumber.from("200"),
      //   parseInt((new Date('Jan-29-2021 18:40:35').getTime() / 1000).toFixed(0)),
      //   overrides
      // );

      const transaction = await CFTest.connect(owner).startFromHostBasic(
        fDai.address,
        owner.getAddress(), //send from contract to owner
        ethers.BigNumber.from("38580246913580"),
        overrides
      );

      console.log(transaction);
    });
});