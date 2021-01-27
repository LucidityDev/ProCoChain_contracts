pragma solidity >=0.6.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import {
    IConstantFlowAgreementV1
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {
    ISuperToken
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

contract CFTest {
    using SafeMath for uint256;

    uint256 public streamAmountOwner;
    address public owner;
    IERC20 private IERC20C;
    IConstantFlowAgreementV1 private ICFA;

    constructor(
        address _Superfluid,
        address _ERC20,
        uint256 _streamAmountTotal
    ) public {
        owner = msg.sender;
        streamAmountOwner = _streamAmountTotal;
        ICFA = IConstantFlowAgreementV1(_Superfluid);
        IERC20C = IERC20(_ERC20);
    }

    function recieveERC20(uint256 _value) external {
        //must have approval first from owner address to this contract address
        IERC20C.transferFrom(owner, address(this), _value);
    }

     function startFlow(
        ISuperToken token,
        address receiver,
        uint256 _streamAmountOwner,
        uint256 _endTime
    ) external {
        uint256 flowRate = calculateFlowRate(_streamAmountOwner, _endTime);
        ICFA.createFlow(token, receiver, cast(flowRate), "0x");
    }

    function cast(uint256 number) public pure returns (int96) {
        return int96(number);
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
}