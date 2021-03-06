require("@nomiclabs/hardhat-ethers");

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      forking: {
        url: "https://eth-mainnet.alchemyapi.io/v2/UQY0A_j357POL__TwO87Mc-37GvIzuZs",
        blockNumber: 12041561,
      },
      loggingEnabled: true,
    }
  },
  paths: {
    sources: "./contracts",
    cache: "./build/cache",
    artifacts: "./build/artifacts",
    tests: "./test",
  },
  solidity: {
    compilers: [
      { version: "0.8.2" },
    ]
  }
};
