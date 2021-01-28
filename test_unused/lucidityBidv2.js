const { expect } = require("chai");
const { abi: abiNeg } = require("../artifacts/contracts/BidTracker.sol/BidTracker.json");
const { abi: abiNegF } = require("../artifacts/contracts/BidTrackerFactory.sol/BidTrackerFactory.json");
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
  let factory_address;
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
      "0x745861AeD1EEe363b4AaA5F1994Be40b1e05Ff90",
      abiSFT,
      owner)    
    
    // console.log(CT.functions)
    // console.log(SF.functions)
    // console.log(SFCF.functions)
    // console.log(fDai.functions)

    const nowBalance = await fDai.connect(owner).balanceOf(owner.getAddress())
    console.log("fDai balance: ", nowBalance.toString());

    factory_address="0x13e5Cc4beAF377BcC4318A6AB3698CE846f4FA85"
  });

  //Nick, make sure to deploy and test bid/approval/start of flow
  xit("deploy factory contracts", async function () { 
    //(Step 3) deploy bid contract. you should be able to find the deployed contract address through etherscan. 
    const BidFactoryContract = await ethers.getContractFactory(
      "BidTrackerFactory"
    );
    BidFactory = await BidFactoryContract.connect(owner).deploy();
  });

  xit("initiate project", async function () {
    BidFactory = new ethers.Contract(
        factory_address,
        abiNegF,
        owner
    )

    //create project to be bid on. Maybe endtime has to be in here too? instead of at approval. 
    //     address _owner,
    //     address _ConditionalTokens,
    //     address _SuperfluidICFA,
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
      "EEEE ABNAEL MACHADO DE LIMA - CENE",
      [ethers.BigNumber.from("5"),ethers.BigNumber.from("7"),ethers.BigNumber.from("10")],
      [ethers.BigNumber.from("300"),ethers.BigNumber.from("500"),ethers.BigNumber.from("1000")],
      ethers.BigNumber.from("3"),
      ethers.BigNumber.from("500")
    );
  });

  xit("set deposit and transfer funds", async function () {
    BidFactory = new ethers.Contract(
      factory_address,
      abiNegF,
      owner
    )

    const lawproject = await BidFactory.getProject("EEEE ABNAEL MACHADO DE LIMA - CENE");
    console.log(lawproject)

    const lawProjectContract = new ethers.Contract(
      lawproject.projectAddress, //'0xD2820666665C127852213554E2B1cfA8A8199Ef8',
        abiNeg,
        owner
      );

    await fDai.connect(owner).approve(
      lawProjectContract.address, 
      ethers.BigNumber.from("200") //deposit and some stream amount
    );
    await lawProjectContract.connect(owner).recieveERC20(ethers.BigNumber.from("100"))
  });

  xit("bid", async function () {
    BidFactory = new ethers.Contract(
      factory_address,
      abiNegF,
      owner
    )

    const lawproject = await BidFactory.getProject("EEEE ABNAEL MACHADO DE LIMA - CENE");
    const lawProjectContract = new ethers.Contract(
      lawproject.projectAddress, 
        abiNeg,
        owner
      );
    //console.log(lawProjectContract.functions)

    // await lawProjectContract.connect(bidder).newBidderTerms(
    //     [ethers.BigNumber.from("4"),ethers.BigNumber.from("6"),ethers.BigNumber.from("9")],
    //     [ethers.BigNumber.from("400"),ethers.BigNumber.from("600"),ethers.BigNumber.from("900")],
    //     ethers.BigNumber.from("3"),
    //     ethers.BigNumber.from("500")
    //     )

    const bidderterms = await lawProjectContract.connect(owner).loadBidderTerms(bidder.getAddress())
    console.log("new bid from bidder address: ", await bidder.getAddress());
    console.log(bidderterms); //will show up as null the first time
  });

  xit("approve", async function () {
    BidFactory = new ethers.Contract(
      factory_address,
      abiNegF,
      owner
    )

    const lawproject = await BidFactory.getProject("EEEE ABNAEL MACHADO DE LIMA - CENE");
    const lawProjectContract = new ethers.Contract(
      lawproject.projectAddress, 
        abiNeg,
        owner
      );

      const overrides = {
        gasLimit: ethers.BigNumber.from("10000000"),
      };

    await lawProjectContract.connect(owner).approveBidderTerms(
      bidder.getAddress(),
      fDai.address,
      parseInt((new Date('Jan-29-2021 18:40:35').getTime() / 1000).toFixed(0)),
      overrides)
  });
  //view flows on https://app.superfluid.finance/dashboard, and create an it test to view flow
  
  ////Andrew will add these
  //add CT functions
  
  xit("run through Gnosis conditional token and audit report as oracle", async function () {
    //escrow acts as oracle here
    BidFactory = new ethers.Contract(
      "0xA6257e76D645Ef54B03255c77dF30c9947530DBf",
      abiNegF,
      owner
    )

    const lawproject = await BidFactory.getProject("EEEE ABNAEL MACHADO DE LIMA - CENE");
    const lawProjectContract = new ethers.Contract(
      lawproject.projectAddress,
        abiNeg,
        owner
      );

    //questionId->conditionId->outcome slots->CollectionId (of different outcomes)->positionId(tying collateral type)->split to stake
    //1) run getConditionId() and prepareCondition() with same parameters, Auditor should be address of oracle.
    //0x0000000000000000000000000000000000000000000000000000000000000001 as question id (second parameter), can have a few outcomes for failed, passed, ambigious
    const conditionOne = await CT.connect(bidder).getConditionId(
      lawProjectContract.address,
      "0x0000000000000000000000000000000000000000000000000000000000000001",
      2
    );
    await CT.connect(bidder).prepareCondition(
      lawProjectContract.address,
      "0x0000000000000000000000000000000000000000000000000000000000000001",
      2
    );

    //2) check with getOutcomeSlotCount() with the return of getConditionId() to check it ran correctly.
    //bit arrays (binary) are for storing outcomes. 0b001 == 1, 0b010 == 2, 0b011 == 3, 0b100 == 4, 0b101 == 5, 0b111 == 6. So now a uint256 can store 256 different bits.
    //3) Say 3 outcome slots, A, B, C we want to use it test inclusion in a set.
    //                        0, 1, 1 -> 0b110 -> 6 now run getCollectionId (0x00000...,conditionId, 6). If only A is true (1,0,0) this becomes 0b001, which is now 1.
    //                        another example of index set values for outcome slots: lo, hi (1,0) -> 0b01 -> 1. (0,1) -> 0b10 -> 2.
    const ApproveMilestoneOne = await CT.connect(bidder).getCollectionId(
      "0x0000000000000000000000000000000000000000000000000000000000000000",
      conditionOne,
      1 //0b01
    );

    const RejectMilestoneOne = await CT.connect(bidder).getCollectionId(
      "0x0000000000000000000000000000000000000000000000000000000000000000",
      conditionOne,
      2 //0b10
    );
    //4) collateral is set with getPositionId(collateral address (dai), collectionId). this is setting the type of collateral, not amount yet. This is also the ERC1155 unique identification for this token!
    const ApprovalOnePosition = await CT.connect(bidder).getPositionId(
      Dai.address,
      ApproveMilestoneOne
    );
    const RejectOnePosition = await CT.connect(bidder).getPositionId(
      Dai.address,
      RejectMilestoneOne
    );
    //5) set spender approval set to conditionaltoken contract address (already set in our case)
    //6) split position (most important step) is called by address with the collateral (collateralToken (address of dai), parentCollectionId (all 0's 32 bytes), conditionId from 1, partition (outcome slots index set value, so [6,1], amount (value/# of tokens to take))
    //now the CT is holding the collateral and address the held the collateral now holds the CT. You can now use balanceOf(address (so project address), positionId) where positionId is from step 4 to figure out how many CT for each position (outcome) you are holding.
    const allowedTransfer = await Dai.allowance(
      lawProjectContract.address, //owner
      CT.address //spender
    );
    console.log(
      "How much dai will be staked on conditional token: ",
      allowedTransfer.toString()
    );

    await firstEscrow
      .connect(bidder)
      .callSplitPosition(
        Dai.address,
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        conditionOne,
        [1, 2],
        ethers.BigNumber.from("10")
      );

    const daibalance = await Dai.balanceOf(CT.address);
    console.log("CT balance of Dai: ", daibalance.toString());

    const CTbalance = await CT.balanceOf(
      lawProjectContract.address,
      ApprovalOnePosition
    );
    console.log(
      "Escrow balance of CT in Approved Condition: ",
      CTbalance.toString()
    );

    console.log("bidder address before call: ", await bidder.getAddress())
    //transfer to bidder, must be called by bidder
    await firstEscrlawProjectContractow.connect(bidder).transferCT(ApprovalOnePosition);

    const CTbalanceBidder = await CT.balanceOf(
      bidder.getAddress(),
      ApprovalOnePosition
    );

    const CTbalanceAfter = await CT.balanceOf(
      lawProjectContract.address,
      ApprovalOnePosition
    );
    console.log(
      "Escrow balance of CT in Approved Condition after transfer: ",
      CTbalanceAfter.toString()
    );
    const CTbalanceAfter2 = await CT.balanceOf(
      lawProjectContract.address,
        RejectOnePosition
      );
      console.log(
        "Escrow balance of CT in Rejected Condition after transfer: ",
        CTbalanceAfter2.toString()
      );

    //8) reportpayout() is called only by oracle address, with (questionId, outcome slots [1,0,0]) not sure where outcome slots are tied to addresses?
    await lawProjectContract
      .connect(auditor)
      .callReportPayouts(
        "0x0000000000000000000000000000000000000000000000000000000000000001",
        [ethers.BigNumber.from("1"), ethers.BigNumber.from("0")]
      );
    console.log("audit passed, result sent");

  //   //checking condition was reported
  //   const reportStatus = await CT.connect(bidder).filter.ConditionResolution(
  //     conditionOne,
  //     "0x0000000000000000000000000000000000000000000000000000000000000001",
  //     2,
  //     [ethers.BigNumber.from("1"), ethers.BigNumber.from("0")]
  // );
  //     console.log(reportStatus)

    //9) redemption with redeemPositions(dai,parent(all 0's again), conditionId, indexset (outcome slots as index set so [1,0,0] is 0)). CT now get burned.
    await CT.connect(bidder).redeemPositions(
      fDai.address,
      "0x0000000000000000000000000000000000000000000000000000000000000000",
      conditionOne,
      [ethers.BigNumber.from("1")]
    );

    const daibalanceend = await fDai.balanceOf(bidder.getAddress());
    console.log(
      "Bidder balance of Dai after redemption: ",
      daibalanceend.toString()
    );
    //escrow needs a redemption function

    //cheers you're done for now! :) Implement payback system later, where either the escrow redeems and has to return ERC20 to token contract, or bidder sends ERC20 back. 
  });
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

