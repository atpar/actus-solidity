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

	using SafeMath for uint;
	using SignedSafeMath for int;
	using SignedMath for int;


	/**
	 * get the initial contract state
	 * @param contractTerms terms of the contract
	 * @return initial contract state
	 */
	function computeInitialState(ContractTerms memory contractTerms)
		public
		pure
		returns (ContractState memory)
	{
		return initializeContractState(contractTerms);
	}

	/**
	 * computes pending events based on the contract state and
	 * applys them to the contract state and returns the evaluated events and the new contract state
	 * @dev evaluates all events between the scheduled time of the last executed event and now
	 * (such that Led < Tev && now >= Tev)
	 * @param contractTerms terms of the contract
	 * @param contractState current state of the contract
	 * @param currentTimestamp current timestamp
	 * @return the new contract state and the evaluated events
	 */
	function computeNextState(
		ContractTerms memory contractTerms,
		ContractState memory contractState,
		uint256 currentTimestamp
	)
		public
		pure
		returns (ContractState memory, ContractEvent[MAX_EVENT_SCHEDULE_SIZE] memory)
	{
		ContractState memory nextContractState = contractState;
		ContractEvent[MAX_EVENT_SCHEDULE_SIZE] memory nextContractEvents;

		ProtoEvent[MAX_EVENT_SCHEDULE_SIZE] memory pendingProtoEventSchedule = computeProtoEventScheduleSegment(
			contractTerms,
			shiftEventTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
			currentTimestamp
		);

		for (uint8 index = 0; index < MAX_EVENT_SCHEDULE_SIZE; index++) {
			if (pendingProtoEventSchedule[index].eventTime == 0) continue;

			nextContractEvents[index] = ContractEvent(
				pendingProtoEventSchedule[index].eventTime,
				pendingProtoEventSchedule[index].eventType,
				pendingProtoEventSchedule[index].currency,
				payoffFunction(
					pendingProtoEventSchedule[index],
					contractState,
					contractTerms,
					currentTimestamp
				),
				currentTimestamp
			);

			nextContractState = stateTransitionFunction(
				pendingProtoEventSchedule[index],
				contractState,
				contractTerms,
				currentTimestamp
			);
		}

		return (nextContractState, nextContractEvents);
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
	function computeNextStateForProtoEvent(
		ContractTerms memory contractTerms,
		ContractState memory contractState,
		ProtoEvent memory protoEvent,
		uint256 currentTimestamp
	)
		public
		pure
		returns (ContractState memory, ContractEvent memory)
	{
		ContractEvent memory contractEvent = ContractEvent(
			protoEvent.eventTime,
			protoEvent.eventType,
			protoEvent.currency,
			payoffFunction( protoEvent, contractState, contractTerms, currentTimestamp), // solium-disable-line
			currentTimestamp
		);

		ContractState memory nextContractState = stateTransitionFunction(
			protoEvent,
			contractState,
			contractTerms,
			currentTimestamp
		);

		return (nextContractState, contractEvent);
	}

	/**
	 * computes a schedule segment of contract events based on the contract terms and the specified period
	 * @param contractTerms terms of the contract
	 * @param segmentStart start timestamp of the segment
	 * @param segmentEnd end timestamp of the segement
	 * @return event schedule segment
	 */
	function computeProtoEventScheduleSegment(
		ContractTerms memory contractTerms,
		uint256 segmentStart,
		uint256 segmentEnd
	)
		public
		pure
		returns (ProtoEvent[MAX_EVENT_SCHEDULE_SIZE] memory)
	{
		ProtoEvent[MAX_EVENT_SCHEDULE_SIZE] memory protoEventSchedule;
		uint16 index = 0;

		// initial exchange
		if (isInPeriod(contractTerms.initialExchangeDate, segmentStart, segmentEnd)) {
			protoEventSchedule[index] = ProtoEvent(
				contractTerms.initialExchangeDate,
				contractTerms.initialExchangeDate.add(getEpochOffset(EventType.IED)),
				contractTerms.initialExchangeDate,
				EventType.IED,
				contractTerms.currency,
				EventType.IED,
				EventType.IED
			);
			index++;
		}

		// purchase
		if (contractTerms.purchaseDate != 0) {
			if (isInPeriod(contractTerms.purchaseDate, segmentStart, segmentEnd)) {
				protoEventSchedule[index] = ProtoEvent(
					contractTerms.purchaseDate,
					contractTerms.purchaseDate.add(getEpochOffset(EventType.PRD)),
					contractTerms.purchaseDate,
					EventType.PRD,
					contractTerms.currency,
					EventType.PRD,
					EventType.PRD
				);
				index++;
			}
		}

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
					protoEventSchedule[index] = ProtoEvent(
						shiftedIPCITime,
						shiftedIPCITime.add(getEpochOffset(EventType.IPCI)),
						contractTerms.capitalizationEndDate,
						EventType.IPCI,
						contractTerms.currency,
						EventType.IPCI,
						EventType.IPCI
					);
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
					protoEventSchedule[index] = ProtoEvent(
						shiftedIPDate,
						shiftedIPDate.add(getEpochOffset(EventType.IPCI)),
						interestPaymentSchedule[i],
						EventType.IPCI,
						contractTerms.currency,
						EventType.IPCI,
						EventType.IPCI
					);
					index++;
				} else {
					protoEventSchedule[index] = ProtoEvent(
						shiftedIPDate,
						shiftedIPDate.add(getEpochOffset(EventType.IP)),
						interestPaymentSchedule[i],
						EventType.IP,
						contractTerms.currency,
						EventType.IP,
						EventType.IP
					);
					index++;
				}
			}
		}
		// capitalization end date
		else if (contractTerms.capitalizationEndDate != 0) {
			uint256 shiftedIPCIDate = shiftEventTime(
				contractTerms.capitalizationEndDate,
				contractTerms.businessDayConvention,
				contractTerms.calendar
			);
			if (isInPeriod(shiftedIPCIDate, segmentStart, segmentEnd)) {
				protoEventSchedule[index] = ProtoEvent(
					shiftedIPCIDate,
					shiftedIPCIDate.add(getEpochOffset(EventType.IPCI)),
					contractTerms.capitalizationEndDate,
					EventType.IPCI,
					contractTerms.currency,
					EventType.IPCI,
					EventType.IPCI
				);
				index++;
			}
		}

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
				protoEventSchedule[index] = ProtoEvent(
					shiftedRRDate,
					shiftedRRDate.add(getEpochOffset(EventType.RR)),
					rateResetSchedule[i],
					EventType.RR,
					contractTerms.currency,
					EventType.RR,
					EventType.RR
				);
				index++;
			}
			// ... nextRateReset
		}

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
				protoEventSchedule[index] = ProtoEvent(
					shiftedFPDate,
					shiftedFPDate.add(getEpochOffset(EventType.FP)),
					feeSchedule[i],
					EventType.FP,
					contractTerms.currency,
					EventType.FP,
					EventType.FP
				);
				index++;
			}
		}

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
				protoEventSchedule[index] = ProtoEvent(
					shiftedSCDate,
					shiftedSCDate.add(getEpochOffset(EventType.SC)),
					scalingSchedule[i],
					EventType.SC,
					contractTerms.currency,
					EventType.SC,
					EventType.SC
				);
				index++;
			}
		}

		// termination
		if (contractTerms.terminationDate != 0) {
			if (isInPeriod(contractTerms.terminationDate, segmentStart, segmentEnd)) {
				protoEventSchedule[index] = ProtoEvent(
					contractTerms.terminationDate,
					contractTerms.terminationDate.add(getEpochOffset(EventType.TD)),
					contractTerms.terminationDate,
					EventType.TD,
					contractTerms.currency,
					EventType.TD,
					EventType.TD
				);
				index++;
			}
		}

		// principal redemption
		if (isInPeriod(contractTerms.maturityDate, segmentStart, segmentEnd)) {
			protoEventSchedule[index] = ProtoEvent(
				contractTerms.maturityDate,
				contractTerms.maturityDate.add(getEpochOffset(EventType.PR)),
				contractTerms.maturityDate,
				EventType.PR,
				contractTerms.currency,
				EventType.PR,
				EventType.PR
			);
			index++;
		}

		sortProtoEventSchedule(protoEventSchedule, index);

		return protoEventSchedule;
	}

	/**
	 * initialize contract state space based on the contract terms
	 * @dev see initStateSpace()
	 * @param contractTerms terms of the contract
	 * @return initial contract state
	 */
	function initializeContractState(ContractTerms memory contractTerms)
		private
		pure
		returns (ContractState memory)
	{
		ContractState memory contractState;

		contractState.contractStatus = ContractStatus.PF;
		contractState.nominalScalingMultiplier = int256(1 * 10 ** PRECISION);
		contractState.interestScalingMultiplier = int256(1 * 10 ** PRECISION);
		contractState.contractRoleSign = contractTerms.contractRole;
		contractState.lastEventTime = contractTerms.statusDate;
		contractState.nominalValue = contractTerms.notionalPrincipal;
		contractState.nominalRate = contractTerms.nominalInterestRate;
		contractState.nominalAccrued = contractTerms.accruedInterest;
		contractState.feeAccrued = contractTerms.feeAccrued;

		return contractState;
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
		ProtoEvent memory protoEvent,
		ContractState memory contractState,
		ContractTerms memory contractTerms,
		uint256 currentTimestamp
	)
		private
		pure
		returns (ContractState memory)
	{
		if (protoEvent.eventType == EventType.AD) return STF.STF_PAM_AD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.CD) return STF.STF_PAM_CD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.FP) return STF.STF_PAM_FP(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.IED) return STF.STF_PAM_IED(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.IPCI) return STF.STF_PAM_IPCI(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.IP) return STF.STF_PAM_IP(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PP) return STF.STF_PAM_PP(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PRD) return STF.STF_PAM_PRD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PR) return STF.STF_PAM_PR(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PY) return STF.STF_PAM_PY(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.RRF) return STF.STF_PAM_RRF(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.RR) return STF.STF_PAM_RR(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.SC) return STF.STF_PAM_SC(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.TD) return STF.STF_PAM_TD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.DEL) return STF.STF_PAM_DEL(protoEvent, contractTerms, contractState, currentTimestamp);

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
		ProtoEvent memory protoEvent,
		ContractState memory contractState,
		ContractTerms memory contractTerms,
		uint256 currentTimestamp
	)
		private
		pure
		returns (int256)
	{
		if (protoEvent.eventType == EventType.AD) return POF_PAM_AD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.CD) return POF_PAM_CD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.IPCI) return POF_PAM_IPCI(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.RRF) return POF_PAM_RRF(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.RR) return POF_PAM_RR(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.SC) return POF_PAM_SC(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.FP) return POF_PAM_FP(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.IED) return POF_PAM_IED(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.IP) return POF_PAM_IP(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PP) return POF_PAM_PP(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PRD) return POF_PAM_PRD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PR) return POF_PAM_PR(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PY) return POF_PAM_PY(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.TD) return POF_PAM_TD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.DEL) return POF_PAM_DEL(protoEvent, contractTerms, contractState, currentTimestamp);

		revert("PAMEngine.payoffFunction: ATTRIBUTE_NOT_FOUND");
	}
}
