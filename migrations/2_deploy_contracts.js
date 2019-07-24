const ANNEngine = artifacts.require('ANNEngine');
const PAMEngine = artifacts.require('PAMEngine');
const FloatMath = artifacts.require('FloatMath');
const SignedMath = artifacts.require('SignedMath');


module.exports = async (deployer) => {
  await deployer.deploy(FloatMath);
  await deployer.deploy(SignedMath);
  
  await deployer.link(FloatMath, PAMEngine);
  await deployer.deploy(PAMEngine);

  await deployer.link(FloatMath, ANNEngine);
  await deployer.deploy(ANNEngine);
}
