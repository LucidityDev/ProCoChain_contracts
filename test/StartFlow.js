const { expect } = require("chai");
const { abi:abiStartFlow } = require("../artifacts/contracts/StartFlow.sol/StartFlow.json")
const { abi: abiSF } = require("../superfluidartifacts/Superfluid.json");
const { abi: abiSFCF } = require("../superfluidartifacts/ConstantFlowAgreementV1.json");
const { abi: abiSFT } = require("../superfluidartifacts/ERC20WithTokenInfo.json");


const fs = require("fs"); 
const { ethers } = require("hardhat");

function mnemonic() {
  return fs.readFileSync("./test/mnemonic.txt").toString().trim();
}

describe("Start Stream Flow Test", function () {
	let StartFlowFactory, fDai;
	
});