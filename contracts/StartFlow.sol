pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import {
	    IConstantFlowAgreementV1
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {
	    ISuperToken
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

contract StartFlow {

    using SafeMath for uint256;

    IConstantFlowAgreementV1 private ICFA;

    constructor(
	    address _Superfluid
    ) public {
    	ICFA = IConstantFlowAgreementV1(_Superfluid);
    }

    function startFlow(
        ISuperToken token,
        address receiver,
        uint256 _streamAmountOwner,
        uint256 _endTime
    ) private {
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
