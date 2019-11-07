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
 * @title the stateless component for a ANN contract
 * implements the STF and POF of the Actus standard for a ANN contract
 * @dev all numbers except unix timestamp are represented as multiple of 10 ** 18
 * inputs have to be multiplied by 10 ** 18, outputs have to divided by 10 ** 18
 */
contract ANNEngine is Core, IEngine, STF, POF {

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
		contractState.notionalScalingMultiplier = int256(1 * 10 ** PRECISION);
		contractState.interestScalingMultiplier = int256(1 * 10 ** PRECISION);
		contractState.lastEventTime = contractTerms.statusDate;
		contractState.notionalPrincipal = roleSign(contractTerms.contractRole) * contractTerms.notionalPrincipal;
		contractState.nominalInterestRate = contractTerms.nominalInterestRate;
		contractState.accruedInterest = roleSign(contractTerms.contractRole) * contractTerms.accruedInterest;
		contractState.feeAccrued = contractTerms.feeAccrued;
		// annuity calculator to be implemented
		contractState.nextPrincipalRedemptionPayment = roleSign(contractTerms.contractRole) * contractTerms.nextPrincipalRedemptionPayment;

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
	 * TODO: add missing contract features:
	 * - rate reset
	 * - scaling
	 * - interest calculation base
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

		// principal redemption at maturity
		if (isInPeriod(contractTerms.maturityDate, segmentStart, segmentEnd) == true)  {
			protoEventSchedule[index] = encodeProtoEvent(EventType.MD, contractTerms.maturityDate);
			index++;
			protoEventSchedule[index] = encodeProtoEvent(EventType.IP, contractTerms.maturityDate);
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
		if (eventType == EventType.IP || eventType == EventType.IPCI) {
			bytes32[MAX_EVENT_SCHEDULE_SIZE] memory protoEventSchedule;
			uint256 index = 0;

			// interest payment related (covers pre-repayment period only,
			// starting with PRANX interest is paid following the PR schedule)
			if (contractTerms.cycleOfInterestPayment.isSet == true &&
				contractTerms.cycleAnchorDateOfInterestPayment != 0 &&
				contractTerms.cycleAnchorDateOfInterestPayment < contractTerms.cycleAnchorDateOfPrincipalRedemption)
				{
				uint256[MAX_CYCLE_SIZE] memory interestPaymentSchedule = computeDatesFromCycleSegment(
					contractTerms.cycleAnchorDateOfInterestPayment,
					contractTerms.cycleAnchorDateOfPrincipalRedemption, // pure IP schedule ends at beginning of combined IP/PR schedule
					contractTerms.cycleOfInterestPayment,
					contractTerms.endOfMonthConvention,
					false, // do not create an event for cycleAnchorDateOfPrincipalRedemption as covered with the PR schedule
					segmentStart,
					segmentEnd
				);
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
			if (
				contractTerms.capitalizationEndDate != 0 &&
				contractTerms.capitalizationEndDate < contractTerms.cycleAnchorDateOfPrincipalRedemption
			) {
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
		}

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

		if (eventType == EventType.PR) {
			bytes32[MAX_EVENT_SCHEDULE_SIZE] memory protoEventSchedule;
			uint256 index = 0;

			// principal redemption related (covers also interest events post PRANX)
			uint256[MAX_CYCLE_SIZE] memory principalRedemptionSchedule = computeDatesFromCycleSegment(
				contractTerms.cycleAnchorDateOfPrincipalRedemption,
				contractTerms.maturityDate,
				contractTerms.cycleOfPrincipalRedemption,
				contractTerms.endOfMonthConvention,
				false,
				segmentStart,
				segmentEnd
			);
			for (uint8 i = 0; i < MAX_CYCLE_SIZE; i++) {
				if (principalRedemptionSchedule[i] == 0) break;
				uint256 shiftedPRDate = shiftEventTime(
					principalRedemptionSchedule[i],
					contractTerms.businessDayConvention,
					contractTerms.calendar
				);
				if (isInPeriod(shiftedPRDate, segmentStart, segmentEnd) == false) continue;
				protoEventSchedule[index] = encodeProtoEvent(EventType.PR, principalRedemptionSchedule[i]);
				index++;
				protoEventSchedule[index] = encodeProtoEvent(EventType.IP, principalRedemptionSchedule[i]);
				index++;
			}

			return protoEventSchedule;
		}

		revert("ANNEngine.computeCyclicProtoEventScheduleSegment: UNKNOWN_CYCLIC_EVENT_TYPE");
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

		if (eventType == EventType.AD) return STF_PAM_AD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.CD) return STF_PAM_CD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.FP) return STF_PAM_FP(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.IED) return STF_ANN_IED(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.IPCI) return STF_ANN_IPCI(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.IP) return STF_ANN_IP(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PP) return STF_PAM_PP(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PRD) return STF_PAM_PRD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PR) return STF_ANN_PR(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.MD) return STF_ANN_MD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PY) return STF_PAM_PY(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.RRF) return STF_PAM_RRF(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.RR) return STF_ANN_RR(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.SC) return STF_ANN_SC(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.TD) return STF_PAM_TD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.DEL) return STF_PAM_DEL(scheduleTime, contractTerms, contractState, currentTimestamp);

		revert("ANNEngine.stateTransitionFunction: ATTRIBUTE_NOT_FOUND");
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

		if (eventType == EventType.AD) return 0;
		if (eventType == EventType.CD) return 0;
		if (eventType == EventType.IPCI) return 0;
		if (eventType == EventType.RRF) return 0;
		if (eventType == EventType.RR) return 0;
		if (eventType == EventType.SC) return 0;
		if (eventType == EventType.DEL) return 0;
		if (eventType == EventType.FP) return POF_ANN_FP(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.IED) return POF_PAM_IED(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.IP) return POF_PAM_IP(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PP) return POF_PAM_PP(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PRD) return POF_PAM_PRD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PR) return POF_ANN_PR(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.MD) return POF_ANN_MD(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.PY) return POF_PAM_PY(scheduleTime, contractTerms, contractState, currentTimestamp);
		if (eventType == EventType.TD) return POF_PAM_TD(scheduleTime, contractTerms, contractState, currentTimestamp);

		revert("ANNEngine.payoffFunction: ATTRIBUTE_NOT_FOUND");
	}
}