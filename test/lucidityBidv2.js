const { expect } = require("chai");
const { abi: abiNeg } = require("../artifacts/contracts/BidTracker.sol/BidTracker.json");
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
  let BidFactory, fDai, CT, SFCF;
  let owner, bidder, auditor;
  
  it("connect owner", async () => {
    provider = new ethers.providers.InfuraProvider("rinkeby", {
        projectId: "d635ea6eddda4720824cc8b24380e4a9",
        projectSecret: "b4ea2b15f0614105a64f0e8ba1f2bffa"
      });

    owner = ethers.Wallet.fromMnemonic(mnemonic()); //(Step 1) connect your mnemonic
    owner = await owner.connect(provider);
    
    bidder = owner; //just to make things easier for test case. 

    // //connect sf 
    // const sf = new SuperfluidSDK.Framework({
    //   version: "v1", // Protocol release version
    //   web3Provider: provider, // your web3 provider
    //   tokens: ["fDAI"]
    // });

    // await sf.initialize();
    // const agg = await sf.getAgreementClass(keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1"))
    // console.log(agg)

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
      "0x745861AeD1EEe363b4AaA5F1994Be40b1e05Ff90",
      abiSFT,
      owner)    
    
    console.log(CT.functions)
    console.log(SF.functions)
    console.log(SFCF.functions)
    console.log(fDai.functions)

    const nowBalance = await fDai.connect(owner).balanceOf(owner.getAddress())
    console.log("fDai balance: ", nowBalance.toString());
  });

  //Nick, make sure to deploy and test bid/approval/start of flow
  xit("deploy factory contracts", async function () { 
    //(Step 3) deploy bid contract. you should be able to find the deployed contract address through etherscan. 
    const BidFactoryContract = await ethers.getContractFactory(
      "BidTrackerFactory"
    );
    BidFactory = await BidFactoryContract.deploy();

    // (worry about this after you got your deploy to work, Step 4) Superfluid contract address and instance, where can you find its API so we can use it? 
  });

  xit("initiate project", async function () {
    //will need to create a contract instance here after deploying for first time
    //BidFactory = new ethers.Contract(
    //     "factoryAddress",
    //     abiNeg,
    //     owner
    // )

    //create project to be bid on. Maybe endtime has to be in here too? instead of at approval. 
    //     address _owner,
    //     address _ConditionalTokens,
    //     address _Superfluid,
    //     address _ERC20,
    //     string memory _name,
    //     uint256[] memory _bountySpeedTargets,
    //     uint256[] memory _bounties,
    //     uint256 _streamSpeedTarget,
    //     uint256 _streamAmountTotal
    await BidFactory.connect(owner).deployNewProject(
      owner.getAddress(),
      CT.address,
      SFCF.address,
      fDai.address,
      "Honduras Agriculture Project",
      [ethers.BigNumber.from("5"),ethers.BigNumber.from("7"),ethers.BigNumber.from("10")],
      [ethers.BigNumber.from("300"),ethers.BigNumber.from("500"),ethers.BigNumber.from("1000")],
      ethers.BigNumber.from("3"),
      ethers.BigNumber.from("1000")
    );
  });

  xit("bid, and then approval", async function () {
    const lawproject = await BidFactory.getProject("Honduras Agriculture Project");
    console.log(lawproject)

    const lawProjectContract = new ethers.Contract(
      lawproject.projectAddress,
        abiNeg,
        owner
      );

    await lawProjectContract.connect(bidder).newBidderTerms(
        [ethers.BigNumber.from("4"),ethers.BigNumber.from("6"),ethers.BigNumber.from("9")],
        [ethers.BigNumber.from("400"),ethers.BigNumber.from("600"),ethers.BigNumber.from("900")])

    const bidderterms = await lawProjectContract.connect(owner).loadBidderTerms(bidder.getAddress())
    console.log("new bid from bidder address: ", await bidder.getAddress());
    console.log(bidderterms);

    //need approval function call, and check if stream kickoff worked
  });

  //view flows on https://app.superfluid.finance/dashboard, and create an it test to view flow
  
  ////Andrew will add these
  //add CT functions
  //test CT and flow reading/withdrawal
  //test security deposit resolve

  ///ignore below for now///
  xit("testing data oracle to report on milestone 3mb", async () => {
    //need to setup a new contract that acts as the data oracle on chain, so that it can be replaced if neccessary.     

    //this should ultimately report conditions, so oracle contract should be the auditor. 
  })
  
  xit("sablier create flow, check flow info", async () => {
    //setting time boundaries, must be multiple of transfer amount 
    const startTime = ethers.BigNumber.from(parseInt((new Date('Dec-06-2020 18:40:30').getTime() / 1000).toFixed(0)))
    const endTime = ethers.BigNumber.from(parseInt((new Date('Dec-06-2020 18:40:35').getTime() / 1000).toFixed(0)))
    
    await Dai.connect(owner).approve(Sablier.address,ethers.BigNumber.from("100")) //dai approval 

    streamId = await Sablier.connect(owner).createStream(bidder.getAddress(),ethers.BigNumber.from("100"),Dai.address,startTime,endTime)

    //check stream balance
    const streamInfoI = await Sablier.connect(owner).getStream(ethers.BigNumber.from("1"))
    console.log("total stream size/deposit (dai): " + streamInfoI.deposit.toString())
    console.log("rate per second: " + streamInfoI.ratePerSecond.toString())
    console.log("stop time: " + new Date(parseInt(streamInfoI.stopTime.toString()) * 1000))

    const balanceAfterCreate = await Dai.balanceOf(owner.getAddress())
    console.log("Owner balance dai post stream create: " + balanceAfterCreate)

    const balanceOfStream = await Sablier.connect(bidder).balanceOf(ethers.BigNumber.from("1"), bidder.getAddress())
    console.log("Available to withdraw from stream: " + balanceOfStream)
    // const withdrawInfo = await Sablier.connect(bidder).withdrawFromStream(streamId, ethers.BigNumber.from("100"))
    // console.log(withdrawInfo)
  });
});

