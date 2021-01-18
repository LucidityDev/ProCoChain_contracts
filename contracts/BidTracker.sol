// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.7.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface IConditionalTokens {
    // how do we flexibly set outcomes?
    // getConditionId
    // prepareCondition
    // getCollectionId
    // getPositionId

    function splitPosition(
        address collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256[] calldata partition,
        uint256 amount
    ) external;

    function reportPayouts(bytes32 questionId, uint256[] calldata payouts)
        external;
}

//to fill in
interface IConstantFlowAgreementV1 {

}

contract BidTracker {
    
    using SafeMath for uint256;
	
    bool public ownerApproval = false;
    uint16 public basePrice; //needs to be added to constructor
    string public projectName; //probably could be stored as bytes?
    address public owner;
    address private oracleAddress;
    address public winningBidder; //this only needs to be stored if we have post bid edits
    address[] public all_bidders; //should be able to replace this with event
    
    uint256[] public bountySpeedTargetOwner; //wonder if string would be cheaper, also if timeline is neccessary
    uint256[] public targetBountyOwner; 
    uint256 public speedTargetOwner;
    uint256 public streamAmountOwner;

    IERC1155 private IERC1155C;
    IConditionalTokens private ICT;
    IConstantFlowAgreementV1 private ICFA;

    event currentTermsApproved(address approvedBidder);
    event newBidSent(
        address Bidder,
        uint256[] speedtargetBidder,
        uint256[] targetbountyBidder
    );

    //these need to be private
    mapping(address => uint256[]) private BidderToTargets;
    mapping(address => uint256[]) private BidderToBounties;
    mapping(address => uint256) private BidderToStreamSpeed;
    mapping(address => uint256) private BidderToStreamAmount;

    constructor(
        address _owner,
        address _ConditionalToken,
        address _Superfluid,
        string memory _name,
        uint256[] memory _bountySpeedTargets,
        uint256[] memory _bounties,
	uint256 _streamSpeedTarget,
	uint256 _streamAmountTotal
    ) public {
        owner = _owner;
        projectName = _name;
        bountySpeedTargetOwner = _bountySpeedTargets;
        targetBountyOwner = _bounties;
	speedTargetOwner = _streamSpeedTarget;	
	streamAmountOwner = _streamAmountTotal;
        ICFA = IConstantFlowAgreementV1(_Superfluid);
        IERC1155C = IERC1155(_ConditionalToken);
        ICT = IConditionalTokens(_ConditionalToken);
    }

    //called by bidder submit
    function newBidderTerms(
        uint256[] calldata _bountySpeedTargets,
        uint256[] calldata _bounties,
	uint256 _streamSpeedTarget,
	uint256 _streamAmountTotal
    ) external {
        require(
            ownerApproval == false,
            "another proposal has already been accepted"
        );
        require(msg.sender != owner, "owner cannot create a bid");
        BidderToTargets[msg.sender] = _bountySpeedTargets;
        BidderToBounties[msg.sender] = _bounties;
	BidderToStreamSpeed[msg.sender] = _streamSpeedTarget;
	BidderToStreamAmount[msg.sender] = _streamAmountTotal;
        all_bidders.push(msg.sender);
        emit newBidSent(msg.sender, _speedtargets, _bounties);
    }

    //called by owner approval submit
    function approveBidderTerms(
        address _bidder,
  	// ISuperToken token,
	// address receiver,
	// uint256 endTime,
	// address _CTaddress,
   	// address _ERC20address,
        // address auditor,
	// uint startdate,
	// uint
    ) external {
        require(msg.sender == owner, "Only project owner can approve terms");
        require(ownerApproval == false, "A bid has already been approved");
        ownerApproval = true;
        winningBidder = _bidder;

        //adjust owner terms to be same as bidder terms
        targetBountyOwner = BidderToBounties[_bidder];
        bountySpeedTargetOwner = BidderToTargets[_bidder];
	speedTargetOwner = BidderToStreamSpeed[_bidder];
	streamAmountOwner = BidderToStreamAmount[_bidder];

        //kick off sablier stream

	startFlow(token, receiver, streamAmountOwner, endTime);
	
	//kick off CT setting loop, though this is going to be like 4 * # milestones of approvals
        //emit newStream()
        //emit CTidandoutcomes() maybe some function that rounds down on report. Need chainlink to resolve this in the future.

        emit currentTermsApproved(_bidder);
    }

	function startFlow(ISuperToken token, address receiver, uint256 _streamAmountOwner, uint _endTime) private {
	
		uint256 flowRate = calculateFlowRate(_streamAmountOwner, _endTime);

		//	ICFA.createFlow(
		//      token,
		//      receiver,
		//      flowRate,
		//      "0x"
		//  );

	}

	function calculateFlowRate(uint256 _streamAmountOwner, uint256 _endTime) private view returns (uint256) {
		uint256 _totalSeconds = calculateTotalSeconds(_endTime);
		uint256 _flowRate = _streamAmountOwner.div( _totalSeconds);
		return _flowRate;
	}
	
	function calculateTotalSeconds(uint256 _endTime) private view returns (uint256) {
		uint256 totalSeconds = _endTime.sub(block.timestamp);
		return totalSeconds;
	}

    //CT functions, loop through length of milestones//
    function setPositions() external {
        // getConditionId
        // prepareCondition
        // getCollectionId
        // getPositionId
        // return all the gets?
    }

    function callSplitPosition(
        address tokenaddress,
        bytes32 parent,
        bytes32 conditionId,
        uint256[] calldata partition,
        uint256 value //bytes32 approvalPositionId,
    ) external {
        ICT.splitPosition(tokenaddress, parent, conditionId, partition, value);
        //totalValue = totalValue.sub(value); figure out how this is being called (i.e. how is money getting to this contract in the first place)
    }

    //transfer CT tokens to bidder wallet for a certain positionId. There should be a way to transfer CT to owner too.
    function transferCTtoBidder(uint256 positionId) external payable {
        require(
            msg.sender == winningBidder,
            "only bidder can redeem conditional tokens"
        );
        uint256 heldAmount = IERC1155C.balanceOf(address(this), positionId); //need to make it so only approve position id is transferrable

        IERC1155C.safeTransferFrom(
            address(this),
            msg.sender,
            positionId,
            heldAmount,
            ""
        );
    }

    //reportPayouts() should call fetchOracle()
    function callReportPayouts(bytes32 questionID, uint256[] calldata outcome)
        external
    {
        require(msg.sender == owner, "not owner"); //later this should only be called from governance contract with a vote
        ICT.reportPayouts(questionID, outcome);
    }

    function updateOracle(address newOracleAddress) external {
        require(msg.sender == owner, "Only owner can update oracle");
        oracleAddress = newOracleAddress;
    }

    function fetchOracleData(uint256 speedtarget) internal {
        //still need to do this
    }

    // //winning bidder can propose new bid terms 
    // function adjustBidTerms(uint256[] memory _bountySpeedTargets, uint256[] memory _bounties, uint256 streamSpeedTarget, uint256 _streamAmountTotal) public {
    //     require(ownerApproval == true, "a bid has not been approved yet");
    //     require(msg.sender == winningBidder, "only approved bidder can submit new terms");
    //     BidderToBounties[msg.sender] = _bounties;
    //     BidderToTargets[msg.sender] = _speedtargets;
    //	   BidderToStreamSpeed[msg.sender] = _streamSpeedTarget;
    //	   BidderToStreamAmount[msg.sender] = _streamAmountTotal;
    // }

    // //owner needs to approve new terms
    // function approveNewTerms() public {
    //     require(ownerApproval == true, "a bid has not been approved yet");
    //     require(msg.sender == owner, "only owner can approve new terms");

    //     targetBountyOwner = BidderToBounties[winningBidder];
    //     bountySpeedTargetOwner = BidderToTargets[winningBidder];
    //     speedTargetOwner = BidderToStreamSpeed[winningBidder];
    //     streamAmountOwner = BidderToStreamAmount[winningBidder];
    //     //this has to somehow affect stream? start and cancel again here? 
    // }

    //////Below are all external view functions

    //loads owner terms for bidder to see
    function loadOwnerTerms()
        external
        view
        returns (
            uint256[] memory _bountySpeedTargets,
            uint256[] memory _bounties,
	    uint256 _streamSpeedTarget,
	    uint256 _streamAmountTotal
        )
    {
        return (bountySpeedTargetOwner, targetBountyOwner, speedTargetOwner, streamAmountOwner);
    }

    //loads all bidders addresses in an array
    function getAllBidderAddresses() external view returns (address[] memory) {
        return (all_bidders);
    }

    //loads bidder terms for owner to see
    function loadBidderTerms(address _bidder)
        external
        view
        returns (uint256[] memory _bountySpeedtargets, uint256[] memory _bounties, uint256 _streamSpeedTarget, uint256 _streamAmountTotal)
    {
        require(
            msg.sender == owner,
            "Only project owner can see proposed terms"
        );
        return (BidderToTargets[_bidder], BidderToBounties[_bidder], BidderToStreamSpeed[_bidder], BidderToStreamAmount[_bidder]);
    }
}
