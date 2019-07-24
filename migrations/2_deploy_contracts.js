const ANNEngine = artifacts.require('ANNEngine');
const PAMEngine = artifacts.require('PAMEngine');
const SignedMath = artifacts.require('SignedMath');


module.exports = async (deployer) => {
  await deployer.deploy(SignedMath);
  
  await deployer.link(SignedMath, PAMEngine);
  await deployer.deploy(PAMEngine);

  await deployer.link(SignedMath, ANNEngine);
  await deployer.deploy(ANNEngine);
}
