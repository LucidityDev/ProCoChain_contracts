pragma solidity >=0.6.0;
import "./BidTracker.sol";

contract BidTrackerFactory {
    using Counters for Counters.Counter;
    Counters.Counter public nonce; // acts as unique identifier for minted NFTs

    mapping(string => uint256) public nameToProjectIndex;
    BidTracker[] public projects;
    event NewProject( //remember you already set up theGraph for this
        string name,
        address owner,
        address project,
        uint256[] speedtargets,
        uint256[] targetbounties
    );

    function deployNewProject(
        address _owner,
        address _ConditionalTokens,
        address _Sablier,
        string memory _name,
        uint256[] memory _speedtargets,
        uint256[] memory _bounties
    ) public returns (address) {
        //need to check if name or symbol already exists
        require(nameToProjectIndex[_name] == 0, "Name has already been taken");
        BidTracker newProject = new BidTracker(
            _owner,
            _ConditionalTokens,
            _Sablier,
            _name,
            _speedtargets,
            _bounties
        );
        projects.push(newProject);

        nonce.increment(); //start at 1
        nameToProjectIndex[_name] = nonce.current();

        //emit event
        emit NewProject(
            _name,
            _owner,
            address(newProject),
            _speedtargets,
            _bounties
        );
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