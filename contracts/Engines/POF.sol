pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Core/Core.sol";


contract POF is Core {
  function POF_PAM_FP (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    if (contractTerms.feeBasis == FeeBasis.A) {
      return (
        performanceIndicator(contractState.contractPerformance)
        * roleSign(contractTerms.contractRole)
        * contractTerms.feeRate
      );
    }

    return (
      performanceIndicator(contractState.contractPerformance)
      * contractState.feeAccrued
        .add(
          yearFraction(
            shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
            shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractTerms.feeRate)
          .floatMult(contractState.notionalPrincipal)
        )
    );
  }

  function POF_PAM_IED (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractPerformance)
      * roleSign(contractTerms.contractRole)
      * (-1)
      * contractTerms.notionalPrincipal
        .add(contractTerms.premiumDiscountAtIED)
    );
  }

  function POF_PAM_IP (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractPerformance)
      * contractState.interestScalingMultiplier
        .floatMult(
          contractState.accruedInterest
          .add(
            yearFraction(
              shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
              shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
              contractTerms.dayCountConvention,
              contractTerms.maturityDate
            )
            .floatMult(contractState.nominalInterestRate)
            .floatMult(contractState.notionalPrincipal)
          )
        )
    );
  }

  function POF_PAM_PP (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractPerformance)
      * roleSign(contractTerms.contractRole)
      * 0 // riskFactor(scheduleTime, contractState, contractTerms, contractTerms.objectCodeOfPrepaymentModel)
      * contractState.notionalPrincipal
    );
  }

  function POF_PAM_PRD (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractPerformance)
      * roleSign(contractTerms.contractRole)
      * (-1)
      * contractTerms.priceAtPurchaseDate
        .add(contractState.accruedInterest)
        .add(
          yearFraction(
            shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
            shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractState.nominalInterestRate)
          .floatMult(contractState.notionalPrincipal)
        )
    );
  }

  function POF_PAM_PR (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractPerformance)
      * contractState.notionalScalingMultiplier
        .floatMult(contractState.notionalPrincipal)
    );
  }

  function POF_PAM_PY (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    if (contractTerms.penaltyType == PenaltyType.A) {
      return (
        performanceIndicator(contractState.contractPerformance)
        * roleSign(contractTerms.contractRole)
        * contractTerms.penaltyRate
      );
    } else if (contractTerms.penaltyType == PenaltyType.N) {
      return (
        performanceIndicator(contractState.contractPerformance)
        * roleSign(contractTerms.contractRole)
        * yearFraction(
            shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
            shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractTerms.penaltyRate)
          .floatMult(contractState.notionalPrincipal)
      );
    } else {
      // riskFactor(scheduleTime, contractState, contractTerms, contractTerms.marketObjectCodeOfRateReset);
      int256 risk = 0;
      int256 param = 0;
      if (contractState.nominalInterestRate - risk > 0) param = contractState.nominalInterestRate - risk;
      return (
        performanceIndicator(contractState.contractPerformance)
        * roleSign(contractTerms.contractRole)
        * yearFraction(
            shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
            shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractState.notionalPrincipal)
          .floatMult(param)
      );
    }
  }

  function POF_PAM_TD (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractPerformance)
      * roleSign(contractTerms.contractRole)
      * contractTerms.priceAtPurchaseDate
        .add(contractState.accruedInterest)
        .add(
          yearFraction(
            shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
            shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractState.nominalInterestRate)
          .floatMult(contractState.notionalPrincipal)
        )
    );
  }

  function POF_ANN_FP (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    if (contractTerms.feeBasis == FeeBasis.A) {
      return (
        performanceIndicator(contractState.contractPerformance)
        * roleSign(contractTerms.contractRole)
        * contractTerms.feeRate
      );
    } else {
      return (
        performanceIndicator(contractState.contractPerformance)
        * contractState.feeAccrued
          .add(
            yearFraction(
              shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
              shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
              contractTerms.dayCountConvention,
              contractTerms.maturityDate
            )
            .floatMult(contractTerms.feeRate)
            .floatMult(contractState.notionalPrincipal)
          )
      );
    }
  }

  function POF_ANN_PR (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractPerformance)
      * (contractState.notionalScalingMultiplier * roleSign(contractTerms.contractRole))
        .floatMult(
          (roleSign(contractTerms.contractRole) * contractState.notionalPrincipal)
          .min(
              roleSign(contractTerms.contractRole)
              * (
                contractState.nextPrincipalRedemptionPayment
                - contractState.accruedInterest
                - yearFraction(
                  shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
                  shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
                  contractTerms.dayCountConvention,
                  contractTerms.maturityDate
                )
                .floatMult(contractState.nominalInterestRate)
                .floatMult(contractState.notionalPrincipal)
              )
            )
        )
    );
  }

  function POF_ANN_MD (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractPerformance)
      * contractState.notionalScalingMultiplier
        .floatMult(contractState.notionalPrincipal)
    );
  }

  function POF_CEG_MD (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    return 0;
  }

  function POF_CEG_XD (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractPerformance)
      * roleSign(contractTerms.contractRole)
      * contractTerms.coverageOfCreditEnhancement
        .floatMult(contractState.notionalPrincipal)
    );
  }

  function POF_CEG_PRD (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractPerformance)
      * roleSign(contractTerms.contractRole)
      * (-1)
      * contractTerms.priceAtPurchaseDate
    );
  }

  function POF_CEG_FP (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    if (contractTerms.feeBasis == FeeBasis.A) {
      return (
        performanceIndicator(contractState.contractPerformance)
        * roleSign(contractTerms.contractRole)
        * contractTerms.feeRate
      );
    }

    return (
      performanceIndicator(contractState.contractPerformance)
      * contractState.feeAccrued
        .add(
          yearFraction(
            shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
            shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractTerms.feeRate)
          .floatMult(contractState.notionalPrincipal)
        )
    );
  }
}