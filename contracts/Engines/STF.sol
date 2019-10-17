pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Core/Core.sol";


contract STF is Core {

  function STF_PAM_AD (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = contractState.nominalAccrued
    .add(
      contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.lastEventTime = timestamp;

    return contractState;
  }

  function STF_PAM_CD (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = contractState.nominalAccrued
    .add(
      contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.contractStatus = ContractStatus.DF;
    contractState.lastEventTime = timestamp;

    return contractState;
  }

  function STF_PAM_FP (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = contractState.nominalAccrued
    .add(
      contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.feeAccrued = 0;
    contractState.lastEventTime = timestamp;

    return contractState;
  }

  function STF_PAM_IED (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalValue = roleSign(contractTerms.contractRole) * contractTerms.notionalPrincipal;
    contractState.nominalRate = contractTerms.nominalInterestRate;
    contractState.lastEventTime = timestamp;

    if (contractTerms.cycleAnchorDateOfInterestPayment != 0 &&
      contractTerms.cycleAnchorDateOfInterestPayment < contractTerms.initialExchangeDate
    ) {
      contractState.nominalAccrued = contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(
        yearFraction(
          contractTerms.cycleAnchorDateOfInterestPayment,
          timestamp,
          contractTerms.dayCountConvention,
          contractTerms.maturityDate
        )
      );
    }

    return contractState;
  }

  function STF_PAM_IPCI (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalValue = contractState.nominalValue
    .add(
      contractState.nominalAccrued
      .add(
        contractState.nominalRate
        .floatMult(contractState.nominalValue)
        .floatMult(contractState.timeFromLastEvent)
      )
    );
    contractState.nominalAccrued = 0;
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.lastEventTime = timestamp;

    return contractState;
  }

  function STF_PAM_IP (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = 0;
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.lastEventTime = timestamp;
    
    return contractState;
  }

  function STF_PAM_PP (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = contractState.nominalAccrued
    .add(
      contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.nominalValue -= 0; // riskFactor(contractTerms.objectCodeOfPrepaymentModel, timestamp, contractState, contractTerms) * contractState.nominalValue;
    contractState.lastEventTime = timestamp;

    return contractState;
  }

  function STF_PAM_PRD (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = contractState.nominalAccrued
    .add(
      contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.lastEventTime = timestamp;

    return contractState;
  }

  function STF_PAM_PR (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = contractState.nominalAccrued
    .add(
      contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.nominalValue = 0;
    contractState.lastEventTime = timestamp;

    return contractState;
  }

  function STF_PAM_PY (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = contractState.nominalAccrued
    .add(
      contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.lastEventTime = timestamp;

    return contractState;
  }

  function STF_PAM_RRF (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = contractState.nominalAccrued
    .add(
      contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.nominalRate = contractTerms.nextResetRate;
    contractState.lastEventTime = timestamp;

    return contractState;
  }

  function STF_PAM_RR (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    // int256 rate = //riskFactor(contractTerms.marketObjectCodeOfRateReset, timestamp, contractState, contractTerms)
    // 	* contractTerms.rateMultiplier + contractTerms.rateSpread;
    int256 rate = contractTerms.rateSpread;
    int256 deltaRate = rate.sub(contractState.nominalRate);

      // apply period cap/floor
    if ((contractTerms.lifeCap < deltaRate) && (contractTerms.lifeCap < ((-1) * contractTerms.periodFloor))) {
      deltaRate = contractTerms.lifeCap;
    } else if (deltaRate < ((-1) * contractTerms.periodFloor)) {
      deltaRate = ((-1) * contractTerms.periodFloor);
    }
    rate = contractState.nominalRate.add(deltaRate);

    // apply life cap/floor
    if (contractTerms.lifeCap < rate && contractTerms.lifeCap < contractTerms.lifeFloor) {
      rate = contractTerms.lifeCap;
    } else if (rate < contractTerms.lifeFloor) {
      rate = contractTerms.lifeFloor;
    }

    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = contractState.nominalAccrued
    .add(
      contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.nominalRate = rate;
    contractState.lastEventTime = timestamp;

    return contractState;
  }

  function STF_PAM_SC (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = contractState.nominalAccrued
    .add(
      contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );

    if ((contractTerms.scalingEffect == ScalingEffect.I00)
      || (contractTerms.scalingEffect == ScalingEffect.IN0)
      || (contractTerms.scalingEffect == ScalingEffect.I0M)
      || (contractTerms.scalingEffect == ScalingEffect.INM)
    ) {
      contractState.interestScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, timestamp, contractState, contractTerms)
    }
    if ((contractTerms.scalingEffect == ScalingEffect._0N0)
      || (contractTerms.scalingEffect == ScalingEffect._0NM)
      || (contractTerms.scalingEffect == ScalingEffect.IN0)
      || (contractTerms.scalingEffect == ScalingEffect.INM)
    ) {
      contractState.nominalScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, timestamp, contractState, contractTerms)
    }

    contractState.lastEventTime = timestamp;

    return contractState;
  }

  function STF_PAM_TD (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalValue = 0;
    contractState.nominalAccrued = 0;
    contractState.feeAccrued = 0;
    contractState.lastEventTime = timestamp;

    return contractState;
  }

  // function STF_ANN_AD (
  //   uint256 timestamp,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   contractState.timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.nominalAccrued = contractState.nominalAccrued
  //   .add(
  //     contractState.nominalRate
  //     .floatMult(contractState.nominalValue)
  //     .floatMult(contractState.timeFromLastEvent)
  //   );
  //   contractState.feeAccrued = contractState.feeAccrued
  //   .add(
  //     contractTerms.feeRate
  //     .floatMult(contractState.nominalValue)
  //     .floatMult(contractState.timeFromLastEvent)
  //   );
  //   contractState.lastEventTime = timestamp;

  //   return contractState;
  // }

  // function STF_ANN_CD (
  //   uint256 timestamp,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   contractState.timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.nominalAccrued = contractState.nominalAccrued
  //   .add(
  //     contractState.nominalRate
  //     .floatMult(contractState.nominalValue)
  //     .floatMult(contractState.timeFromLastEvent)
  //   );
  //   contractState.feeAccrued = contractState.feeAccrued
  //   .add(
  //     contractTerms.feeRate
  //     .floatMult(contractState.nominalValue)
  //     .floatMult(contractState.timeFromLastEvent)
  //   );
  //   contractState.contractStatus = ContractStatus.DF;
  //   contractState.lastEventTime = timestamp;

  //   return contractState;
  // }

  // function STF_ANN_FP (
  //   uint256 timestamp,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   contractState.timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.nominalAccrued = contractState.nominalAccrued
  //   .add(
  //     contractState.nominalRate
  //     .floatMult(contractState.nominalValue)
  //     .floatMult(contractState.timeFromLastEvent)
  //   );
  //   contractState.feeAccrued = 0;
  //   contractState.lastEventTime = timestamp;

  //   return contractState;
  // }

  function STF_ANN_IED (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalValue = roleSign(contractTerms.contractRole) * contractTerms.notionalPrincipal;
    contractState.nominalRate = contractTerms.nominalInterestRate;
    contractState.lastEventTime = timestamp;

    if (contractTerms.cycleAnchorDateOfInterestPayment != 0 &&
      contractTerms.cycleAnchorDateOfInterestPayment < contractTerms.initialExchangeDate
    ) {
      contractState.nominalAccrued = contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(
        yearFraction(
          shiftCalcTime(contractTerms.cycleAnchorDateOfInterestPayment, contractTerms.businessDayConvention, contractTerms.calendar),
          shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
          contractTerms.dayCountConvention,
          contractTerms.maturityDate
        )
      );
    }

    return contractState;
  }

  function STF_ANN_IPCI (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = contractState.nominalAccrued
    .add(
      contractState.nominalAccrued
      .add(
        contractState.nominalRate
        .floatMult(contractState.nominalValue)
        .floatMult(contractState.timeFromLastEvent)
      )
    );
    contractState.nominalAccrued = 0;
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.lastEventTime = timestamp;

    return contractState;
  }

  function STF_ANN_IP (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = 0;
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.lastEventTime = timestamp;

    return contractState;
  }

  // function STF_ANN_PP (
  //   uint256 timestamp,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   contractState.timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.nominalAccrued = contractState.nominalAccrued
  //   .add(
  //     contractState.nominalRate
  //     .floatMult(contractState.nominalValue)
  //     .floatMult(contractState.timeFromLastEvent)
  //   );
  //   contractState.feeAccrued = contractState.feeAccrued
  //   .add(
  //     contractTerms.feeRate
  //     .floatMult(contractState.nominalValue)
  //     .floatMult(contractState.timeFromLastEvent)
  //   );
  //   contractState.nominalValue -= 0; // riskFactor(contractTerms.objectCodeOfPrepaymentModel, timestamp, contractState, contractTerms) * contractState.nominalValue;
  //   contractState.lastEventTime = timestamp;

  //   return contractState;
  // }

  // STF_PAM_PRD
  // function STF_ANN_PRD (
  //   uint256 timestamp,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   contractState.timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.nominalAccrued = contractState.nominalAccrued
  //   .add(
  //     contractState.nominalRate
  //     .floatMult(contractState.nominalValue)
  //     .floatMult(contractState.timeFromLastEvent)
  //   );
  //   contractState.feeAccrued = contractState.feeAccrued
  //   .add(
  //     contractTerms.feeRate
  //     .floatMult(contractState.nominalValue)
  //     .floatMult(contractState.timeFromLastEvent)
  //   );
  //   contractState.lastEventTime = timestamp;

  //   return contractState;
  // }

  function STF_ANN_PR (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = contractState.nominalAccrued
    .add(
      contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.nominalValue = contractState.nominalValue
    .sub(
      roleSign(contractTerms.contractRole)
      * (
        roleSign(contractTerms.contractRole)
        * contractState.nominalValue
      )
      .min(
        roleSign(contractTerms.contractRole)
        * (
          contractState.nextPrincipalRedemptionPayment
          .sub(contractState.nominalAccrued)
        )
      )
    );

    contractState.lastEventTime = timestamp;

    return contractState;
  }

  function STF_ANN_MD (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = contractState.nominalAccrued
    .add(
      contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.nominalValue = 0.0;
    contractState.lastEventTime = timestamp;

    return contractState;
  }

  // STF_PAM_PY
  // function STF_ANN_PY (
  //   uint256 timestamp,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   contractState.timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.nominalAccrued = contractState.nominalAccrued
  //   .add(
  //     contractState.nominalRate
  //     .floatMult(contractState.nominalValue)
  //     .floatMult(contractState.timeFromLastEvent)
  //   );
  //   contractState.feeAccrued = contractState.feeAccrued
  //   .add(
  //     contractTerms.feeRate
  //     .floatMult(contractState.nominalValue)
  //     .floatMult(contractState.timeFromLastEvent)
  //   );
  //   contractState.lastEventTime = timestamp;

  //   return contractState;
  // }

  // function STF_ANN_RRF (
  //   uint256 timestamp,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   contractState.timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.nominalAccrued = contractState.nominalAccrued
  //   .add(
  //     contractState.nominalRate
  //     .floatMult(contractState.nominalValue)
  //     .floatMult(contractState.timeFromLastEvent)
  //   );
  //   contractState.feeAccrued = contractState.feeAccrued
  //   .add(
  //     contractTerms.feeRate
  //     .floatMult(contractState.nominalValue)
  //     .floatMult(contractState.timeFromLastEvent)
  //   );
  //   contractState.nominalRate = contractTerms.nextResetRate;
  //   contractState.lastEventTime = timestamp;

  //   return contractState;
  // }

  function STF_ANN_RR (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    // int256 rate = //riskFactor(contractTerms.marketObjectCodeOfRateReset, timestamp, contractState, contractTerms)
    // 	* contractTerms.rateMultiplier + contractTerms.rateSpread;
    int256 rate = contractTerms.rateSpread;
    int256 deltaRate = rate.sub(contractState.nominalRate);

      // apply period cap/floor
    if ((contractTerms.lifeCap < deltaRate) && (contractTerms.lifeCap < ((-1) * contractTerms.periodFloor))) {
      deltaRate = contractTerms.lifeCap;
    } else if (deltaRate < ((-1) * contractTerms.periodFloor)) {
      deltaRate = ((-1) * contractTerms.periodFloor);
    }
    rate = contractState.nominalRate.add(deltaRate);

    // apply life cap/floor
    if (contractTerms.lifeCap < rate && contractTerms.lifeCap < contractTerms.lifeFloor) {
      rate = contractTerms.lifeCap;
    } else if (rate < contractTerms.lifeFloor) {
      rate = contractTerms.lifeFloor;
    }

    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = contractState.nominalAccrued
    .add(
      contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.nominalRate = rate;
    contractState.nextPrincipalRedemptionPayment = 0; // TODO: implement annuity calculator
    contractState.lastEventTime = timestamp;

    return contractState;
  }

  function STF_ANN_SC (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalAccrued = contractState.nominalAccrued
    .add(
      contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.nominalValue)
      .floatMult(contractState.timeFromLastEvent)
    );

    if ((contractTerms.scalingEffect == ScalingEffect.I00)
      || (contractTerms.scalingEffect == ScalingEffect.IN0)
      || (contractTerms.scalingEffect == ScalingEffect.I0M)
      || (contractTerms.scalingEffect == ScalingEffect.INM)
    ) {
      contractState.interestScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, timestamp, contractState, contractTerms)
    }
    if ((contractTerms.scalingEffect == ScalingEffect._0N0)
      || (contractTerms.scalingEffect == ScalingEffect._0NM)
      || (contractTerms.scalingEffect == ScalingEffect.IN0)
      || (contractTerms.scalingEffect == ScalingEffect.INM)
    ) {
      contractState.nominalScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, timestamp, contractState, contractTerms)
    }

    contractState.lastEventTime = timestamp;
    return contractState;
  }

  // function STF_ANN_TD (
  //   uint256 timestamp,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   contractState.timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.nominalValue = 0;
  //   contractState.nominalAccrued = 0;
  //   contractState.feeAccrued = 0;
  //   contractState.lastEventTime = timestamp;

  //   return contractState;
  // }
}