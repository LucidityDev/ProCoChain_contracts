pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SchoolAPI is ChainlinkClient, Ownable {
  
    uint256 public randInt = 0;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    constructor() public {
        setPublicChainlinkToken();
        oracle = 0x5148b5cE8C2222c9DcC726d3e12F493c76Fbf942; //Andrew's Oracle on Rinkeby, NOT THE NODE ADDRESS
        jobId = "7893d0d99c7c450e898ac81042190abc"; //Eth Get Int
        fee = 1 * 10 ** 18; // should be 0.1 LINK but adjusted to 1 LINK due to possible config error
    }
    
    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function requestRandomUint() public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // Set the URL to perform the GET request on
        request.add("Httpget", "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=ETH&tsyms=USD");
        
        // Set the path to find the desired data in the API response, where the response format is:
        // {"RAW":
        //   {"ETH":
        //    {"USD":
        //     {
        //      "VOLUME24HOUR": xxx.xxx,
        //     }
        //    }
        //   }
        //  }
        request.add("Jsonparse", "RAW.ETH.USD.VOLUME24HOUR");
        
        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**18;
        request.addInt("Multiply", timesAmount);
        
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    /**
     * Receive the response in the form of uint256
     */ 
    function fulfill(bytes32 _requestId, uint256 _randInt) public recordChainlinkFulfillment(_requestId)
    {
        randInt = _randInt;
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    function cancelRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
    )
        public
        onlyOwner
    {
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
    }
}