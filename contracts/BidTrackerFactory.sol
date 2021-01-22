pragma solidity >=0.6.0;
import "./BidTracker.sol";

contract BidTrackerFactory {
    using Counters for Counters.Counter;
    Counters.Counter public nonce; // acts as unique identifier for minted NFTs

    mapping(string => uint256) public nameToProjectIndex;
    BidTracker[] public projects;
    event NewProject(
        //remember you already set up theGraph for this
        string name,
        address owner,
        address project,
        uint256[] bountySpeedTargets,
        uint256[] targetbounties,
        uint256 streamSpeedTarget,
        uint256 streamAmountTotal
    );

    function deployNewProject(
        address _owner,
        address _ConditionalTokens,
        address _Superfluid,
        address _ERC20,
        string memory _name,
        uint256[] memory _bountySpeedTargets,
        uint256[] memory _bounties,
        uint256 _streamSpeedTarget,
        uint256 _streamAmountTotal
    ) public returns (address) {
        //need to check if name or symbol already exists
        require(nameToProjectIndex[_name] == 0, "Name has already been taken");
        BidTracker newProject =
            new BidTracker(
                _owner,
                _ConditionalTokens,
                _Superfluid,
                _ERC20,
                _name,
                _bountySpeedTargets,
                _bounties,
                _streamSpeedTarget,
                _streamAmountTotal
            );
        projects.push(newProject);

        nonce.increment(); //start at 1. Could replace this with theGraph instead
        nameToProjectIndex[_name] = nonce.current();

        //emit event
        emit NewProject(
            _name,
            _owner,
            address(newProject),
            _bountySpeedTargets,
            _bounties,
            _streamSpeedTarget,
            _streamAmountTotal
        );
        return address(newProject);
    }

    function getProject(string memory _name)
        public
        view
        returns (address projectAddress, string memory name)
    {
        BidTracker selectedProject = projects[nameToProjectIndex[_name] - 1];
        return (address(selectedProject), selectedProject.projectName());
    }
}
