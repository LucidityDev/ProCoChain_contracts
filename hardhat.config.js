require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('hardhat-docgen');
const fs = require("fs");

const defaultNetwork = "goerli"; 

function mnemonic() {
  try {
    return fs.readFileSync("./mnemonic.txt").toString().trim();
  } catch (e) {
    if (defaultNetwork !== "localhost") {
    }
  }
  return "";
}

module.exports = {
  defaultNetwork,

  networks: {
    localhost: {
      url: "http://localhost:8545",
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/faefe1dcd6094fb388019173d2328d8f",
      accounts: {
        mnemonic: mnemonic(),
      },
    },
    mainnet: {
      url: "https://mainnet.infura.io/v3/faefe1dcd6094fb388019173d2328d8f",
      accounts: {
        mnemonic: mnemonic(),
      },
    },
    goerli: {
      url: "https://goerli.infura.io/v3/faefe1dcd6094fb388019173d2328d8f",
      accounts: {
        mnemonic: mnemonic(),
      },
    },
    kovan: {
      url: "https://kovan.infura.io/v3/faefe1dcd6094fb388019173d2328d8f",
      accounts: {
        mnemonic: mnemonic(),
      },
    },
    xdai: {
      url: 'https://dai.poa.network',
      gasPrice: 1000000000,
      accounts: {
        mnemonic: mnemonic(),
      },
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.5.11"
      },
      {
        version: "0.6.0"
      },
      {
        version:"0.5.8"
      },
      {
        version:"0.6.12"
      },
      {
        version:"0.7.0"
      }],
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  etherscan: {
    apiKey: "FQKZCMUAQUA688R7FVDIH9BGD6698JIFPZ"
    //npx hardhat clean
    //npx hardhat verify --network goerli 0x2BABA5Cadf0f8AbB8A145A9824c2972a08edD2c0
    //npx hardhat verify --network goerli --constructor-args project_arguments.js 0xe676a458f10fa4363838a8877c74e2aa4a6518cb
  },
  docgen: {
    path: './docs',
    clear: true,
    runOnCompile: true,
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 10000000
  }
};


