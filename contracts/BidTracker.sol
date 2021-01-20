// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.7.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
    string public projectName;
    address public owner;
    address private oracleAddress;
    address public winningBidder;
    address[] public all_bidders; //should be able to replace this with event and theGraph
    uint256[] public bountySpeedTargetOwner;
    uint256[] public targetBountyOwner;
    uint256 public speedTargetOwner;
    uint256 public streamAmountOwner;
    uint256 private BidderEndtime;

    IERC1155 private IERC1155C;
    IERC20 private IERC20C;
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
        address _ERC20,
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
        IERC20C = IERC20(_ERC20);
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
        ISuperToken token,
        address receiver,
        uint256 endTime,
        address _CTaddress,
        address _ERC20address,
        address auditor,
        uint256 startdate
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
        
        BidderEndtime = endTime;

        setDeposit();
        startFlow(token, receiver, streamAmountOwner, endTime);

        //kick off CT setting loop, though this is going to be like 4 * # milestones of approvals
        //emit newStream()
        //emit CTidandoutcomes() maybe some function that rounds down on report. Need chainlink to resolve this in the future.
        emit currentTermsApproved(_bidder);
    }

    function setDeposit() internal {
        //must have approval first from owner address to this contract address
        uint256 _value = streamAmountOwner.div(10); //10% of total stream amount is security deposit
        IERC20C.transferFrom(owner, address(this), _value);
    }

    function resolveDeposit() internal {
        if (block.timestamp >= BidderEndtime) {
            //funds transfer to bidder
            IERC20C.approve(winningBidder, streamAmountOwner.div(10)); 
            IERC20C.transferFrom(address(this), winningBidder, streamAmountOwner.div(10));
        }
        else {
            //funds transfer back to owner
            IERC20C.approve(owner, streamAmountOwner.div(10));
            IERC20C.transferFrom(address(this), owner, streamAmountOwner.div(10)); 
        }
    }

    function endFlow() public {
        //ICFA.deleteFlow() //Nick fill in rest here please
        resolveDeposit();
    }

    function startFlow(
        ISuperToken token,
        address receiver,
        uint256 _streamAmountOwner,
        uint256 _endTime
    ) private {
        uint256 flowRate = calculateFlowRate(_streamAmountOwner, _endTime);

        //	ICFA.createFlow(
        //      token,
        //      receiver,
        //      flowRate,
        //      "0x"
        //  );
    }

    function calculateFlowRate(uint256 _streamAmountOwner, uint256 _endTime)
        private
        view
        returns (uint256)
    {
        uint256 _totalSeconds = calculateTotalSeconds(_endTime);
        uint256 _flowRate = _streamAmountOwner.div(_totalSeconds);
        return _flowRate;
    }

    function calculateTotalSeconds(uint256 _endTime)
        private
        view
        returns (uint256)
    {
        uint256 totalSeconds = _endTime.sub(block.timestamp);
        return totalSeconds;
    }

    //CT functions, loop through length of milestones//
    function callSplitPosition(
        address tokenaddress,
        bytes32 parent,
        bytes32 conditionId,
        uint256[] calldata partition,
        uint256 value, //bytes32 approvalPositionId,
        uint256 rejectValue //bytes32 rejectionPositionId
    ) external {
        ICT.splitPosition(tokenaddress, parent, conditionId, partition, value);
        //store value and rejectValue for use in transferCT function? if memory allows
    }

    //transfer CT tokens to bidder wallet for a certain positionId.
    function transferCT(uint256 positionId) external payable {
        require(
            msg.sender == winningBidder || msg.sender == owner,
            "only winning bidder or owner can redeem conditional tokens"
        );
        uint256 heldAmount = IERC1155C.balanceOf(address(this), positionId); 

        //need to prevent bidder from taking both owner and bidder outcomes
        IERC1155C.safeTransferFrom(
            address(this),
            msg.sender,
            positionId,
            heldAmount,
            ""
        );
    }

    //reportPayouts() should call fetchOracle(). Or maybe oracle should handle these functions.
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
        return (
            bountySpeedTargetOwner,
            targetBountyOwner,
            speedTargetOwner,
            streamAmountOwner
        );
    }

    //loads all bidders addresses in an array
    function getAllBidderAddresses() external view returns (address[] memory) {
        return (all_bidders);
    }

    //loads bidder terms for owner to see
    function loadBidderTerms(address _bidder)
        external
        view
        returns (
            uint256[] memory _bountySpeedtargets,
            uint256[] memory _bounties,
            uint256 _streamSpeedTarget,
            uint256 _streamAmountTotal
        )
    {
        require(
            msg.sender == owner || ownerApproval==true, 
            "Only project owner can see proposed terms if not approved yet"
        );
        return (
            BidderToTargets[_bidder],
            BidderToBounties[_bidder],
            BidderToStreamSpeed[_bidder],
            BidderToStreamAmount[_bidder]
        );
    }
}
