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
    bool public noncompliant = false;
    string public projectName;
    address public owner;
    address public oracleAddress;
    address public winningBidder;
    address[] public all_bidders; //should be able to replace this with event and theGraph

    //bid options initialized by owner
    uint256[] public bountySpeedTargetOwner;
    uint256[] public targetBountyOwner;
    uint256 public wifiSpeedOwner;
    uint256 public securityDeposit = 1000000000000000; //can be changed in the future
    int96 public streamRateOwner;

    //bids need to be private
    mapping(address => uint256[]) private BidderToTargets;
    mapping(address => uint256[]) private BidderToBounties;
    mapping(address => uint256) private BidderToWifiSpeed; //speed of wifi
    mapping(address => int96) private BidderToStreamRate; //rate of payment

    //interfaces - is it better to store variable or create a new instance in each function call?
    IERC1155 private IERC1155C;
    IERC20 private IERC20C;
    IConditionalTokens private ICT;
    IConstantFlowAgreementV1 private ICFA;
    ISuperfluid private ISF;

    event currentTermsApproved(
        address approvedBidder,
        uint256 finalWifiSpeed,
        int96 finalStreamRate,
        uint256[] finalTargetSpeeds,
        uint256[] finalBounties,
        uint256 createdAt
    );
    event newBidSent(
        address Bidder,
        int96 streamRateBidder,
        uint256 wifiSpeedBidder,
        uint256[] bountySpeedTargets,
        uint256[] bounties,
        uint256 createdAt
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
        uint256 _wifiSpeedTarget,
        int96 _streamRate
    ) public {
        owner = _owner;
        projectName = _name;
        bountySpeedTargetOwner = _bountySpeedTargets;
        targetBountyOwner = _bounties;
        wifiSpeedOwner = _wifiSpeedTarget;
        streamRateOwner = _streamRate;
        ICFA = IConstantFlowAgreementV1(_CFA);
        ISF = ISuperfluid(_Superfluid);
        IERC1155C = IERC1155(_ConditionalToken);
        IERC20C = IERC20(_ERC20);
        ICT = IConditionalTokens(_ConditionalToken);
    }

    ////utils
    function cast(uint256 number) public pure returns (int96) {
        return int96(number);
    }

    function recieveERC20(uint256 _value) external {
        //must have approval first from owner address to this contract address
        IERC20C.transferFrom(owner, address(this), _value);
    }

    ///bidding and approvals
    function newBidderTerms(
        uint256[] calldata _bountySpeedTargets,
        uint256[] calldata _bounties,
        uint256 _wifiSpeedTarget,
        int96 _streamRate
    ) external {
        require(
            ownerApproval == false,
            "another proposal has already been accepted"
        );
        // require(msg.sender != owner, "owner cannot create a bid");
        BidderToTargets[msg.sender] = _bountySpeedTargets;
        BidderToBounties[msg.sender] = _bounties;
        BidderToWifiSpeed[msg.sender] = _wifiSpeedTarget;
        BidderToStreamRate[msg.sender] = _streamRate;
        all_bidders.push(msg.sender);

        emit newBidSent(
            msg.sender,
            _streamRate,
            _wifiSpeedTarget,
            _bountySpeedTargets,
            _bounties,
            block.timestamp
        );
    }

    function approveBidderTerms(address _bidder, address token) external {
        require(msg.sender == owner, "Only project owner can approve terms");
        require(ownerApproval == false, "A bid has already been approved");
        ownerApproval = true;
        winningBidder = _bidder;

        setDeposit();
        startFlow(token, _bidder, streamRateOwner);
        emit currentTermsApproved(
            _bidder,
            BidderToWifiSpeed[_bidder],
            BidderToStreamRate[_bidder],
            BidderToTargets[_bidder],
            BidderToBounties[_bidder],
            block.timestamp
        );
    }

    function endFlow(address token, address receiver) public {
        require(msg.sender == owner, "Only owner can cancel flow");
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

    //security deposit
    function setDeposit() internal {
        //must have approval first from owner address to this contract address
        IERC20C.transferFrom(owner, address(this), securityDeposit);
    }

    function resolveDeposit() internal {
        if (noncompliant == true) {
            //funds transfer to bidder
            IERC20C.approve(winningBidder, securityDeposit);
            IERC20C.transferFrom(address(this), winningBidder, securityDeposit);
        } else {
            //funds transfer back to owner
            IERC20C.approve(owner, securityDeposit);
            IERC20C.transferFrom(address(this), owner, securityDeposit);
        }
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
        noncompliant = false; //replace with fetchOracleData() later
    }

    function fetchOracleData(uint256 jobID) internal {
        //still need to do this. Returns weekly average speed.
    }

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

    //////External view functions. May be unneccesary due to theGraph.
    //loads owner terms for bidder to see.
    function loadOwnerTerms()
        external
        view
        returns (
            uint256[] memory _bountySpeedTargets,
            uint256[] memory _bounties,
            uint256 _wifiSpeedTarget,
            int96 _streamAmountTotal
        )
    {
        return (
            bountySpeedTargetOwner,
            targetBountyOwner,
            wifiSpeedOwner,
            streamRateOwner
        );
    }

    //loads bidder terms for owner to see
    function loadBidderTerms(address _bidder)
        external
        view
        returns (
            uint256[] memory _bountySpeedtargets,
            uint256[] memory _bounties,
            uint256 _wifiSpeedTarget,
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
            BidderToWifiSpeed[_bidder],
            BidderToStreamRate[_bidder]
        );
    }
}
