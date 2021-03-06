pragma solidity >=0.6.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import {
    IConstantFlowAgreementV1
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {
    ISuperToken,
    ISuperfluid
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import "./Int96SafeMath.sol";

contract CFTest {
    using Int96SafeMath for int96;

    uint256 public streamAmountOwner;
    address public owner;
    IERC20 private IERC20C;
    ISuperfluid private SF;
    IConstantFlowAgreementV1 private ICFA;

    constructor(
        address _Superfluid,
        address _ICFA,
        address _ERC20,
        uint256 _streamAmountTotal
    ) public {
        owner = msg.sender;
        streamAmountOwner = _streamAmountTotal;
        SF = ISuperfluid(_Superfluid);
        ICFA = IConstantFlowAgreementV1(_ICFA);
        IERC20C = IERC20(_ERC20);
    }

    function recieveERC20(uint256 _value) external {
        //must have approval first from owner address to this contract address
        IERC20C.transferFrom(owner, address(this), _value);
    }

    function startFromHost(
        address _ERC20,
        address _receiever,
        int96 _streamAmountOwner,
        int96 _endTime
    ) external {
        int96 flowRate = calculateFlowRate(_streamAmountOwner, _endTime);
        SF.callAgreement(
            ICFA,
            abi.encodeWithSelector(
                ICFA.createFlow.selector,
                _ERC20,
                _receiever,
                flowRate,
                new bytes(0) // placeholder
            ),
            "0x"
        );
    }

    // function startFromHostBasic(
    //     address _ERC20,
    //     address _receiever,
    //     int96 _flowRate
    // ) external {
    //     SF.callAgreement(
    //         ICFA,
    //         abi.encodeWithSelector(
    //             ICFA.createFlow.selector,
    //             _ERC20,
    //             _receiever,
    //             "38580246913580", //HARDCODE THIS AND SEE IF IT WORKS. ,
    //             new bytes(0) // placeholder
    //         ),
    //         "0x"
    //     );
    // }

    // function startFlow(
    //     ISuperToken token,
    //     address receiver,
    //     uint256 _streamAmountOwner,
    //     uint256 _endTime
    // ) external {
    //     uint256 flowRate = calculateFlowRate(_streamAmountOwner, _endTime);
    //     ICFA.createFlow(token, receiver, cast(flowRate), "0x");
    // }

    function calculateFlowRate(int96 _streamAmountOwner, int96 _endTime)
        private
        view
        returns (int96)
    {
        int96 _totalSeconds = calculateTotalSeconds(_endTime);
        int96 _flowRate = _streamAmountOwner.div(_totalSeconds);
        return _flowRate;
    }

    function calculateTotalSeconds(int96 _endTime)
        private
        view
        returns (int96)
    {
        int96 totalSeconds = _endTime.sub(cast(block.timestamp), "overflow");
        return totalSeconds;
    }

    function cast(uint256 number) public pure returns (int96) {
        return int96(number);
    }
}
