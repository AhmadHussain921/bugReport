/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-web3");

require("solidity-coverage");

module.exports = {
  solidity: "0.8.4",
  compilers: [
    {
      version: "0.8.4",
    },
  ],
};
