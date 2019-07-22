pragma solidity ^0.5.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

import "../../contracts/Core/Math/SignedMath.sol";


contract TestSignedMath {

  using SignedMath for int256;

  SignedMath instance;

  constructor() public {
    instance = SignedMath(DeployedAddresses.SignedMath());
  }

  function testSignedMin() public {
    Assert.equal(
      int256(1).min(int256(2)),
      1,
      "min of 1 and 2 should be 1"
    );

    Assert.equal(
      int256(1).min(int256(0)),
      0,
      "min of 1 and 0 should be 0"
    );

    Assert.equal(
      int256(1).min(int256(-1)),
      -1,
      "min of 1 and -1 should be -1"
    );
  }

  function testSignedMax() public {
    Assert.equal(
      int256(1).max(int256(2)),
      2,
      "max of 1 and 2 should be 2"
    );

    Assert.equal(
      int256(1).max(int256(0)),
      1,
      "max of 1 and 0 should be 1"
    );

    Assert.equal(
      int256(1).max(int256(-1)),
      1,
      "max of 1 and -1 should be 1"
    );
  }
}
