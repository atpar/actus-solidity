pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/drafts/SignedSafeMath.sol";

import "../Core/Core.sol";
import "../Core/SignedMath.sol";
import "./IEngine.sol";
import "./STF.sol";
import "./POF.sol";


/**
 * @title the stateless component for a PAM contract
 * implements the STF and POF of the Actus standard for a PAM contract
 * @dev all numbers except unix timestamp are represented as multiple of 10 ** 18
 * inputs have to be multiplied by 10 ** 18, outputs have to divided by 10 ** 18
 */
contract PAMEngine is Core, IEngine, STF, POF {

	/**
	 * initialize contract state space based on the contract terms
	 * @dev see initStateSpace()
	 * @param contractTerms terms of the contract
	 * @return initial contract state
	 */
	function computeInitialState(ContractTerms memory contractTerms)
		public
		pure
		returns (ContractState memory)
	{
		ContractState memory contractState;

		contractState.contractPerformance = ContractPerformance.PF;
		contractState.notionalScalingMultiplier = int256(1 * 10 ** PRECISION);
		contractState.interestScalingMultiplier = int256(1 * 10 ** PRECISION);
		contractState.lastEventTime = contractTerms.statusDate;
		contractState.notionalPrincipal = contractTerms.notionalPrincipal;
		contractState.nominalInterestRate = contractTerms.nominalInterestRate;
		contractState.accruedInterest = contractTerms.accruedInterest;
		contractState.feeAccrued = contractTerms.feeAccrued;

		return contractState;
	}

	/**
	 * applys a prototype event to the current state of a contract and
	 * returns the contrat event and the new contract state
	 * @param contractTerms terms of the contract
	 * @param contractState current state of the contract
	 * @param protoEvent prototype event to be evaluated and applied to the contract state
	 * @param currentTimestamp current timestamp
	 * @return the new contract state and the evaluated event
	 */
	function computeStateForProtoEvent(
		ContractTerms memory contractTerms,
		ContractState memory contractState,
		bytes32 protoEvent,
		uint256 currentTimestamp
	)
		public
		pure
		returns (ContractState memory)
	{
		return stateTransitionFunction(
			protoEvent,
			contractState,
			contractTerms,
			currentTimestamp
		);
	}

	/**
	 * applys a prototype event to the current state of a contract and
	 * returns the contrat event and the new contract state
	 * @param contractTerms terms of the contract
	 * @param contractState current state of the contract
	 * @param protoEvent prototype event to be evaluated and applied to the contract state
	 * @param currentTimestamp current timestamp
	 * @return the new contract state and the evaluated event
	 */
	function computePayoffForProtoEvent(
		ContractTerms memory contractTerms,
		ContractState memory contractState,
		bytes32 protoEvent,
		uint256 currentTimestamp
	)
		public
		pure
		returns (int256)
	{
		return payoffFunction(
			protoEvent,
			contractState,
			contractTerms,
			currentTimestamp
		);
	}

	/**
	 * computes a schedule segment of non-cyclic contract events based on the contract terms and the specified period
	 * @param contractTerms terms of the contract
	 * @param segmentStart start timestamp of the segment
	 * @param segmentEnd end timestamp of the segement
	 * @return event schedule segment
	 */
	function computeNonCyclicProtoEventScheduleSegment(
		ContractTerms memory contractTerms,
		uint256 segmentStart,
		uint256 segmentEnd
	)
		public
		pure
		returns (bytes32[MAX_EVENT_SCHEDULE_SIZE] memory)
	{
		bytes32[MAX_EVENT_SCHEDULE_SIZE] memory protoEventSchedule;
		uint16 index = 0;

		// initial exchange
		if (isInPeriod(contractTerms.initialExchangeDate, segmentStart, segmentEnd)) {
			protoEventSchedule[index] = encodeProtoEvent(EventType.IED, contractTerms.initialExchangeDate);
			index++;
		}

		// purchase
		if (contractTerms.purchaseDate != 0) {
			if (isInPeriod(contractTerms.purchaseDate, segmentStart, segmentEnd)) {
				protoEventSchedule[index] = encodeProtoEvent(EventType.PRD, contractTerms.purchaseDate);
				index++;
			}
		}

		// termination
		if (contractTerms.terminationDate != 0) {
			if (isInPeriod(contractTerms.terminationDate, segmentStart, segmentEnd)) {
				protoEventSchedule[index] = encodeProtoEvent(EventType.TD, contractTerms.terminationDate);
				index++;
			}
		}

		// principal redemption
		if (isInPeriod(contractTerms.maturityDate, segmentStart, segmentEnd)) {
			protoEventSchedule[index] = encodeProtoEvent(EventType.PR, contractTerms.maturityDate);
			index++;
		}

		return protoEventSchedule;
	}

	/**
	 * computes a schedule segment of cyclic contract events based on the contract terms and the specified period
	 * @param contractTerms terms of the contract
	 * @param segmentStart start timestamp of the segment
	 * @param segmentEnd end timestamp of the segement
	 * @param eventType eventType of the cyclic schedule
	 * @return event schedule segment
	 */
	function computeCyclicProtoEventScheduleSegment(
		ContractTerms memory contractTerms,
		uint256 segmentStart,
		uint256 segmentEnd,
		EventType eventType
	)
		public
		pure
		returns(bytes32[MAX_EVENT_SCHEDULE_SIZE] memory)
	{
		if (eventType == EventType.IP || eventType == EventType.IPCI) {
			bytes32[MAX_EVENT_SCHEDULE_SIZE] memory protoEventSchedule;
			uint256 index = 0;

			// interest payment related (e.g. for reoccurring interest payments)
			if (contractTerms.nominalInterestRate != 0 && (
				contractTerms.cycleOfInterestPayment.isSet == true && contractTerms.cycleAnchorDateOfInterestPayment != 0)
			) {
				uint256[MAX_CYCLE_SIZE] memory interestPaymentSchedule = computeDatesFromCycleSegment(
					contractTerms.cycleAnchorDateOfInterestPayment,
					contractTerms.maturityDate,
					contractTerms.cycleOfInterestPayment,
					contractTerms.endOfMonthConvention,
					true,
					segmentStart,
					segmentEnd
				);
				if (contractTerms.capitalizationEndDate != 0) {
					uint256 shiftedIPCITime = shiftEventTime(
						contractTerms.capitalizationEndDate,
						contractTerms.businessDayConvention,
						contractTerms.calendar
					);
					if (isInPeriod(shiftedIPCITime, segmentStart, segmentEnd)) {
						protoEventSchedule[index] = encodeProtoEvent(EventType.IPCI, contractTerms.capitalizationEndDate);
						index++;
					}
				}
				for (uint8 i = 0; i < MAX_CYCLE_SIZE; i++) {
					if (interestPaymentSchedule[i] == 0) break;
					uint256 shiftedIPDate = shiftEventTime(
						interestPaymentSchedule[i],
						contractTerms.businessDayConvention,
						contractTerms.calendar
					);
					if (isInPeriod(shiftedIPDate, segmentStart, segmentEnd) == false) continue;
					if (
						contractTerms.capitalizationEndDate != 0 &&
						interestPaymentSchedule[i] <= contractTerms.capitalizationEndDate
					) {
						if (interestPaymentSchedule[i] == contractTerms.capitalizationEndDate) continue;
						protoEventSchedule[index] = encodeProtoEvent(EventType.IPCI, interestPaymentSchedule[i]);
						index++;
					} else {
						protoEventSchedule[index] = encodeProtoEvent(EventType.IP, interestPaymentSchedule[i]);
						index++;
					}
				}
			}

			// capitalization end date
			if (contractTerms.capitalizationEndDate != 0) {
				uint256 shiftedIPCIDate = shiftEventTime(
					contractTerms.capitalizationEndDate,
					contractTerms.businessDayConvention,
					contractTerms.calendar
				);
				if (isInPeriod(shiftedIPCIDate, segmentStart, segmentEnd)) {
					protoEventSchedule[index] = encodeProtoEvent(EventType.IPCI, contractTerms.capitalizationEndDate);
					index++;
				}
			}

			return protoEventSchedule;
		} else if (eventType == EventType.RR) {
			bytes32[MAX_EVENT_SCHEDULE_SIZE] memory protoEventSchedule;
			uint256 index = 0;

			// rate reset
			if (contractTerms.cycleOfRateReset.isSet == true && contractTerms.cycleAnchorDateOfRateReset != 0) {
				uint256[MAX_CYCLE_SIZE] memory rateResetSchedule = computeDatesFromCycleSegment(
					contractTerms.cycleAnchorDateOfRateReset,
					contractTerms.maturityDate,
					contractTerms.cycleOfRateReset,
					contractTerms.endOfMonthConvention,
					false,
					segmentStart,
					segmentEnd
				);
				for (uint8 i = 0; i < MAX_CYCLE_SIZE; i++) {
					if (rateResetSchedule[i] == 0) break;
					uint256 shiftedRRDate = shiftEventTime(
						rateResetSchedule[i],
						contractTerms.businessDayConvention,
						contractTerms.calendar
					);
					if (isInPeriod(shiftedRRDate, segmentStart, segmentEnd) == false) continue;
					protoEventSchedule[index] = encodeProtoEvent(EventType.RR, rateResetSchedule[i]);
					index++;
				}
			}
			// ... nextRateReset

			return protoEventSchedule;
		} else if (eventType == EventType.FP) {
			bytes32[MAX_EVENT_SCHEDULE_SIZE] memory protoEventSchedule;
			uint256 index = 0;

			// fees
			if (contractTerms.cycleOfFee.isSet == true && contractTerms.cycleAnchorDateOfFee != 0) {
				uint256[MAX_CYCLE_SIZE] memory feeSchedule = computeDatesFromCycleSegment(
					contractTerms.cycleAnchorDateOfFee,
					contractTerms.maturityDate,
					contractTerms.cycleOfFee,
					contractTerms.endOfMonthConvention,
					true,
					segmentStart,
					segmentEnd
				);
				for (uint8 i = 0; i < MAX_CYCLE_SIZE; i++) {
					if (feeSchedule[i] == 0) break;
					uint256 shiftedFPDate = shiftEventTime(
						feeSchedule[i],
						contractTerms.businessDayConvention,
						contractTerms.calendar
					);
					if (isInPeriod(shiftedFPDate, segmentStart, segmentEnd) == false) continue;
					protoEventSchedule[index] = encodeProtoEvent(EventType.FP, feeSchedule[i]);
					index++;
				}
			}

			return protoEventSchedule;
		} else if (eventType == EventType.SC) {
			bytes32[MAX_EVENT_SCHEDULE_SIZE] memory protoEventSchedule;
			uint256 index;

			// scaling
			if ((contractTerms.scalingEffect != ScalingEffect._000 || contractTerms.scalingEffect != ScalingEffect._00M)
				&& contractTerms.cycleAnchorDateOfScalingIndex != 0
			) {
				uint256[MAX_CYCLE_SIZE] memory scalingSchedule = computeDatesFromCycleSegment(
					contractTerms.cycleAnchorDateOfScalingIndex,
					contractTerms.maturityDate,
					contractTerms.cycleOfScalingIndex,
					contractTerms.endOfMonthConvention,
					true,
					segmentStart,
					segmentEnd
				);
				for (uint8 i = 0; i < MAX_CYCLE_SIZE; i++) {
					if (scalingSchedule[i] == 0) break;
					uint256 shiftedSCDate = shiftEventTime(
						scalingSchedule[i],
						contractTerms.businessDayConvention,
						contractTerms.calendar
					);
					if (isInPeriod(shiftedSCDate, segmentStart, segmentEnd) == false) continue;
					protoEventSchedule[index] = encodeProtoEvent(EventType.SC, scalingSchedule[i]);
					index++;
				}
			}

			return protoEventSchedule;
		}

		revert("PAMEngine.computeCyclicProtoEventScheduleSegment: UNKNOWN_CYCLIC_EVENT_TYPE");
	}

	/**
	 * computes the next contract state based on the contract terms, state and the event type
	 * @param protoEvent proto event for which to evaluate the next state for
	 * @param contractState current state of the contract
	 * @param contractTerms terms of the contract
	 * @param currentTimestamp current timestamp
	 * @return next contract state
	 */
	function stateTransitionFunction(
		bytes32 protoEvent,
		ContractState memory contractState,
		ContractTerms memory contractTerms,
		uint256 currentTimestamp
	)
		private
		pure
		returns (ContractState memory)
	{
		(EventType eventType, uint256 scheduleTime) = decodeProtoEvent(protoEvent);

		if (eventType == EventType.AD) return STF_PAM_AD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.CD) return STF_PAM_CD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.FP) return STF_PAM_FP(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.IED) return STF_PAM_IED(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.IPCI) return STF_PAM_IPCI(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.IP) return STF_PAM_IP(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PP) return STF_PAM_PP(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PRD) return STF_PAM_PRD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PR) return STF_PAM_PR(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PY) return STF_PAM_PY(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.RRF) return STF_PAM_RRF(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.RR) return STF_PAM_RR(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.SC) return STF_PAM_SC(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.TD) return STF_PAM_TD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.DEL)  return STF_PAM_DEL(scheduleTime, contractTerms, contractState, currentTimestamp);

		revert("PAMEngine.stateTransitionFunction: ATTRIBUTE_NOT_FOUND");
	}

	/**
	 * calculates the payoff for the current time based on the contract terms,
	 * state and the event type
	 * @param protoEvent proto event for which to evaluate the payoff for
	 * @param contractState current state of the contract
	 * @param contractTerms terms of the contract
	 * @param currentTimestamp current timestamp
	 * @return payoff
	 */
	function payoffFunction(
		bytes32 protoEvent,
		ContractState memory contractState,
		ContractTerms memory contractTerms,
		uint256 currentTimestamp
	)
		private
		pure
		returns (int256)
	{
		(EventType eventType, uint256 scheduleTime) = decodeProtoEvent(protoEvent);

		if (eventType == EventType.AD) return 0;
		if (eventType == EventType.CD) return 0;
		if (eventType == EventType.IPCI) return 0;
		if (eventType == EventType.RRF) return 0;
		if (eventType == EventType.RR) return 0;
		if (eventType == EventType.SC) return 0;
		if (eventType == EventType.DEL) return 0;
		if (eventType == EventType.FP) return POF_PAM_FP(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.IED) return POF_PAM_IED(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.IP) return POF_PAM_IP(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PP) return POF_PAM_PP(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PRD) return POF_PAM_PRD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PR) return POF_PAM_PR(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PY) return POF_PAM_PY(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.TD) return POF_PAM_TD(scheduleTime, contractTerms, contractState, currentTimestamp);

		revert("PAMEngine.payoffFunction: ATTRIBUTE_NOT_FOUND");
	}
}
