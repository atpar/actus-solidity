pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Core/Core.sol";


contract POF is Core {
  function POF_PAM_FP (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns(int256)
  {
    if (contractTerms.feeBasis == FeeBasis.A) {
      return (
        performanceIndicator(contractState.contractStatus)
        * roleSign(contractTerms.contractRole)
        * contractTerms.feeRate
      );
    }

    return (
      performanceIndicator(contractState.contractStatus)
      * contractState.feeAccrued
        .add(
          yearFraction(
            shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
            shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractTerms.feeRate)
          .floatMult(contractState.nominalValue)
        )
    );
  }

  function POF_PAM_IED (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractStatus)
      * roleSign(contractTerms.contractRole)
      * (-1)
      * contractTerms.notionalPrincipal
        .add(contractTerms.premiumDiscountAtIED)
    );
  }

  function POF_PAM_IP (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractStatus)
      * contractState.interestScalingMultiplier
        .floatMult(
          contractState.nominalAccrued
          .add(
            yearFraction(
              shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
              shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
              contractTerms.dayCountConvention,
              contractTerms.maturityDate
            )
            .floatMult(contractState.nominalRate)
            .floatMult(contractState.nominalValue)
          )
        )
    );
  }

  function POF_PAM_PP (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractStatus)
      * roleSign(contractTerms.contractRole)
      * 0 // riskFactor(timestamp, contractState, contractTerms, contractTerms.objectCodeOfPrepaymentModel)
      * contractState.nominalValue
    );
  }

  function POF_PAM_PRD (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractStatus)
      * roleSign(contractTerms.contractRole)
      * (-1)
      * contractTerms.priceAtPurchaseDate
        .add(contractState.nominalAccrued)
        .add(
          yearFraction(
            shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
            shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractState.nominalRate)
          .floatMult(contractState.nominalValue)
        )
    );
  }

  function POF_PAM_PR (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractStatus)
      * contractState.nominalScalingMultiplier
        .floatMult(contractState.nominalValue)
    );
  }

  function POF_PAM_PY (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns(int256)
  {
    if (contractTerms.penaltyType == PenaltyType.A) {
      return (
        performanceIndicator(contractState.contractStatus)
        * roleSign(contractTerms.contractRole)
        * contractTerms.penaltyRate
      );
    } else if (contractTerms.penaltyType == PenaltyType.N) {
      return (
        performanceIndicator(contractState.contractStatus)
        * roleSign(contractTerms.contractRole)
        * yearFraction(
            shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
            shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractTerms.penaltyRate)
          .floatMult(contractState.nominalValue)
      );
    } else {
      // riskFactor(timestamp, contractState, contractTerms, contractTerms.marketObjectCodeOfRateReset);
      int256 risk = 0;
      int256 param = 0;
      if (contractState.nominalRate - risk > 0) param = contractState.nominalRate - risk;
      return (
        performanceIndicator(contractState.contractStatus)
        * roleSign(contractTerms.contractRole)
        * yearFraction(
            shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
            shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractState.nominalValue)
          .floatMult(param)
      );
    }
  }

  function POF_PAM_TD (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractStatus)
      * roleSign(contractTerms.contractRole)
      * contractTerms.priceAtPurchaseDate
        .add(contractState.nominalAccrued)
        .add(
          yearFraction(
            shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
            shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractState.nominalRate)
          .floatMult(contractState.nominalValue)
        )
    );
  }

  function POF_ANN_FP (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns(int256)
  {
    if (contractTerms.feeBasis == FeeBasis.A) {
      return (
        performanceIndicator(contractState.contractStatus)
        * roleSign(contractTerms.contractRole)
        * contractTerms.feeRate
      );
    } else {
      return (
        performanceIndicator(contractState.contractStatus)
        * contractState.feeAccrued
          .add(
            yearFraction(
              shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
              shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
              contractTerms.dayCountConvention,
              contractTerms.maturityDate
            )
            .floatMult(contractTerms.feeRate)
            .floatMult(contractState.nominalValue)
          )
      );
    }
  }

  function POF_ANN_PR (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractStatus)
      * (contractState.nominalScalingMultiplier * roleSign(contractTerms.contractRole))
        .floatMult(
          (roleSign(contractTerms.contractRole) * contractState.nominalValue)
          .min(
              roleSign(contractTerms.contractRole)
              * (
                contractState.nextPrincipalRedemptionPayment
                - contractState.nominalAccrued
                - yearFraction(
                  shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
                  shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
                  contractTerms.dayCountConvention,
                  contractTerms.maturityDate
                )
                .floatMult(contractState.nominalRate)
                .floatMult(contractState.nominalValue)
              )
            )
        )
    );
  }

  function POF_ANN_MD (
    uint256 timestamp,
    ContractTerms memory contractTerms,
    ContractState memory contractState
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractStatus)
      * contractState.nominalScalingMultiplier
        .floatMult(contractState.nominalValue)
    );
  }
}