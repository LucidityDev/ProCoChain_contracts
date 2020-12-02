const { expect } = require("chai");
const { abi: abiNeg } = require("../artifacts/contracts/BidTracking.sol/BidTracker.json");

describe("Internet Bid Lucidity Full Feature Test", function () {
  let BidFactory, Dai, CT;
  let owner, bidder, auditor, funder;

  it("deploy factory contracts", async function () {
     [owner, bidder, auditor, funder] = await ethers.getSigners(); //jsonrpc signers from default 20 accounts with 10000 ETH each

    //conditional tokens
    const CTContract = await ethers.getContractFactory("ConditionalTokens"); //contract name here
    CT = await CTContract.deploy();

    //using Dai contract 
    const DaiContract = await ethers.getContractFactory("Dai");
    Dai = await DaiContract.connect(funder).deploy(ethers.BigNumber.from("0"));
    await Dai.connect(funder).mint(funder.getAddress(),ethers.BigNumber.from("100")) //mint to 
    
    const daibalance = await Dai.balanceOf(funder.getAddress());
    console.log("funder address: ", await funder.getAddress());
    console.log("funder balance of Dai: ", daibalance.toString());
  
    //deploy neg contract
    const BidFactoryContract = await ethers.getContractFactory(
      "BidTrackerFactory"
    );
    BidFactory = await BidFactoryContract.deploy();
  });

  it("initiate project, bid, and then approval", async function () {
    //create project to be bid on
    await BidFactory.connect(owner).deployNewProject(
      owner.getAddress(),
      CT.address,
      "Honduras Agriculture Project",
      "HAP",
      "Milestone1; Milestone2; Milestone3",
      [ethers.BigNumber.from("3"),ethers.BigNumber.from("6"),ethers.BigNumber.from("9")],
      [ethers.BigNumber.from("300"),ethers.BigNumber.from("600"),ethers.BigNumber.from("900")]
    );

    const lawproject = await BidFactory.getProject("Honduras Agriculture Project");
    console.log("Project owner terms deployed with new bid tracker")
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
    console.log("bidder address: ", await bidder.getAddress());
    console.log(bidderterms)
  });
});

