var MarketParLib = artifacts.require("./Market.sol");

module.exports = function(deployer) {
  deployer.deploy(MarketParLib);
};
