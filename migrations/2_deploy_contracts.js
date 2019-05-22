const PAMEngine = artifacts.require('PAMEngine');
const FloatMath = artifacts.require('FloatMath');

module.exports = async (deployer, network, accounts) => {
  await deployer.deploy(FloatMath);
  await deployer.link(FloatMath, PAMEngine);
  await deployer.deploy(PAMEngine);
}
