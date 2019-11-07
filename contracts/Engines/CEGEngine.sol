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
 * @title the stateless component for a CEG contract
 * implements the STF and POF of the Actus standard for a CEG contract
 * @dev all numbers except unix timestamp are represented as multiple of 10 ** 18
 * inputs have to be multiplied by 10 ** 18, outputs have to divided by 10 ** 18
 */
contract CEGEngine is Core, IEngine, STF, POF {

	using SafeMath for uint;
	using SignedSafeMath for int;
	using SignedMath for int;


	/**
	 * initialize contract state space based on the contract terms
	 * TODO:
	 * - implement annuity calculator
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
		contractState.lastEventTime = contractTerms.statusDate;
		contractState.notionalPrincipal = roleSign(contractTerms.contractRole) * contractTerms.notionalPrincipal;
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
	function computeNonCylicProtoEventScheduleSegment(
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

		// purchase
		if (contractTerms.purchaseDate != 0) {
			if (isInPeriod(contractTerms.purchaseDate, segmentStart, segmentEnd)) {
				protoEventSchedule[index] = encodeProtoEvent(EventType.PRD, contractTerms.purchaseDate);
				index++;
			}
		}

		// maturity event
		if (isInPeriod(contractTerms.maturityDate, segmentStart, segmentEnd) == true) {
			protoEventSchedule[index] = encodeProtoEvent(EventType.MD, contractTerms.maturityDate);
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
		returns (bytes32[MAX_EVENT_SCHEDULE_SIZE] memory)
	{
		if (eventType == EventType.FP) {
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
		}

		revert("CEGEngine.computeCyclicProtoEventScheduleSegment: UNKNOWN_CYCLIC_EVENT_TYPE");
	}

	// function applyProtoEventsToProtoEventSchedule(
	// 	ProtoEvent[MAX_EVENT_SCHEDULE_SIZE] memory protoEventSchedule,
	// 	ProtoEvent[MAX_EVENT_SCHEDULE_SIZE] memory protoEvents
	// )
	// 	public
	// 	pure
	// 	returns (ProtoEvent[MAX_EVENT_SCHEDULE_SIZE] memory)
	// {
	// 	// for loop can be removed after reimplementation of sortProtoEventSchedule
	// 	// check if protoEventSchedule[MAX_EVENT_SCHEDULE_SIZE - numberOfProtoEvents].scheduleTime == 0 is sufficient
	// 	uint256 index = 0;
	// 	for (uint256 j = 0; index < MAX_EVENT_SCHEDULE_SIZE; index++) {
	// 		if (protoEvents[j].eventTime == 0) {
	// 			if (j != 0) break;
	// 			return protoEventSchedule;
	// 		}
	// 		if (protoEventSchedule[index].eventTime == 0) {
	// 			protoEventSchedule[index] = protoEvents[j];
	// 			j++;
	// 		}
	// 	}
	// 	sortProtoEventSchedule(protoEventSchedule, index);

	// 	// CEGEngine specific schedule rules

	// 	bool afterExecutionDate = false;
	// 	for (uint256 i = 1; i < MAX_EVENT_SCHEDULE_SIZE; i++) {
	// 		if (protoEventSchedule[i - 1].eventTime == 0) {
	// 			delete protoEventSchedule[i];
	// 			continue;
	// 		}
	// 		if (
	// 			afterExecutionDate == false
	// 			&& protoEventSchedule[i].eventType == EventType.XD
	// 		) {
	// 			afterExecutionDate = true;
	// 		}
	// 		// remove all FP events after execution date
	// 		if (
	// 			afterExecutionDate == true
	// 			&& protoEventSchedule[i].eventType == EventType.FP
	// 		) {
	// 			delete protoEventSchedule[i];
	// 		}
	// 	}

	// 	return protoEventSchedule;
	// }

	/**
	 * computes the next contract state based on the contract terms, state and the event type
	 * TODO:
	 * - annuity calculator for RR/RRF events
	 * - IPCB events and Icb state variable
	 * - Icb state variable updates in Nac-updating events
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

		if (eventType == EventType.PRD) return STF_CEG_PRD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.FP) return STF_CEG_FP(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.XD) return STF_CEG_XD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.MD) return STF_CEG_MD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.DEL) return STF_PAM_DEL(scheduleTime, contractTerms, contractState, currentTimestamp);

		revert("CEGEngine.stateTransitionFunction: ATTRIBUTE_NOT_FOUND");
	}

	/**
	 * calculates the payoff for the current time based on the contract terms,
	 * state and the event type
	 * - IPCB events and Icb state variable
	 * - Icb state variable updates in IP-paying events
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

		if (eventType == EventType.DEL) return 0;
		if (eventType == EventType.PRD) return POF_CEG_PRD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.FP) return POF_CEG_FP(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.XD) return POF_CEG_XD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.MD) return POF_CEG_MD(scheduleTime, contractTerms, contractState, currentTimestamp);

		revert("CEGEngine.payoffFunction: ATTRIBUTE_NOT_FOUND");
	}
}