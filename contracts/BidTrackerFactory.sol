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
    	@notice Deploys a new project AKA an instance of the BidTracker.sol contract with caller as the project owner
       	@param _owner the ethereum address of the owner of a particular project
       	@param _ConditionalTokens the ethereum address of the ConditionalTokens contract
       	@param _Superfluid the ethereum address of the Superfluid Host contract
        @param _CFA the Constant Flow Agreement that starts the constant _streamRate payment to the winning bidder
       	@param _ERC20 the ethereum address for the ERC20 token to be used for payment
       	@param _name The name of the project
       	@param _bountySpeedTargets an array of the mbs speed targets to be set in Gnosis Conditional Tokens
       	@param _bounties an array with the bounties set for the _bountySpeedTargets array
       	@param _wifiSpeedTarget The target mbs speed for the Internet Service Provider
       	@param _streamRate The per second stream rate to be sent to the winning bidder 
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

    /**
    @notice Get the address of the project by name
    @return projectAddress address of the deployed project
    @param _name Case sensitive name of project
     */
    function getProject(string memory _name)
        public
        view
        returns (address projectAddress, string memory name)
    {
        BidTracker selectedProject = projects[nameToProjectIndex[_name] - 1];
        return (address(selectedProject), selectedProject.projectName());
    }
}
