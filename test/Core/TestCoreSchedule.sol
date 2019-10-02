pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "truffle/Assert.sol";

import "../../contracts/Core/Core.sol";


contract TestCoreSchedule is Core {

  /** Covered test cases:
    - cycle not set, different overlaps, with or without endtime
    - Different overlaps of segment and cycle with or without addEndtime
      - start before, end before
      - start before, end within
      - start before, end after
      - start within, end within
      - start within, end after
      - start after, end after

      The tests are divided into multiple parts to avoid a stack which is too deep
  */
  function testComputeDatesFromCycleSegment_1() public {

    // Initialize variables
    IPS memory c = IPS(1, P.M, S.LONG, false); // Every 1 month
    EndOfMonthConvention eomc = EndOfMonthConvention.EOM;
    bool addEndTime = false;
    uint256 cStart = 1514764800; // Monday, 2018-01-01 00:00:00 UTC
    uint256 cEnd = 1538352000; // Monday, 2018-10-01 00:00:00 UTC
    uint256 sStart = 1525132800; // Tuesday, 2018-05-01 00:00:00 UTC
    uint256 sEnd = 1535760000; // Saturday, 2018-09-01 00:00:00 UTC

    /*
    * test cases where cycle.isSet == false
    */
    c = IPS(1, P.M, S.LONG, false); // isSet = false

    // Segment lies before cycle
    uint256[MAX_CYCLE_SIZE] memory result_t1; // empty array
    Assert.equal(
      keccak256(abi.encode(computeDatesFromCycleSegment(cStart, cEnd, c, eomc, addEndTime, 0, 0))),
      keccak256(abi.encode(result_t1)),
      "Should return an empty array"
    );

    // Segment lies after cycle
    uint256[MAX_CYCLE_SIZE] memory result_t2; // empty array
    Assert.equal(
      keccak256(abi.encode(computeDatesFromCycleSegment(cStart, cEnd, c, eomc, addEndTime, 9999999999, 9999999999))),
      keccak256(abi.encode(result_t2)),
      "Should return an empty array"
    );

    // Segment lies within cycle
    uint256[MAX_CYCLE_SIZE] memory result_t3;
    uint256[MAX_CYCLE_SIZE] memory dates_t3 = computeDatesFromCycleSegment(cStart, cEnd, c, eomc, addEndTime, sStart, sEnd);

    Assert.equal(
      keccak256(abi.encode(dates_t3)), keccak256(abi.encode(result_t3)),
      "Should return an empty array");

    // Cycle lies within Segment, addEndTime == false
    uint256[MAX_CYCLE_SIZE] memory result_t4;
    addEndTime = false;
    result_t4[0] = cStart;
    sStart = 0;
    sEnd = 9999999999;
    uint256[MAX_CYCLE_SIZE] memory dates_t4 = computeDatesFromCycleSegment(cStart, cEnd, c, eomc, addEndTime, sStart, sEnd);

    Assert.equal(keccak256(abi.encode(dates_t4)), keccak256(abi.encode(result_t4)),
      "Array should contain only the cycle start date");
  }

  function testComputeDatesFromCycleSegment_2() public {

    // Initialize variables
    IPS memory c = IPS(1, P.M, S.LONG, false); // Every 1 month
    EndOfMonthConvention eomc = EndOfMonthConvention.EOM;
    bool addEndTime = false;
    uint256 cStart = 1514764800; // Monday, 2018-01-01 00:00:00 UTC
    uint256 cEnd = 1538352000; // Monday, 2018-10-01 00:00:00 UTC
    uint256 sStart = 1525132800; // Tuesday, 2018-05-01 00:00:00 UTC
    uint256 sEnd = 1535760000; // Saturday, 2018-09-01 00:00:00 UTC

    /*
    * test cases where cycle.isSet == false (continued)
    */
    // Cycle lies within Segment, addEndTime == true
    uint256[MAX_CYCLE_SIZE] memory result_t5;
    addEndTime = true;
    result_t5[0] = cStart;
    result_t5[1] = cEnd;

    Assert.equal(
      keccak256(abi.encode(computeDatesFromCycleSegment(cStart, cEnd, c, eomc, addEndTime, 0, 9999999999))),
      keccak256(abi.encode(result_t5)),
      "Array should contain cycle start and end dates");

    // Only cycle start lies within segment, addEndTime == true
    addEndTime = true;
    uint256[MAX_CYCLE_SIZE] memory result_t6;
    result_t6[0] = cStart;
    Assert.equal(
      keccak256(abi.encode(computeDatesFromCycleSegment(cStart, cEnd, c, eomc, addEndTime, 0, sEnd))),
      keccak256(abi.encode(result_t6)),
      "Should contain cycle start date"
    );

    // Only cycle end lies within segment, addEndTime == false
    addEndTime = false;
    uint256[MAX_CYCLE_SIZE] memory result_t7; // empty array
    Assert.equal(
      keccak256(abi.encode(computeDatesFromCycleSegment(cStart, cEnd, c, eomc, addEndTime, sStart, 9999999999))),
      keccak256(abi.encode(result_t7)),
      "Should return an empty array"
    );
  }

  function testComputeDatesFromCycleSegment_3() public {

    // Initialize variables
    IPS memory c = IPS(1, P.M, S.LONG, true); // Every 1 month
    EndOfMonthConvention eomc = EndOfMonthConvention.EOM;
    bool addEndTime = false;
    uint256 cStart = 1514764800; // Monday, 2018-01-01 00:00:00 UTC
    uint256 cEnd = 1538352000; // Monday, 2018-10-01 00:00:00 UTC
    uint256 sStart = 1525132800; // Tuesday, 2018-05-01 00:00:00 UTC
    uint256 sEnd = 1535760000; // Saturday, 2018-09-01 00:00:00 UTC

    /*
    * test cases where cycle.isSet == true
    */

    // Segment lies in cycle
    uint256[MAX_CYCLE_SIZE] memory result_t7; // empty array
    uint256[MAX_CYCLE_SIZE] memory dates_t7;
    dates_t7 = computeDatesFromCycleSegment(cStart, cEnd, c, eomc, addEndTime, sStart, sEnd);

    result_t7[0] = uint256(1527811200); // Friday, 2018-06-01 00:00:00 UTC
    result_t7[1] = uint256(1530403200); // Sunday, 2018-07-01 00:00:00 UTC
    result_t7[2] = uint256(1533081600); // Wednesday, 2018-08-01 00:00:00 UTC
    result_t7[3] = uint256(1535760000); // Saturday, 2018-09-01 00:00:00 UTC

    Assert.equal(
      keccak256(abi.encode(dates_t7)),
      keccak256(abi.encode(result_t7)),
      "Should return 1527811200, 1530403200, 1533081600, 1535760000"
    );

    // Segment lies in cycle, addEndTime = false
    addEndTime = false;
    uint256[MAX_CYCLE_SIZE] memory result_t8; // empty array
    uint256[MAX_CYCLE_SIZE] memory dates_t8;
    dates_t8 = computeDatesFromCycleSegment(cStart, cEnd, c, eomc, addEndTime, 0, 9999999999);

    result_t8[0] = uint256(1514764800); // Monday, 2018-01-01 00:00:00 UTC
    result_t8[1] = uint256(1517443200); // Thursday, 2018-02-01 00:00:00 UTC
    result_t8[2] = uint256(1519862400); // Thursday, 2018-03-01 00:00:00 UTC
    result_t8[3] = uint256(1522540800); // Sunday, 2018-04-01 00:00:00 UTC
    result_t8[4] = uint256(1525132800); // Tuesday, 2018-05-01 00:00:00 UTC
    result_t8[5] = uint256(1527811200); // Friday, 2018-06-01 00:00:00 UTC
    result_t8[6] = uint256(1530403200); // Sunday, 2018-07-01 00:00:00 UTC
    result_t8[7] = uint256(1533081600); // Wednesday, 2018-08-01 00:00:00 UTC
    result_t8[8] = uint256(1535760000); // Saturday, 2018-09-01 00:00:00 UTC

    Assert.equal(
      keccak256(abi.encode(dates_t8)),
      keccak256(abi.encode(result_t8)),
      "Should return 1514764800, 1517443200, 1519862400, 1522540800, 1525132800, 1527811200, 1530403200, 1533081600, 1535760000"
    );

    // Segment lies in cycle, addEndTime = true
    addEndTime = true;
    uint256[MAX_CYCLE_SIZE] memory result_t9; // empty array
    uint256[MAX_CYCLE_SIZE] memory dates_t9;
    dates_t9 = computeDatesFromCycleSegment(cStart, cEnd, c, eomc, addEndTime, 0, 9999999999);

    result_t9[0] = uint256(1514764800); // Monday, 2018-01-01 00:00:00 UTC
    result_t9[1] = uint256(1517443200); // Thursday, 2018-02-01 00:00:00 UTC
    result_t9[2] = uint256(1519862400); // Thursday, 2018-03-01 00:00:00 UTC
    result_t9[3] = uint256(1522540800); // Sunday, 2018-04-01 00:00:00 UTC
    result_t9[4] = uint256(1525132800); // Tuesday, 2018-05-01 00:00:00 UTC
    result_t9[5] = uint256(1527811200); // Friday, 2018-06-01 00:00:00 UTC
    result_t9[6] = uint256(1530403200); // Sunday, 2018-07-01 00:00:00 UTC
    result_t9[7] = uint256(1533081600); // Wednesday, 2018-08-01 00:00:00 UTC
    result_t9[8] = uint256(1535760000); // Saturday, 2018-09-01 00:00:00 UTC
    result_t9[9] = uint256(1538352000); // Monday, 2018-10-01 00:00:00 UTC

    Assert.equal(
      keccak256(abi.encode(dates_t9)),
      keccak256(abi.encode(result_t9)),
      "Should return 1514764800, 1517443200, 1519862400, 1522540800, 1525132800, 1527811200, 1530403200, 1533081600, 1535760000, 1538352000"
    );
  }
}
