pragma solidity >=0.6.0;

contract OracleSchools {
    mapping (bytes32 => uint8) public schoolSpeed;

    function updateSpeed() public payable {
        // if (oraclize_getPrice("URL") > this.balance) {
        //     //Handle out of funds error
        // } else {
        //     oraclize_query("URL", "json(http://api.fixer.io/latest?symbols=USD).rates.USD");
        // }
    }
    
    function __callback(bytes32 schoolId, uint8 result) public {
        // require(msg.sender == oraclize_cbAddress());

        schoolSpeed[schoolId] = result;
    }
}