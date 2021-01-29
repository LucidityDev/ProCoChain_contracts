// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import {
    IConstantFlowAgreementV1
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {
    ISuperfluid
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import "./Int96SafeMath.sol";

interface IConditionalTokens {
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

contract BidTracker {
    using Int96SafeMath for int96;
    using SafeMath for uint256;

    //tracking variables
    bool public ownerApproval = false;
    string public projectName;
    address public owner;
    address public oracleAddress;
    address public winningBidder;
    address[] public all_bidders; //should be able to replace this with event and theGraph

    //bid options initialized by owner
    uint256[] public bountySpeedTargetOwner;
    uint256[] public targetBountyOwner;
    uint256 public speedTargetOwner;
    uint256 public securityDeposit = 1000;
    int96 public streamRateOwner;
    int96 private BidderEndtime;

    //bids need to be private
    mapping(address => uint256[]) private BidderToTargets;
    mapping(address => uint256[]) private BidderToBounties;
    mapping(address => uint256) private BidderToStreamSpeed; //speed of wifi
    mapping(address => int96) private BidderToStreamRate; //rate of payment

    //interfaces - is it better to store variable or create a new instance in each function call?
    IERC1155 private IERC1155C;
    IERC20 private IERC20C;
    IConditionalTokens private ICT;
    IConstantFlowAgreementV1 private ICFA;
    ISuperfluid private ISF;

    event currentTermsApproved(address approvedBidder);
    event newBidSent(
        address Bidder,
        uint256 speedTargetBidder,
        uint256[] bountySpeedTargets,
        uint256[] bounties
    );

    constructor(
        address _owner,
        address _ConditionalToken,
        address _Superfluid,
        address _CFA,
        address _ERC20,
        string memory _name,
        uint256[] memory _bountySpeedTargets,
        uint256[] memory _bounties,
        uint256 _streamSpeedTarget,
        int96 _streamRate
    ) public {
        owner = _owner;
        projectName = _name;
        bountySpeedTargetOwner = _bountySpeedTargets;
        targetBountyOwner = _bounties;
        speedTargetOwner = _streamSpeedTarget;
        streamRateOwner = _streamRate;
        ICFA = IConstantFlowAgreementV1(_CFA);
        ISF = ISuperfluid(_Superfluid);
        IERC1155C = IERC1155(_ConditionalToken);
        IERC20C = IERC20(_ERC20);
        ICT = IConditionalTokens(_ConditionalToken);
    }

    //called by bidder submit
    function newBidderTerms(
        uint256[] calldata _bountySpeedTargets,
        uint256[] calldata _bounties,
        uint256 _streamSpeedTarget,
        int96 _streamRate
    ) external {
        require(
            ownerApproval == false,
            "another proposal has already been accepted"
        );
        // require(msg.sender != owner, "owner cannot create a bid");
        BidderToTargets[msg.sender] = _bountySpeedTargets;
        BidderToBounties[msg.sender] = _bounties;
        BidderToStreamSpeed[msg.sender] = _streamSpeedTarget;
        BidderToStreamRate[msg.sender] = _streamRate;
        all_bidders.push(msg.sender);

        emit newBidSent(
            msg.sender,
            _streamSpeedTarget,
            _bountySpeedTargets,
            _bounties
        );
    }

    //called by owner approval submit
    function approveBidderTerms(address _bidder, address token)
        external
    // int96 endTime
    {
        require(msg.sender == owner, "Only project owner can approve terms");
        require(ownerApproval == false, "A bid has already been approved");
        ownerApproval = true;
        winningBidder = _bidder;

        //adjust owner terms to be same as bidder terms
        targetBountyOwner = BidderToBounties[_bidder];
        bountySpeedTargetOwner = BidderToTargets[_bidder];
        speedTargetOwner = BidderToStreamSpeed[_bidder];
        streamRateOwner = BidderToStreamRate[_bidder];

        // BidderEndtime = endTime;

        //setDeposit();
        startFlow(token, _bidder, streamRateOwner);

        //emit newStream()
        //emit CTidandoutcomes() maybe some function that rounds down on report. Need chainlink to resolve this in the future.
        emit currentTermsApproved(_bidder);
    }

    function setDeposit() internal {
        //must have approval first from owner address to this contract address
        IERC20C.approve(owner, securityDeposit);
        IERC20C.transferFrom(owner, address(this), securityDeposit);
    }

    function recieveERC20(uint256 _value) external {
        //must have approval first from owner address to this contract address
        IERC20C.transferFrom(owner, address(this), _value);
    }

    function resolveDeposit() internal {
        if (cast(block.timestamp) >= BidderEndtime) {
            //funds transfer to bidder
            IERC20C.approve(winningBidder, securityDeposit);
            IERC20C.transferFrom(address(this), winningBidder, securityDeposit);
        } else {
            //funds transfer back to owner
            IERC20C.approve(owner, securityDeposit);
            IERC20C.transferFrom(address(this), owner, securityDeposit);
        }
    }

    function endFlow(address token, address receiver) public {
        ISF.callAgreement(
            ICFA,
            abi.encodeWithSelector(
                ICFA.deleteFlow.selector,
                token,
                msg.sender,
                receiver,
                new bytes(0) // placeholder
            ),
            "0x"
        );
        resolveDeposit();
    }

    function startFlow(
        address _ERC20,
        address _receiever,
        int96 _streamRate // int96 _endTime
    ) private {
        // int96 flowRate = calculateFlowRate(_streamAmountOwner, _endTime);
        ISF.callAgreement(
            ICFA,
            abi.encodeWithSelector(
                ICFA.createFlow.selector,
                _ERC20,
                _receiever,
                _streamRate,
                new bytes(0) // placeholder
            ),
            "0x"
        );
    }

    function cast(uint256 number) public pure returns (int96) {
        return int96(number);
    }

    // function calculateFlowRate(int96 _streamAmountOwner, int96 _endTime)
    //     private
    //     view
    //     returns (int96)
    // {
    //     int96 _totalSeconds = calculateTotalSeconds(_endTime);
    //     int96 _flowRate = _streamAmountOwner.div(_totalSeconds);
    //     return _flowRate;
    // }

    // function calculateTotalSeconds(int96 _endTime)
    //     private
    //     view
    //     returns (int96)
    // {
    //     int96 totalSeconds = _endTime.sub(cast(block.timestamp), "time error");
    //     return totalSeconds;
    // }

    //CT functions, loop through length of milestones//
    function callSplitPosition(
        address tokenaddress,
        bytes32 parent,
        bytes32 conditionId,
        uint256[] calldata partition,
        uint256 value //bytes32 approvalPositionId,
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

    //////Below are all external view functions

    //loads owner terms for bidder to see
    function loadOwnerTerms()
        external
        view
        returns (
            uint256[] memory _bountySpeedTargets,
            uint256[] memory _bounties,
            uint256 _streamSpeedTarget,
            int96 _streamAmountTotal
        )
    {
        return (
            bountySpeedTargetOwner,
            targetBountyOwner,
            speedTargetOwner,
            streamRateOwner
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
            int96 _streamAmountTotal
        )
    {
        require(
            msg.sender == owner || ownerApproval == true,
            "Only project owner can see proposed terms if not approved yet"
        );
        return (
            BidderToTargets[_bidder],
            BidderToBounties[_bidder],
            BidderToStreamSpeed[_bidder],
            BidderToStreamRate[_bidder]
        );
    }
}
