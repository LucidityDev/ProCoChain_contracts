const { expect } = require("chai");
const { abi: abiSchool } = require("../artifacts/contracts/OracleSchools.sol/SchoolAPI.json");
const fs = require("fs"); 

const { ethers } = require("hardhat");

function mnemonic() {
      return fs.readFileSync("./mnemonic.txt").toString().trim();
  }

describe("Oracle Testing Chainlink", function () {
    let Oracle;
    let owner, bidder, auditor;
  
    it("connect owner", async () => {
        provider = new ethers.providers.InfuraProvider("rinkeby", {
            projectId: "d635ea6eddda4720824cc8b24380e4a9",
            projectSecret: "b4ea2b15f0614105a64f0e8ba1f2bffa"
          });

        owner = ethers.Wallet.fromMnemonic(mnemonic());
        owner = await owner.connect(provider);
    });

    xit("deploy oracle contract", async function () {
        const OracleContract = await ethers.getContractFactory("SchoolAPI");
        Oracle = await OracleContract.deploy();
        console.log(Oracle)
    });

    it("test oracle get", async function () {
        //create Oracle from address and abi
        Oracle = new ethers.Contract(
            "0xAc94a69BecBdECaB8E24C786041782e39111686a",
              abiSchool,
              owner
            );

        //check uint 
        const preUint = await Oracle.randInt()
        console.log("pre request uint: ", preUint.toString())
        //call request
        const makeRequest = await Oracle.requestRandomUint()
        //call uint
        const returnedUint = await Oracle.randInt()
        console.log("post request uint: ", returnedUint.toString())
    })
});