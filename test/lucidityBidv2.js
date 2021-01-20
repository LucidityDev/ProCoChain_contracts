const { expect } = require("chai");
const { abi: abiNeg } = require("../artifacts/contracts/BidTracker.sol/BidTracker.json");
const { abi: abiSF } = require("../superfluidartifacts/Superfluid.json");
const { abi: abiSFT } = require("../superfluidartifacts/SuperToken.json");
const { abi: abiSFCF } = require("../superfluidartifacts/ConstantFlowAgreementV1.json");

const { ethers } = require("hardhat");

describe("Internet Bid Lucidity Full Feature Test", function () {
  let BidFactory, Dai, CT, Sablier, SF, SFT, SFCF;
  let streamId; //for sablier
  let owner, bidder, auditor;

  it("deploy factory contracts", async function () {
     [owner, bidder, auditor] = await ethers.getSigners(); 

    //conditional tokens
    const CTContract = await ethers.getContractFactory("ConditionalTokens");
    CT = await CTContract.deploy();

    //using Dai contract 
    const DaiContract = await ethers.getContractFactory("Dai");
    Dai = await DaiContract.connect(owner).deploy(ethers.BigNumber.from("0"));
    await Dai.connect(owner).mint(owner.getAddress(),ethers.BigNumber.from("10000000")) //mint to 
    
    const daibalance = await Dai.balanceOf(owner.getAddress());
    console.log("owner address: ", await owner.getAddress());
    console.log("owner balance of Dai: ", daibalance.toString());
  
    //deploy bid contract
    const BidFactoryContract = await ethers.getContractFactory(
      "BidTrackerFactory"
    );
    BidFactory = await BidFactoryContract.deploy();

    //Sablier
    //const SablierContract = await ethers.getContractFactory("Sablier");
    //Sablier = await SablierContract.deploy();

    ////getting contract factory for SF, SFT, SF Constant Flow *ignore*
    // SF = await SFContract.deploy();
    // SFT = await SFTContract.deploy();
    // SFCF = await SFCFContract.deploy();
    // const createdaixWrapper = await SF.connect(owner).createERC20Wrapper(Dai.address,ethers.BigNumber.from("18"), "Dai Wrapped","Daix"); //Dai.decimal()
    // console.log(createdaixWrapper)
    // const daixWrapper = await SF.getERC20Wrapper(Dai.address, "Dai");
    // console.log(daixWrapper)
    // const daix = await SFT.at(daixWrapper.wrapperAddress); //not sure if createwrapper launches an SFT?
    // SF.connect(owner).callAgreement(CFCF.address, CFCA.connect(owner).createFlow(daix.address, bidder.getAddress(), "385802469135802", "0x"))
  });

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

  it("initiate project", async function () {
    //create project to be bid on
    await BidFactory.connect(owner).deployNewProject(
      owner.getAddress(),
      CT.address,
      Sablier.address,
      "Honduras Agriculture Project",
      [ethers.BigNumber.from("3"),ethers.BigNumber.from("5"),ethers.BigNumber.from("10")],
      [ethers.BigNumber.from("300"),ethers.BigNumber.from("500"),ethers.BigNumber.from("1000")]
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

  xit("testing data oracle to report on milestone 3mb", async () => {
    //need to setup a new contract that acts as the data oracle on chain, so that it can be replaced if neccessary.     

    //this should ultimately report conditions, so oracle contract should be the auditor. 
  })
});

