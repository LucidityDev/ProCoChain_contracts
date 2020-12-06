// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.7.0;
import "@openzeppelin/contracts/utils/Counters.sol";

interface IConditionalTokens {
    //how do we flexibly set outcomes? 
    
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
interface ISablier {}

contract BidTrackerFactory {
    using Counters for Counters.Counter;
    Counters.Counter public nonce; // acts as unique identifier for minted NFTs

    mapping(string => uint256) public nameToProjectIndex;
    BidTracker[] public projects;
    // event NewProject( //remember you already set up theGraph for this
    //     string name,
    //     address owner,
    //     address project,
    //     uint256[] speedtargets,
    //     uint256[] targetbounties
    // );

    function deployNewProject(
        address _owner,
        address _ConditionalTokens,
        string memory _name,
        uint256[] memory _speedtargets,
        uint256[] memory _bounties
    ) public returns (address) {
        //need to check if name or symbol already exists
        require(nameToProjectIndex[_name] == 0, "Name has already been taken");
        BidTracker newProject = new BidTracker(
            _owner,
            _ConditionalTokens,
            _name,
            _speedtargets,
            _bounties
        );
        projects.push(newProject);

        nonce.increment(); //start at 1
        nameToProjectIndex[_name] = nonce.current();

        // //emit event
        // emit NewProject(
        //     _name,
        //     _owner,
        //     address(newProject),
        //     _speedtargets,
        //     _bounties,
        // );
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
    uint16 public basePrice; 
    string public projectName;
    address public owner;
    address public winningBidder;
    address[] public all_bidders;
    uint256[] public speedtargetOwner;
    uint256[] public targetbountyOwner;

    //bandwidth target
    //days serviced target
    //do we want a timeline for these? 
    //number of people serviced?

    IConditionalTokens private ICT;

    event currentTermsApproved(address approvedBidder);
    event newBidSent(address Bidder, uint256[] timelines, uint256[] budgets);

    mapping(address => uint256[]) private BidderToTargets;
    mapping(address => uint256[]) private BidderToBounties;

    constructor(
        address _owner,
        address _ConditionalToken,
        string memory _name,
        uint256[] memory _speedtargets,
        uint256[] memory _bounties
    ) public {
        owner = _owner;
        projectName = _name;
        speedtargetOwner = _speedtargets;
        targetbountyOwner = _bounties;
        ICT = IConditionalTokens(_ConditionalToken);
    }

    //called by bidder submit
    function newBidderTerms(
        uint256[] calldata _speedtargets,
        uint256[] calldata _bounties
    ) external {
        require(
            ownerApproval == false,
            "another proposal has already been accepted"
        );
        require(msg.sender != owner, "owner cannot create a bid");
        
        BidderToTargets[msg.sender] = _speedtargets;
        BidderToBounties[msg.sender] = _bounties;
        all_bidders.push(msg.sender);
        emit newBidSent(msg.sender, _speedtargets, _bounties);
    }

    //called by owner approval submit
    function approveBidderTerms(
        address _bidder
        // address _CTaddress,
        // address _ERC20address,
        // address auditor
    ) external {
        require(msg.sender == owner, "Only project owner can approve terms");
        require(ownerApproval == false, "A bid has already been approved");
        ownerApproval = true;
        winningBidder = _bidder;

        //adjust owner terms to be same as bidder terms
        targetbountyOwner = BidderToBounties[msg.sender];
        speedtargetOwner = BidderToTargets[msg.sender];

        //maybe kick off a healthERC720 non-transferrable, that has a constructor with health values. 
        //problem is that then the ERC20 is what goes into CT, health factor * base price? something like that, with limited group allowances
        
        emit currentTermsApproved(_bidder);
    }

    //////This section is for post bid approval management

    //bidder can propose new bid terms
    function adjustBidTerms(uint256[] memory _speedtargets, uint256[] memory _bounties) public {
        require(ownerApproval == true, "a bid has not been approved yet");
        require(msg.sender == winningBidder, "only approved bidder can submit new terms");
        BidderToBounties[msg.sender] = _bounties;
        BidderToTargets[msg.sender] = _speedtargets;
    }

    //owner needs to approve new terms
    function approveNewTerms() public {
        require(ownerApproval == true, "a bid has not been approved yet");
        require(msg.sender == owner, "only owner can approve new terms");
        targetbountyOwner = BidderToBounties[msg.sender];
        speedtargetOwner = BidderToTargets[msg.sender];
        //this has to somehow update health token too? but then you can't adjust CT?
        //this shouldn't affect superfluid 
    }

    //set CT functions?
    function setCT() public {

    }

    function reportOracle() public {
        //review oracle calls from cryptozombies
    }

    //////Below are all external view functions

    //loads owner terms for bidder to see
    function loadOwnerTerms()
        external
        view
        returns (
            uint256[] memory _speedtargets,
            uint256[] memory _bounties
        )
    {
        return (speedtargetOwner, targetbountyOwner);
    }

    //loads all bidders addresses in an array
    function getAllBidderAddresses() external view returns (address[] memory) {
        return (all_bidders);
    }

    //loads bidder terms for owner to see
    function loadBidderTerms(address _bidder)
        external
        view
        returns (uint256[] memory _speedtargets, uint256[] memory _bounties)
    {
        require(
            msg.sender == owner,
            "Only project owner can see proposed terms"
        );
        return (BidderToTargets[_bidder], BidderToBounties[_bidder]);
    }
}
