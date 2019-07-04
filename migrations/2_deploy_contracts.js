var Finocial = artifacts.require('./Finocial.sol');
var StandardToken = artifacts.require('./StandardToken.sol');
module.exports = async function(deployer, network, accounts) {

  deployer.deploy(Finocial);

  /**
  * below deployment should be only for Development
  */
  const standardToken = await deployer.deploy(StandardToken, "Test Tokens", "TTT", 18, 10000000000);

}
