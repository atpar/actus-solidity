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
	 * @param terms terms of the contract
	 * @return initial contract state
	 */
	function computeInitialState(LifecycleTerms memory terms)
		public
		pure
		returns (State memory)
	{
		State memory state;

		state.contractPerformance = ContractPerformance.PF;
		state.notionalScalingMultiplier = int256(1 * 10 ** PRECISION);
		state.interestScalingMultiplier = int256(1 * 10 ** PRECISION);
		state.statusDate = terms.statusDate;
		state.maturityDate = terms.maturityDate;
		state.notionalPrincipal = roleSign(terms.contractRole) * terms.notionalPrincipal;
		state.nominalInterestRate = terms.nominalInterestRate;
		state.accruedInterest = roleSign(terms.contractRole) * terms.accruedInterest;
		state.feeAccrued = terms.feeAccrued;
		// annuity calculator to be implemented
		state.nextPrincipalRedemptionPayment = roleSign(terms.contractRole) * terms.nextPrincipalRedemptionPayment;

		return state;
	}

	/**
	 * applys a prototype event to the current state of a contract and
	 * returns the contrat event and the new contract state
	 * @param terms terms of the contract
	 * @param state current state of the contract
	 * @param _event prototype event to be evaluated and applied to the contract state
	 * @param externalData external data needed for POF evaluation
	 * @return the new contract state and the evaluated event
	 */
	function computeStateForEvent(
		LifecycleTerms memory terms,
		State memory state,
		bytes32 _event,
		bytes32 externalData
	)
		public
		pure
		returns (State memory)
	{
		return stateTransitionFunction(
			_event,
			state,
			terms,
			externalData
		);
	}

	/**
	 * applys a prototype event to the current state of a contract and
	 * returns the contrat event and the new contract state
	 * @param terms terms of the contract
	 * @param state current state of the contract
	 * @param _event prototype event to be evaluated and applied to the contract state
	 * @param externalData external data needed for POF evaluation
	 * @return the new contract state and the evaluated event
	 */
	function computePayoffForEvent(
		LifecycleTerms memory terms,
		State memory state,
		bytes32 _event,
		bytes32 externalData
	)
		public
		pure
		returns (int256)
	{
		return payoffFunction(
			_event,
			state,
			terms,
			externalData
		);
	}

	/**
	 * computes a schedule segment of non-cyclic contract events based on the contract terms and the specified period
	 * TODO: add missing contract features:
	 * - rate reset
	 * - scaling
	 * - interest calculation base
	 * @param terms terms of the contract
	 * @param segmentStart start timestamp of the segment
	 * @param segmentEnd end timestamp of the segement
	 * @return event schedule segment
	 */
	function computeNonCyclicScheduleSegment(
		GeneratingTerms memory terms,
		uint256 segmentStart,
		uint256 segmentEnd
	)
		public
		pure
		returns (bytes32[MAX_EVENT_SCHEDULE_SIZE] memory)
	{
		bytes32[MAX_EVENT_SCHEDULE_SIZE] memory _eventSchedule;
		uint16 index = 0;

		// initial exchange
		if (isInPeriod(terms.initialExchangeDate, segmentStart, segmentEnd)) {
			_eventSchedule[index] = encodeEvent(EventType.IED, terms.initialExchangeDate);
			index++;
		}

		// purchase
		if (terms.purchaseDate != 0) {
			if (isInPeriod(terms.purchaseDate, segmentStart, segmentEnd)) {
				_eventSchedule[index] = encodeEvent(EventType.PRD, terms.purchaseDate);
				index++;
			}
		}

		// termination
		if (terms.terminationDate != 0) {
			if (isInPeriod(terms.terminationDate, segmentStart, segmentEnd)) {
				_eventSchedule[index] = encodeEvent(EventType.TD, terms.terminationDate);
				index++;
			}
		}

		// principal redemption at maturity
		if (isInPeriod(terms.maturityDate, segmentStart, segmentEnd) == true)  {
			_eventSchedule[index] = encodeEvent(EventType.MD, terms.maturityDate);
			index++;
			_eventSchedule[index] = encodeEvent(EventType.IP, terms.maturityDate);
			index++;
		}

		return _eventSchedule;
	}

	/**
	 * computes a schedule segment of cyclic contract events based on the contract terms and the specified period
	 * @param terms terms of the contract
	 * @param segmentStart start timestamp of the segment
	 * @param segmentEnd end timestamp of the segement
	 * @param eventType eventType of the cyclic schedule
	 * @return event schedule segment
	 */
	function computeCyclicScheduleSegment(
		GeneratingTerms memory terms,
		uint256 segmentStart,
		uint256 segmentEnd,
		EventType eventType
	)
		public
		pure
		returns (bytes32[MAX_EVENT_SCHEDULE_SIZE] memory)
	{
		bytes32[MAX_EVENT_SCHEDULE_SIZE] memory _eventSchedule;

		if (eventType == EventType.IP || eventType == EventType.IPCI) {
			uint256 index = 0;

			// interest payment related (covers pre-repayment period only,
			// starting with PRANX interest is paid following the PR schedule)
			if (terms.cycleOfInterestPayment.isSet == true &&
				terms.cycleAnchorDateOfInterestPayment != 0 &&
				terms.cycleAnchorDateOfInterestPayment < terms.cycleAnchorDateOfPrincipalRedemption)
				{
				uint256[MAX_CYCLE_SIZE] memory interestPaymentSchedule = computeDatesFromCycleSegment(
					terms.cycleAnchorDateOfInterestPayment,
					terms.cycleAnchorDateOfPrincipalRedemption, // pure IP schedule ends at beginning of combined IP/PR schedule
					terms.cycleOfInterestPayment,
					false, // do not create an event for cycleAnchorDateOfPrincipalRedemption as covered with the PR schedule
					segmentStart,
					segmentEnd
				);
				for (uint8 i = 0; i < MAX_CYCLE_SIZE; i++) {
					if (interestPaymentSchedule[i] == 0) break;
					if (isInPeriod(interestPaymentSchedule[i], segmentStart, segmentEnd) == false) continue;
					if (
						terms.capitalizationEndDate != 0 &&
						interestPaymentSchedule[i] <= terms.capitalizationEndDate
					) {
						if (interestPaymentSchedule[i] == terms.capitalizationEndDate) continue;
						_eventSchedule[index] = encodeEvent(EventType.IPCI, interestPaymentSchedule[i]);
						index++;
					} else {
						_eventSchedule[index] = encodeEvent(EventType.IP, interestPaymentSchedule[i]);
						index++;
					}
				}
			}
			// capitalization end date
			if (
				terms.capitalizationEndDate != 0 &&
				terms.capitalizationEndDate < terms.cycleAnchorDateOfPrincipalRedemption
			) {
				if (isInPeriod(terms.capitalizationEndDate, segmentStart, segmentEnd)) {
					_eventSchedule[index] = encodeEvent(EventType.IPCI, terms.capitalizationEndDate);
					index++;
				}
			}
		}

		if (eventType == EventType.FP) {
			uint256 index = 0;

			// fees
			if (terms.cycleOfFee.isSet == true && terms.cycleAnchorDateOfFee != 0) {
				uint256[MAX_CYCLE_SIZE] memory feeSchedule = computeDatesFromCycleSegment(
					terms.cycleAnchorDateOfFee,
					terms.maturityDate,
					terms.cycleOfFee,
					true,
					segmentStart,
					segmentEnd
				);
				for (uint8 i = 0; i < MAX_CYCLE_SIZE; i++) {
					if (feeSchedule[i] == 0) break;
					if (isInPeriod(feeSchedule[i], segmentStart, segmentEnd) == false) continue;
					_eventSchedule[index] = encodeEvent(EventType.FP, feeSchedule[i]);
					index++;
				}
			}
		}

		if (eventType == EventType.PR) {
			uint256 index = 0;

			// principal redemption related (covers also interest events post PRANX)
			uint256[MAX_CYCLE_SIZE] memory principalRedemptionSchedule = computeDatesFromCycleSegment(
				terms.cycleAnchorDateOfPrincipalRedemption,
				terms.maturityDate,
				terms.cycleOfPrincipalRedemption,
				false,
				segmentStart,
				segmentEnd
			);
			for (uint8 i = 0; i < MAX_CYCLE_SIZE; i++) {
				if (principalRedemptionSchedule[i] == 0) break;
				if (isInPeriod(principalRedemptionSchedule[i], segmentStart, segmentEnd) == false) continue;
				_eventSchedule[index] = encodeEvent(EventType.PR, principalRedemptionSchedule[i]);
				index++;
				_eventSchedule[index] = encodeEvent(EventType.IP, principalRedemptionSchedule[i]);
				index++;
			}
		}

		return _eventSchedule;
	}

	function isEventScheduled(
		bytes32 _event,
		LifecycleTerms memory terms,
		State memory state,
		bool hasUnderlying,
		State memory underlyingState
	)
		public
		pure
		returns (bool)
	{
		return true;
	}

	/**
	 * computes the next contract state based on the contract terms, state and the event type
	 * TODO:
	 * - annuity calculator for RR/RRF events
	 * - IPCB events and Icb state variable
	 * - Icb state variable updates in Nac-updating events
	 * @param _event proto event for which to evaluate the next state for
	 * @param state current state of the contract
	 * @param terms terms of the contract
	 * @param externalData external data needed for POF evaluation
	 * @return next contract state
	 */
	function stateTransitionFunction(
		bytes32 _event,
		State memory state,
		LifecycleTerms memory terms,
		bytes32 externalData
	)
		private
		pure
		returns (State memory)
	{
		(EventType eventType, uint256 scheduleTime) = decodeEvent(_event);

		if (eventType == EventType.AD) return STF_PAM_AD(scheduleTime, terms, state, externalData);
		if (eventType == EventType.CD) return STF_PAM_CD(scheduleTime, terms, state, externalData);
		if (eventType == EventType.FP) return STF_PAM_FP(scheduleTime, terms, state, externalData);
		if (eventType == EventType.IED) return STF_ANN_IED(scheduleTime, terms, state, externalData);
		if (eventType == EventType.IPCI) return STF_ANN_IPCI(scheduleTime, terms, state, externalData);
		if (eventType == EventType.IP) return STF_ANN_IP(scheduleTime, terms, state, externalData);
		if (eventType == EventType.PP) return STF_PAM_PP(scheduleTime, terms, state, externalData);
		if (eventType == EventType.PRD) return STF_PAM_PRD(scheduleTime, terms, state, externalData);
		if (eventType == EventType.PR) return STF_ANN_PR(scheduleTime, terms, state, externalData);
		if (eventType == EventType.MD) return STF_ANN_MD(scheduleTime, terms, state, externalData);
		if (eventType == EventType.PY) return STF_PAM_PY(scheduleTime, terms, state, externalData);
		if (eventType == EventType.RRF) return STF_PAM_RRF(scheduleTime, terms, state, externalData);
		if (eventType == EventType.RR) return STF_ANN_RR(scheduleTime, terms, state, externalData);
		if (eventType == EventType.SC) return STF_ANN_SC(scheduleTime, terms, state, externalData);
		if (eventType == EventType.TD) return STF_PAM_TD(scheduleTime, terms, state, externalData);
		if (eventType == EventType.CE) return STF_PAM_DEL(scheduleTime, terms, state, externalData);

		revert("ANNEngine.stateTransitionFunction: ATTRIBUTE_NOT_FOUND");
	}

	/**
	 * calculates the payoff for the current time based on the contract terms,
	 * state and the event type
	 * - IPCB events and Icb state variable
	 * - Icb state variable updates in IP-paying events
	 * @param _event proto event for which to evaluate the payoff for
	 * @param state current state of the contract
	 * @param terms terms of the contract
	 * @param externalData external data needed for POF evaluation
	 * @return payoff
	 */
	function payoffFunction(
		bytes32 _event,
		State memory state,
		LifecycleTerms memory terms,
		bytes32 externalData
	)
		private
		pure
		returns (int256)
	{
		(EventType eventType, uint256 scheduleTime) = decodeEvent(_event);

		if (eventType == EventType.AD) return 0;
		if (eventType == EventType.CD) return 0;
		if (eventType == EventType.IPCI) return 0;
		if (eventType == EventType.RRF) return 0;
		if (eventType == EventType.RR) return 0;
		if (eventType == EventType.SC) return 0;
		if (eventType == EventType.CE) return 0;
		if (eventType == EventType.FP) return POF_ANN_FP(scheduleTime, terms, state, externalData);
		if (eventType == EventType.IED) return POF_PAM_IED(scheduleTime, terms, state, externalData);
		if (eventType == EventType.IP) return POF_PAM_IP(scheduleTime, terms, state, externalData);
		if (eventType == EventType.PP) return POF_PAM_PP(scheduleTime, terms, state, externalData);
		if (eventType == EventType.PRD) return POF_PAM_PRD(scheduleTime, terms, state, externalData);
		if (eventType == EventType.PR) return POF_ANN_PR(scheduleTime, terms, state, externalData);
		if (eventType == EventType.MD) return POF_ANN_MD(scheduleTime, terms, state, externalData);
		if (eventType == EventType.PY) return POF_PAM_PY(scheduleTime, terms, state, externalData);
		if (eventType == EventType.TD) return POF_PAM_TD(scheduleTime, terms, state, externalData);

		revert("ANNEngine.payoffFunction: ATTRIBUTE_NOT_FOUND");
	}
}