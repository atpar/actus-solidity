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
			payoffFunction(protoEvent, contractState, contractTerms, currentTimestamp), // solium-disable-line
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
	 * TODO: add missing contract features:
	 * - rate reset
	 * - scaling
	 * - interest calculation base
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

		// interest payment related (covers pre-repayment period only,
		//    starting with PRANX interest is paid following the PR schedule)
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
		else if (
			contractTerms.capitalizationEndDate != 0 &&
			contractTerms.capitalizationEndDate < contractTerms.cycleAnchorDateOfPrincipalRedemption
		) {
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
			protoEventSchedule[index] = ProtoEvent(
				shiftedPRDate,
				shiftedPRDate.add(getEpochOffset(EventType.PR)),
				principalRedemptionSchedule[i],
				EventType.PR,
				contractTerms.currency,
				EventType.PR,
				EventType.PR
			);
			index++;
			protoEventSchedule[index] = ProtoEvent(
				shiftedPRDate,
				shiftedPRDate.add(getEpochOffset(EventType.IP)),
				principalRedemptionSchedule[i],
				EventType.IP,
				contractTerms.currency,
				EventType.IP,
				EventType.IP
			);
			index++;
		}

		// principal redemption at maturity
		if (isInPeriod(contractTerms.maturityDate, segmentStart, segmentEnd) == true) {
			protoEventSchedule[index] = ProtoEvent(
				contractTerms.maturityDate,
				contractTerms.maturityDate.add(getEpochOffset(EventType.PR)),
				contractTerms.maturityDate,
				EventType.MD,
				contractTerms.currency,
				EventType.MD,
				EventType.MD
			);
			index++;
			protoEventSchedule[index] = ProtoEvent(
				contractTerms.maturityDate,
				contractTerms.maturityDate.add(getEpochOffset(EventType.IP)),
				contractTerms.maturityDate,
				EventType.IP,
				contractTerms.currency,
				EventType.IP,
				EventType.IP
			);
			index++;
		}

		sortProtoEventSchedule(protoEventSchedule, index);

		return protoEventSchedule;
	}

	/**
	 * initialize contract state space based on the contract terms
	 * TODO:
	 * - implement annuity calculator
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
		contractState.nominalValue = roleSign(contractTerms.contractRole) * contractTerms.notionalPrincipal;
		contractState.nominalRate = contractTerms.nominalInterestRate;
		contractState.nominalAccrued = roleSign(contractTerms.contractRole) * contractTerms.accruedInterest;
		contractState.feeAccrued = contractTerms.feeAccrued;
		// annuity calculator to be implemented
		contractState.nextPrincipalRedemptionPayment = roleSign(contractTerms.contractRole) * contractTerms.nextPrincipalRedemptionPayment;

		return contractState;
	}

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
		ProtoEvent memory protoEvent,
		ContractState memory contractState,
		ContractTerms memory contractTerms,
		uint256 currentTimestamp
	)
		private
		pure
		returns (ContractState memory)
	{
		if (protoEvent.eventType == EventType.AD) return STF_ANN_AD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.CD) return STF_ANN_CD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.FP) return STF_ANN_FP(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.IED) return STF_ANN_IED(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.IPCI) return STF_ANN_IPCI(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.IP) return STF_ANN_IP(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PP) return STF_ANN_PP(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PRD) return STF_ANN_PRD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PR) return STF_ANN_PR(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.MD) return STF_ANN_MD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PY) return STF_ANN_PY(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.RRF) return STF_ANN_RRF(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.RR) return STF_ANN_RR(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.SC) return STF_ANN_SC(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.TD) return STF_ANN_TD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.DEL) return STF_ANN_DEL(protoEvent, contractTerms, contractState, currentTimestamp);

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
		ProtoEvent memory protoEvent,
		ContractState memory contractState,
		ContractTerms memory contractTerms,
		uint256 currentTimestamp
	)
		private
		pure
		returns (int256)
	{
		if (protoEvent.eventType == EventType.AD) return POF_ANN_AD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.CD) return POF_ANN_CD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.IPCI) return POF_ANN_IPCI(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.RRF) return POF_ANN_RRF(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.RR) return POF_ANN_RR(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.SC) return POF_ANN_SC(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.FP) return POF_ANN_FP(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.IED) return POF_ANN_IED(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.IP) return POF_ANN_IP(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PP) return POF_ANN_PP(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PRD) return POF_ANN_PRD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PR) return POF_ANN_PR(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.MD) return POF_ANN_MD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.PY) return POF_ANN_PY(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.TD) return POF_ANN_TD(protoEvent, contractTerms, contractState, currentTimestamp);
		if (protoEvent.eventType == EventType.DEL) return POF_ANN_DEL(protoEvent, contractTerms, contractState, currentTimestamp);

		revert("ANNEngine.payoffFunction: ATTRIBUTE_NOT_FOUND");
	}
}
