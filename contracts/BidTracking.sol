// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.7.0;
import "@openzeppelin/contracts/utils/Counters.sol";

//start milestones here? monthly reset? How often to set new conditions
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

//start stream from here? 
//do conditional tokens make sense here - get some ammount of ERC20 that represents the health of the service?
interface ISuperFluid {}

contract BidTrackerFactory {
    using Counters for Counters.Counter;
    Counters.Counter public nonce; // acts as unique identifier for minted NFTs

    mapping(string => uint256) public nameToProjectIndex;
    BidTracker[] public projects;
    // event NewProject(
    //     string name,
    //     address owner,
    //     address project,
    //     uint256[] timelinesOwner,
    //     uint256[] budgetsOwner,
    //     string milestones
    // );

    function deployNewProject(
        address _owner,
        address _ConditionalTokens,
        string memory _name,
        string memory _symbol,
        string memory _milestones,
        uint256[] memory _timeline,
        uint256[] memory _budgets
    ) public returns (address) {
        //need to check if name or symbol already exists
        require(nameToProjectIndex[_name] == 0, "Name has already been taken");
        BidTracker newProject = new BidTracker(
            _owner,
            _ConditionalTokens,
            _name,
            _symbol,
            _milestones,
            _timeline,
            _budgets
        );
        projects.push(newProject);

        nonce.increment(); //start at 1
        nameToProjectIndex[_name] = nonce.current();

        //emit event
        // emit NewProject(
        //     _name,
        //     _owner,
        //     address(newProject),
        //     _timeline,
        //     _budgets,
        //     _milestones
        // );
        //should create safe in here too, and add an address variable for the safe.
        return address(newProject);
    }

    function getProject(string memory _name)
        public
        view
        returns (address projectAddress, string memory name)
    {

            BidTracker selectedProject
         = projects[nameToProjectIndex[_name] - 1];

        return (address(selectedProject), selectedProject.projectName());
    }
}

contract BidTracker {
    bool public ownerApproval = false;
    string public projectName;
    string public symbol;
    string public milestones;
    address public owner;
    address public winningBidder;
    address[] public all_bidders;
    uint256[] public timelinesOwner;
    uint256[] public budgetsOwner;

    IConditionalTokens private ICT;

    event currentTermsApproved(address approvedBidder);
    event newBidSent(address Bidder, uint256[] timelines, uint256[] budgets);

    mapping(address => uint256[]) public BidderToTimeline;
    mapping(address => uint256[]) public BidderToBudgets;
    mapping(address => bool) public BidderProposalStatus;

    constructor(
        address _owner,
        address _ConditionalToken,
        string memory _name,
        string memory _symbol,
        string memory _milestones,
        uint256[] memory _timelines,
        uint256[] memory _budgets
    ) public {
        owner = _owner;
        projectName = _name;
        symbol = _symbol;
        milestones = _milestones;
        timelinesOwner = _timelines;
        budgetsOwner = _budgets;
        ICT = IConditionalTokens(_ConditionalToken);
    }

    //called by bidder submit
    function newBidderTerms(
        uint256[] calldata _timelines,
        uint256[] calldata _budgets
    ) external {
        require(
            ownerApproval == false,
            "another proposal has already been accepted"
        );
        require(msg.sender != owner, "owner cannot create a bid");
        
        BidderToTimeline[msg.sender] = _timelines;
        BidderToBudgets[msg.sender] = _budgets;
        BidderProposalStatus[msg.sender] = false;
        all_bidders.push(msg.sender);
        emit newBidSent(msg.sender, _timelines, _budgets);
    }

    //called by owner approval submit
    function approveBidderTerms(
        address _bidder,
        address _CTaddress,
        address _ERC20address,
        address auditor
    ) external {
        require(msg.sender == owner, "Only project owner can approve terms");
        ownerApproval = true;
        BidderProposalStatus[_bidder] = true;
        winningBidder = _bidder;

        //adjust owner terms to be same as bidder terms
        budgetsOwner = BidderToBudgets[msg.sender];
        timelinesOwner = BidderToTimeline[msg.sender];

        //start superfluid and CT? 

        emit currentTermsApproved(_bidder);
    }

    ////This section is for post bid approval management

    //adjust bid terms
    //report to CT function

    ////Below are all external view functions

    //loads owner terms for bidder to see
    function loadOwnerTerms()
        external
        view
        returns (
            string memory _milestones,
            uint256[] memory _timelines,
            uint256[] memory _budgets
        )
    {
        return (milestones, budgetsOwner, timelinesOwner);
    }

    //loads all bidders
    function getAllBidderAddresses() external view returns (address[] memory) {
        return (all_bidders);
    }

    //loads bidder terms for owner to see
    function loadBidderTerms(address _bidder)
        external
        view
        returns (uint256[] memory _timelines, uint256[] memory _budgets)
    {
        require(
            msg.sender == owner,
            "Only project owner can see proposed terms"
        );
        return (BidderToTimeline[_bidder], BidderToBudgets[_bidder]);
    }
}
