const { RelayProvider } = require("@opengsn/gsn");
const { GsnTestEnvironment } = require("@opengsn/gsn/dist/GsnTestEnvironment");
const { ethers } = require("hardhat");
const chai = require("chai");
const { solidity } = require("ethereum-waffle");
var expect = chai.expect;

const Web3HttpProvider = require("web3-providers-http");

//we still use truffle compiled files
const Factiiv = require("../artifacts/contracts/Factiiv.sol/Factiiv");

chai.use(solidity);
describe("using ethers with OpenGSN", () => {
  let factiiv;
  let web3provider;
  let from;
  before(async () => {
    let env = await GsnTestEnvironment.startGsn("localhost");
    // console.log("envir var: ", env);
    const { paymasterAddress, forwarderAddress } = env.contractsDeployment;
    web3provider = new Web3HttpProvider("http://localhost:8545");
    const deploymentProvider = new ethers.providers.Web3Provider(web3provider);
    //     root address is variable and can be changed according to needs
    //     root address is assigned the governance role on contract deployment
    var rootAddress = "0x19E7E376E7C213B7E7e7e46cc70A5dD086DAff2A";
    const factory = new ethers.ContractFactory(
      Factiiv.abi,
      Factiiv.bytecode,
      deploymentProvider.getSigner()
    );
    factiiv = await factory.deploy(rootAddress, forwarderAddress);
    await factiiv.deployed();
    const config = {
      paymasterAddress: paymasterAddress,
    };
    console.log("paymaster address", paymasterAddress);
    let gsnProvider = RelayProvider.newProvider({
      provider: web3provider,
      config,
    });
    await gsnProvider.init();
    // The above is the full provider configuration. can use the provider returned by startGsn:
    //     const gsnProvider = env.relayProvider;
    const account = new ethers.Wallet(Buffer.from("1".repeat(64), "hex"));
    gsnProvider.addAccount(account.privateKey);
    from = account.address;
    console.log("sending accoutt ::", account.address);
    // gsnProvider is now an rpc provider with GSN support. make it an ethers provider:
    const etherProvider = new ethers.providers.Web3Provider(gsnProvider);
    factiiv = factiiv.connect(etherProvider.getSigner(from));
  });

  describe("Set Minimum Amount", async () => {
    it("Should set Minmum Amount", async () => {
      await factiiv.setMinimumAmount(Number(100));

      await expect(factiiv.setMinimumAmount(Number(100)))
        .to.emit(factiiv, "SetMinimum")
        .withArgs("0x19E7E376E7C213B7E7e7e46cc70A5dD086DAff2A", 100);
      // expect((await factiiv.minimumAmount()).toNumber()).to.equal(Number(100));
    });
  });
});
