pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Core/Core.sol";


contract POF is Core {

  function POF_PAM_AD (
    ProtoEvent memory protoEvent,
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

  function POF_PAM_CD (
    ProtoEvent memory protoEvent,
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

  function POF_PAM_IPCI (
    ProtoEvent memory protoEvent,
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

  function POF_PAM_RRF (
    ProtoEvent memory protoEvent,
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

  function POF_PAM_RR (
    ProtoEvent memory protoEvent,
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

  function POF_PAM_SC (
    ProtoEvent memory protoEvent,
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

  function POF_PAM_DEL (
    ProtoEvent memory protoEvent,
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

  function POF_PAM_FP (
    ProtoEvent memory protoEvent,
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
            shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractTerms.feeRate)
          .floatMult(contractState.nominalValue)
        )
    );
  }

  function POF_PAM_IED (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
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
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
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
              shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractStatus)
      * roleSign(contractTerms.contractRole)
      * 0 // riskFactor(protoEvent.scheduleTime, contractState, contractTerms, contractTerms.objectCodeOfPrepaymentModel)
      * contractState.nominalValue
    );
  }

  function POF_PAM_PRD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
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
            shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractState.nominalRate)
          .floatMult(contractState.nominalValue)
        )
    );
  }

  function POF_PAM_PR (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
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
    ProtoEvent memory protoEvent,
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
            shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractTerms.penaltyRate)
          .floatMult(contractState.nominalValue)
      );
    } else {
      // riskFactor(protoEvent.scheduleTime, contractState, contractTerms, contractTerms.marketObjectCodeOfRateReset);
      int256 risk = 0;
      int256 param = 0;
      if (contractState.nominalRate - risk > 0) param = contractState.nominalRate - risk;
      return (
        performanceIndicator(contractState.contractStatus)
        * roleSign(contractTerms.contractRole)
        * yearFraction(
            shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
            shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractState.nominalValue)
          .floatMult(param)
      );
    }
  }

  function POF_PAM_TD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
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
            shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractState.nominalRate)
          .floatMult(contractState.nominalValue)
        )
    );
  }

  function POF_ANN_AD (
    ProtoEvent memory protoEvent,
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

  function POF_ANN_CD (
    ProtoEvent memory protoEvent,
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

  function POF_ANN_IPCI (
    ProtoEvent memory protoEvent,
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

  function POF_ANN_RRF (
    ProtoEvent memory protoEvent,
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

  function POF_ANN_RR (
    ProtoEvent memory protoEvent,
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

  function POF_ANN_SC (
    ProtoEvent memory protoEvent,
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

  function POF_ANN_DEL (
    ProtoEvent memory protoEvent,
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

  function POF_ANN_FP (
    ProtoEvent memory protoEvent,
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
              shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
              contractTerms.dayCountConvention,
              contractTerms.maturityDate
            )
            .floatMult(contractTerms.feeRate)
            .floatMult(contractState.nominalValue)
          )
      );
    }
  }

  function POF_ANN_IED (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
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

  function POF_ANN_IP (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
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
              shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
              contractTerms.dayCountConvention,
              contractTerms.maturityDate
            )
            .floatMult(contractState.nominalRate)
            .floatMult(contractState.nominalValue)
          )
        )
    );
  }

  function POF_ANN_PP (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(contractState.contractStatus)
      * roleSign(contractTerms.contractRole)
      * 0 // riskFactor(protoEvent.scheduleTime, contractState, contractTerms, contractTerms.objectCodeOfPrepaymentModel)
      * contractState.nominalValue
    );
  }

  function POF_ANN_PRD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
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
            shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractState.nominalRate)
          .floatMult(contractState.nominalValue)
        )
    );
  }

  function POF_ANN_PR (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
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
                  shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
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

  function POF_ANN_PY (
    ProtoEvent memory protoEvent,
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
            shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractTerms.penaltyRate)
          .floatMult(contractState.nominalValue)
      );
    } else {
      // riskFactor(protoEvent.scheduleTime, contractState, contractTerms, contractTerms.marketObjectCodeOfRateReset);
      int256 risk = 0;
      int256 param = 0;
      if (contractState.nominalRate - risk > 0) param = contractState.nominalRate - risk;
      return (
        performanceIndicator(contractState.contractStatus)
        * roleSign(contractTerms.contractRole)
        * yearFraction(
            shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
            shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractState.nominalValue)
          .floatMult(param)
      );
    }
  }

  function POF_ANN_TD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
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
            shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
            contractTerms.dayCountConvention,
            contractTerms.maturityDate
          )
          .floatMult(contractState.nominalRate)
          .floatMult(contractState.nominalValue)
        )
    );
  }
}