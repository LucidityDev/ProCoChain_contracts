const { expect } = require("chai");
const { abi: abiNeg } = require("../artifacts/contracts/BidTracker.sol/BidTracker.json");
const { abi: abiNegF } = require("../artifacts/contracts/BidTrackerFactory.sol/BidTrackerFactory.json");
const { abi: abiSF } = require("../superfluidartifacts/Superfluid.json");
const { abi: abiSFT } = require("../superfluidartifacts/ERC20WithTokenInfo.json");
const { abi: abiSFCF } = require("../superfluidartifacts/ConstantFlowAgreementV1.json");
const { abi: abiCT } = require("../artifacts/contracts/ConditionalToken.sol/ConditionalTokens.json");
const fs = require("fs"); 
const { ethers } = require("hardhat");

function mnemonic() {
  return fs.readFileSync("./test/mnemonic.txt").toString().trim();
}

describe("Internet Bid Lucidity Full Feature Test", function () {
  let BidFactory, fDai, CT, SF, SFCF;
  let factory_address;
  let owner, bidder, auditor;
  let overrides

  it("connect owner and set contracts", async () => {
    overrides = {
      // gasLimit: 3000000
    };
    
    provider = new ethers.providers.InfuraProvider("goerli", {
      projectId: "faefe1dcd6094fb388019173d2328d8f",
      projectSecret: "dffad28934914b97a5365fa0c2eb9de6"
    });

    owner = ethers.Wallet.fromMnemonic(mnemonic()); //(Step 1) connect your mnemonic
    owner = await owner.connect(provider);
    
    bidder = owner; //just to make things easier for test case. 

    SF = new ethers.Contract(
      "0x22ff293e14F1EC3A09B137e9e06084AFd63adDF9", //rink "0xeD5B5b32110c3Ded02a07c8b8e97513FAfb883B6",
      abiSF,
      owner)
    
    CT = new ethers.Contract(
      "0x36bede640D19981A82090519bC1626249984c908",
      abiCT,
      owner)

    SFCF = new ethers.Contract(
      "0xEd6BcbF6907D4feEEe8a8875543249bEa9D308E8", //rink "0xF4C5310E51F6079F601a5fb7120bC72a70b96e2A",
      abiSFCF,
      owner)

    fDai = new ethers.Contract(
      "0xf2d68898557ccb2cf4c10c3ef2b034b2a69dad00",//rink "0x745861AeD1EEe363b4AaA5F1994Be40b1e05Ff90",
      abiSFT,
      owner)    
    
    // console.log(CT.functions)
    // console.log(SF.functions)
    // console.log(SFCF.functions)
    // console.log(fDai.functions)

    const nowBalance = await fDai.connect(owner).balanceOf(owner.getAddress())
    console.log("fDai balance: ", nowBalance.toString());

    factory_address="0x2BABA5Cadf0f8AbB8A145A9824c2972a08edD2c0", //"0x7697aC32BD4cF0cAe881b93BFc8D168d5352741B"
    project_name = "EMEF ENGº WADIH DARWICH ZACARIAS"
  });

  xit("deploy factory contracts", async function () { 
    const BidFactoryContract = await ethers.getContractFactory(
      "BidTrackerFactory"
    );
    BidFactory = await BidFactoryContract.connect(owner).deploy(overrides);
    factory_address = BidFactory.address
    await BidFactory.deployed()
    console.log("Factory at: ", factory_address)
  });

  it("initiate project", async function () {
    BidFactory = new ethers.Contract(
        factory_address,
        abiNegF,
        owner
    )

    const createNew = await BidFactory.connect(owner).deployNewProject(
      owner.getAddress(),
      CT.address,
      SF.address,
      SFCF.address,
      fDai.address,
      project_name,
      [ethers.BigNumber.from("5"),ethers.BigNumber.from("7"),ethers.BigNumber.from("10")],
      [ethers.BigNumber.from("300"),ethers.BigNumber.from("500"),ethers.BigNumber.from("1000")],
      ethers.BigNumber.from("3"),
      ethers.BigNumber.from("3858024691358"),
      overrides
    );
    await createNew.wait(1);
    console.log("Project deployed")
  });
  
  //there is some error, will have to transfer manually through metamask for now
  it("set deposit and transfer some funds to contract", async function () {
    BidFactory = new ethers.Contract(
      factory_address,
      abiNegF,
      owner
    )

    const lawproject = await BidFactory.connect(owner).getProject(project_name);
    console.log("project at: ", lawproject);
    const lawProjectContract = new ethers.Contract(
        lawproject.projectAddress, 
        abiNeg,
        owner
      );

    const approveTx = await fDai.connect(owner).approve(
      lawProjectContract.address, 
      ethers.BigNumber.from("43680246913580000") //stream amount + deposit amount. 
    );
    console.log(approveTx);
    console.log(approveTx.gasLimit.toString());
    await approveTx.wait(1);

    const sendFDAItx = await lawProjectContract.connect(owner).recieveERC20(ethers.BigNumber.from("33680246913580000"),{gasLimit:3000000})
    console.log(sendFDAItx);
    console.log(sendFDAItx.gasLimit.toString());
    await sendFDAItx.wait(1);

    const newBalance = await fDai.connect(owner).balanceOf(lawProjectContract.address) //project address from later
    console.log("fDai balance contract after transfer: ", newBalance.toString());
  });

  it("create new bid", async function () {
    BidFactory = new ethers.Contract(
      factory_address,
      abiNegF,
      owner
    )

    const lawproject = await BidFactory.getProject(project_name, overrides);
    console.log(lawproject)

    const lawProjectContract = new ethers.Contract(
        lawproject.projectAddress, 
        abiNeg,
        owner
      );

    const newBid = await lawProjectContract.connect(bidder).newBidderTerms(
        [ethers.BigNumber.from("4"),ethers.BigNumber.from("6"),ethers.BigNumber.from("9")],
        [ethers.BigNumber.from("400"),ethers.BigNumber.from("600"),ethers.BigNumber.from("900")],
        ethers.BigNumber.from("3"),
        ethers.BigNumber.from("3858024691358"), //stream rate
        overrides
        )
    console.log(newBid);
    console.log(newBid.gasLimit.toString())
    await newBid.wait(1)

    const bidderterms = await lawProjectContract.connect(owner).loadBidderTerms(bidder.getAddress())
    console.log("new bid from bidder address: ", await bidder.getAddress());
    console.log(bidderterms); 
  });

  it("approve the bid", async function () {
    BidFactory = new ethers.Contract(
      factory_address,
      abiNegF,
      owner
    )

    const lawproject = await BidFactory.getProject(project_name);
    const lawProjectContract = new ethers.Contract(
        lawproject.projectAddress, 
        abiNeg,
        owner
      );

    const approve = await lawProjectContract.connect(owner).approveBidderTerms(
      bidder.getAddress(),
      fDai.address,
      // parseInt((new Date('Jan-29-2021 18:40:35').getTime() / 1000).toFixed(0)),
      {gasLimit:3000000})
    await approve.wait(5); //may be a bit long of a wait lol
    console.log(approve)
  });
  
  //view flows on https://app.superfluid.finance/dashboard
  it("check on superfluid flow from project contract to winning bidder", async function () {
    BidFactory = new ethers.Contract(
      factory_address,
      abiNegF,
      owner
    )

    const lawproject = await BidFactory.getProject(project_name);
    const lawProjectContract = new ethers.Contract(
        lawproject.projectAddress, 
        abiNeg,
        owner
      );
    
    const winningBidder = await lawProjectContract.winningBidder();
    console.log(lawProjectContract.address)
    console.log(winningBidder)
    const data = await SFCF.connect(owner).getFlow(fDai.address, lawProjectContract.address, winningBidder)
    console.log(data)

    // /*you can get data at storage even if private lol*/
    // let i = 0;
    // while (i<25) {
    //   let data_at = await ethers.provider.getStorageAt(lawProjectContract.address, i)
    //   console.log(`Data at slot ${i}: ${data_at}`)
    //   i+=1
    // }
  })

  //need to update CT functions later
  xit("run through Gnosis conditional token and audit report as oracle", async function () {
    //escrow acts as oracle here
    BidFactory = new ethers.Contract(
      "0xA6257e76D645Ef54B03255c77dF30c9947530DBf",
      abiNegF,
      owner
    )

    const lawproject = await BidFactory.getProject(project_name);
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
  //test security deposit resolve/cancel flow?

  ///ignore below for now until bandwidth API is nicely set up///
  xit("testing data oracle to report on milestone 3mb", async () => {
    //need to setup a new contract that acts as the data oracle on chain, so that it can be replaced if neccessary.     

    //this should ultimately report conditions, so oracle contract should be the auditor. 
  })
});

