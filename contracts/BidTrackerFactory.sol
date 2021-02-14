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
        uint256[] targeBounties,
        uint256 wifiSpeedTarget,
        int96 streamRate,
        uint256 createdAt
    );

    /**
    	@notice Deploys a new project AKA an instance of the BidTracker.sol contract with the following parameters:
       	@param _owner the ethereum address of the owner of a particular project
       	@param _ConditionalTokens the ethereum address of the ConditionalTokens contract
       	@param _Superfluid the ethereum address of the Superfluid contract which allows the starting and stopping of money streams
       	@param _ERC20 the ethereum address for the ERC20 interface contract to be used as collateral for the conditional tokens
       	@param _name The name of the project
       	@param _bountySpeedTargets an array of the speed targets that have bounties
       	@param _bounties an array with the bounties set for the _bountySpeedTargets array
       	@param _streamSpeedTarget the target speed for the Internet Service Provider
       	@param _streamAmountTotal the total amount of money to be streamed for the internet service
    **/

    function deployNewProject(
        address _owner,
        address _ConditionalTokens,
        address _Superfluid,
        address _CFA,
        address _ERC20,
        string memory _name,
        uint256[] memory _bountySpeedTargets,
        uint256[] memory _bounties,
        uint256 _wifiSpeedTarget,
        int96 _streamRate
    ) public returns (address) {
        //need to check if name or symbol already exists
        require(nameToProjectIndex[_name] == 0, "Name has already been taken");
        BidTracker newProject =
            new BidTracker(
                _owner,
                _ConditionalTokens,
                _Superfluid,
                _CFA,
                _ERC20,
                _name,
                _bountySpeedTargets,
                _bounties,
                _wifiSpeedTarget,
                _streamRate
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
            _wifiSpeedTarget,
            _streamRate,
            block.timestamp
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
