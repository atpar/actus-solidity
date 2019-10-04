pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Core/Core.sol";


contract STF is Core {

  function STF_PAM_AD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_CD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_FP (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_IED (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalValue = roleSign(contractTerms.contractRole) * contractTerms.notionalPrincipal;
    contractState.nominalRate = contractTerms.nominalInterestRate;
    contractState.lastEventTime = protoEvent.scheduleTime;

    if (contractTerms.cycleAnchorDateOfInterestPayment != 0 &&
      contractTerms.cycleAnchorDateOfInterestPayment < contractTerms.initialExchangeDate
    ) {
      contractState.nominalAccrued = contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(
        yearFraction(
          contractTerms.cycleAnchorDateOfInterestPayment,
          protoEvent.scheduleTime,
          contractTerms.dayCountConvention,
          contractTerms.maturityDate
        )
      );
    }

    return contractState;
  }

  function STF_PAM_IPCI (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_IP (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;
    
    return contractState;
  }

  function STF_PAM_PP (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.nominalValue -= 0; // riskFactor(contractTerms.objectCodeOfPrepaymentModel, protoEvent.scheduleTime, contractState, contractTerms) * contractState.nominalValue;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_PRD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_PR (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_PY (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_RRF (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_RR (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    // int256 rate = //riskFactor(contractTerms.marketObjectCodeOfRateReset, protoEvent.scheduleTime, contractState, contractTerms)
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
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_SC (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
      contractState.interestScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, protoEvent.scheduleTime, contractState, contractTerms)
    }
    if ((contractTerms.scalingEffect == ScalingEffect._0N0)
      || (contractTerms.scalingEffect == ScalingEffect._0NM)
      || (contractTerms.scalingEffect == ScalingEffect.IN0)
      || (contractTerms.scalingEffect == ScalingEffect.INM)
    ) {
      contractState.nominalScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, protoEvent.scheduleTime, contractState, contractTerms)
    }

    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_TD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalValue = 0;
    contractState.nominalAccrued = 0;
    contractState.feeAccrued = 0;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_DEL (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    uint256 nonPerformingDate = (contractState.nonPerformingDate == 0)
      ? protoEvent.eventTime
      : contractState.nonPerformingDate;

    bool isInGracePeriod = false;
    if (contractTerms.gracePeriod.isSet) {
      uint256 graceDate = getTimestampPlusPeriod(contractTerms.gracePeriod, nonPerformingDate);
      if (currentTimestamp <= graceDate) {
        contractState.contractStatus = ContractStatus.DL;
        isInGracePeriod = true;
      }
    }

    if (contractTerms.delinquencyPeriod.isSet && !isInGracePeriod) {
      uint256 delinquencyDate = getTimestampPlusPeriod(contractTerms.delinquencyPeriod, nonPerformingDate);
      if (currentTimestamp <= delinquencyDate) {
        contractState.contractStatus = ContractStatus.DQ;
      } else {
        contractState.contractStatus = ContractStatus.DF;
      }
    }

    if (contractState.nonPerformingDate == 0) {
      contractState.nonPerformingDate = protoEvent.eventTime;
    }

    return contractState;
  }

  function STF_ANN_AD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_ANN_CD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_ANN_FP (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_ANN_IED (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalValue = roleSign(contractTerms.contractRole) * contractTerms.notionalPrincipal;
    contractState.nominalRate = contractTerms.nominalInterestRate;
    contractState.lastEventTime = protoEvent.scheduleTime;

    if (contractTerms.cycleAnchorDateOfInterestPayment != 0 &&
      contractTerms.cycleAnchorDateOfInterestPayment < contractTerms.initialExchangeDate
    ) {
      contractState.nominalAccrued = contractState.nominalRate
      .floatMult(contractState.nominalValue)
      .floatMult(
        yearFraction(
          shiftCalcTime(contractTerms.cycleAnchorDateOfInterestPayment, contractTerms.businessDayConvention, contractTerms.calendar),
          shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
          contractTerms.dayCountConvention,
          contractTerms.maturityDate
        )
      );
    }

    return contractState;
  }

  function STF_ANN_IPCI (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_ANN_IP (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_ANN_PP (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.nominalValue -= 0; // riskFactor(contractTerms.objectCodeOfPrepaymentModel, protoEvent.scheduleTime, contractState, contractTerms) * contractState.nominalValue;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_ANN_PRD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_ANN_PR (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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

    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_ANN_MD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_ANN_PY (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_ANN_RRF (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_ANN_RR (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    // int256 rate = //riskFactor(contractTerms.marketObjectCodeOfRateReset, protoEvent.scheduleTime, contractState, contractTerms)
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
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_ANN_SC (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
      contractState.interestScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, protoEvent.scheduleTime, contractState, contractTerms)
    }
    if ((contractTerms.scalingEffect == ScalingEffect._0N0)
      || (contractTerms.scalingEffect == ScalingEffect._0NM)
      || (contractTerms.scalingEffect == ScalingEffect.IN0)
      || (contractTerms.scalingEffect == ScalingEffect.INM)
    ) {
      contractState.nominalScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, protoEvent.scheduleTime, contractState, contractTerms)
    }

    contractState.lastEventTime = protoEvent.scheduleTime;
    return contractState;
  }

  function STF_ANN_TD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.nominalValue = 0;
    contractState.nominalAccrued = 0;
    contractState.feeAccrued = 0;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

    function STF_ANN_DEL (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    uint256 nonPerformingDate = (contractState.nonPerformingDate == 0)
      ? protoEvent.eventTime
      : contractState.nonPerformingDate;

    bool isInGracePeriod = false;
    if (contractTerms.gracePeriod.isSet) {
      uint256 graceDate = getTimestampPlusPeriod(contractTerms.gracePeriod, nonPerformingDate);
      if (currentTimestamp <= graceDate) {
        contractState.contractStatus = ContractStatus.DL;
        isInGracePeriod = true;
      }
    }

    if (contractTerms.delinquencyPeriod.isSet && !isInGracePeriod) {
      uint256 delinquencyDate = getTimestampPlusPeriod(contractTerms.delinquencyPeriod, nonPerformingDate);
      if (currentTimestamp <= delinquencyDate) {
        contractState.contractStatus = ContractStatus.DQ;
      } else {
        contractState.contractStatus = ContractStatus.DF;
      }
    }

    if (contractState.nonPerformingDate == 0) {
      contractState.nonPerformingDate = protoEvent.eventTime;
    }

    return contractState;
  }
}