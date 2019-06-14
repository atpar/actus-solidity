pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/drafts/SignedSafeMath.sol";

import "../Core/Core.sol";
import "../Core/FloatMath.sol";
import "./IEngine.sol";


/**
 * @title the stateless component for a PAM contract
 * implements the STF and POF of the Actus standard for a PAM contract
 * @dev all numbers except unix timestamp are represented as multiple of 10 ** 18
 * inputs have to be multiplied by 10 ** 18, outputs have to divided by 10 ** 18
 */
contract PAMEngine is Core, IEngine {

	using SafeMath for uint;
	using SignedSafeMath for int;
	using FloatMath for int;


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
	 * @param timestamp current timestamp
	 * @return the new contract state and the evaluated events
	 */
	function computeNextState(
		ContractTerms memory contractTerms,
		ContractState memory contractState,
		uint256 timestamp
	)
		public
		pure
		returns (ContractState memory, ContractEvent[MAX_EVENT_SCHEDULE_SIZE] memory)
	{
		ContractState memory nextContractState = contractState;
		ContractEvent[MAX_EVENT_SCHEDULE_SIZE] memory nextContractEvents;

		ProtoEvent[MAX_EVENT_SCHEDULE_SIZE] memory pendingProtoEventSchedule = computeProtoEventScheduleSegment(
			contractTerms,
			contractState.lastEventTime,
			timestamp
		);

		for (uint8 index = 0; index < MAX_EVENT_SCHEDULE_SIZE; index++) {
			if (pendingProtoEventSchedule[index].eventTime == 0) continue;

			nextContractEvents[index] = ContractEvent(
				pendingProtoEventSchedule[index].eventTime,
				pendingProtoEventSchedule[index].eventType,
				pendingProtoEventSchedule[index].currency,
				payoffFunction(
					pendingProtoEventSchedule[index].scheduleTime,
					contractTerms,
					contractState,
					pendingProtoEventSchedule[index].eventType
				),
				timestamp
			);

			nextContractState = stateTransitionFunction(
				pendingProtoEventSchedule[index].scheduleTime,
				contractTerms,
				contractState,
				pendingProtoEventSchedule[index].eventType
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
	 * @param timestamp current timestamp
	 * @return the new contract state and the evaluated event
	 */
	function computeNextStateForProtoEvent(
		ContractTerms memory contractTerms,
		ContractState memory contractState,
		ProtoEvent memory protoEvent,
		uint256 timestamp
	)
		public
		pure
		returns (ContractState memory, ContractEvent memory)
	{
		ContractEvent memory contractEvent = ContractEvent(
			protoEvent.eventTime,
			protoEvent.eventType,
			protoEvent.currency,
			payoffFunction(timestamp, contractTerms, contractState, protoEvent.pofType), // solium-disable-line
			timestamp
		);

		ContractState memory nextContractState = stateTransitionFunction(
			timestamp,
			contractTerms,
			contractState,
			protoEvent.stfType
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
	 * @param timestamp current timestamp
	 * @param contractTerms terms of the contract
	 * @param contractState current state of the contract
	 * @param eventType event type
	 * @return next contract state
	 */
	function stateTransitionFunction(
		uint256 timestamp,
		ContractTerms memory contractTerms,
		ContractState memory contractState,
		EventType eventType
	)
		private
		pure
		returns (ContractState memory)
	{
		if (eventType == EventType.AD) {
			contractState.timeFromLastEvent = yearFraction(
				shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
				shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
				contractTerms.dayCountConvention
			);
			contractState.nominalAccrued = contractState.nominalAccrued.add(contractState.nominalRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.feeAccrued = contractState.feeAccrued.add(contractTerms.feeRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.lastEventTime = timestamp;
			return contractState;
		}
		if (eventType == EventType.CD) {
			contractState.timeFromLastEvent = yearFraction(
				shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
				shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
				contractTerms.dayCountConvention
			);
			contractState.nominalAccrued = contractState.nominalAccrued.add(contractState.nominalRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.feeAccrued = contractState.feeAccrued.add(contractTerms.feeRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.contractStatus = ContractStatus.DF;
			contractState.lastEventTime = timestamp;
			return contractState;
		}
		if (eventType == EventType.FP) {
			contractState.timeFromLastEvent = yearFraction(
				shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
				shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
				contractTerms.dayCountConvention
			);
			contractState.nominalAccrued = contractState.nominalAccrued.add(contractState.nominalRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.feeAccrued = 0;
			contractState.lastEventTime = timestamp;
			return contractState;
		}
		if (eventType == EventType.IED) {
			contractState.timeFromLastEvent = yearFraction(
				shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
				shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
				contractTerms.dayCountConvention
			);
			contractState.nominalValue = roleSign(contractTerms.contractRole) * contractTerms.notionalPrincipal;
			contractState.nominalRate = contractTerms.nominalInterestRate;
			contractState.lastEventTime = timestamp;

			if (contractTerms.cycleAnchorDateOfInterestPayment != 0 &&
				contractTerms.cycleAnchorDateOfInterestPayment < contractTerms.initialExchangeDate
			) {
				contractState.nominalAccrued = contractState.nominalRate
				.floatMult(contractState.nominalValue)
				.floatMult(yearFraction(contractTerms.cycleAnchorDateOfInterestPayment, timestamp, contractTerms.dayCountConvention));
			}
			return contractState;
		}
		if (eventType == EventType.IPCI) {
			contractState.timeFromLastEvent = yearFraction(
				shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
				shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
				contractTerms.dayCountConvention
			);
			contractState.nominalValue = contractState.nominalValue.add(contractState.nominalAccrued.add(contractState.nominalRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent)));
			contractState.nominalAccrued = 0;
			contractState.feeAccrued = contractState.feeAccrued.add(contractTerms.feeRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.lastEventTime = timestamp;
			return contractState;
		}
		if (eventType == EventType.IP) {
			contractState.timeFromLastEvent = yearFraction(
				shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
				shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
				contractTerms.dayCountConvention
			);
			contractState.nominalAccrued = 0;
			contractState.feeAccrued = contractState.feeAccrued.add(contractTerms.feeRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.lastEventTime = timestamp;
			return contractState;
		}
		if (eventType == EventType.PP) {
			contractState.timeFromLastEvent = yearFraction(
				shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
				shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
				contractTerms.dayCountConvention
			);
			contractState.nominalAccrued = contractState.nominalAccrued.add(contractState.nominalRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.feeAccrued = contractState.feeAccrued.add(contractTerms.feeRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.nominalValue -= 0; // riskFactor(contractTerms.objectCodeOfPrepaymentModel, timestamp, contractState, contractTerms) * contractState.nominalValue;
			contractState.lastEventTime = timestamp;
			return contractState;
		}
		if (eventType == EventType.PRD) {
			contractState.timeFromLastEvent = yearFraction(
				shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
				shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
				contractTerms.dayCountConvention
			);
			contractState.nominalAccrued = contractState.nominalAccrued.add(contractState.nominalRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.feeAccrued = contractState.feeAccrued.add(contractTerms.feeRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.lastEventTime = timestamp;
			return contractState;
		}
		if (eventType == EventType.PR) {
			contractState.timeFromLastEvent = yearFraction(
				shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
				shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
				contractTerms.dayCountConvention
			);
			contractState.nominalValue = 0;
			contractState.nominalRate = 0;
			contractState.nominalAccrued = 0;
			contractState.feeAccrued = 0;
			contractState.lastEventTime = timestamp;
			return contractState;
		}
		if (eventType == EventType.PY) {
			contractState.timeFromLastEvent = yearFraction(
				shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
				shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
				contractTerms.dayCountConvention
			);
			contractState.nominalAccrued = contractState.nominalAccrued.add(contractState.nominalRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.feeAccrued = contractState.feeAccrued.add(contractTerms.feeRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.lastEventTime = timestamp;
			return contractState;
		}
		if (eventType == EventType.RRY) {
			contractState.timeFromLastEvent = yearFraction(
				shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
				shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
				contractTerms.dayCountConvention
			);
			contractState.nominalAccrued = contractState.nominalAccrued.add(contractState.nominalRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.feeAccrued = contractState.feeAccrued.add(contractTerms.feeRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.nominalRate = contractTerms.nextResetRate;
			contractState.lastEventTime = timestamp;
			return contractState;
		}
		if (eventType == EventType.RR) {
			// int256 rate = //riskFactor(contractTerms.marketObjectCodeOfRateReset, timestamp, contractState, contractTerms)
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
				shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
				contractTerms.dayCountConvention
			);
			contractState.nominalAccrued = contractState.nominalAccrued.add(contractState.nominalRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.nominalRate = rate;
			contractState.lastEventTime = timestamp;
			return contractState;
		}
		if (eventType == EventType.SC) {
			contractState.timeFromLastEvent = yearFraction(
				shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
				shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
				contractTerms.dayCountConvention
			);
			contractState.nominalAccrued = contractState.nominalAccrued.add(contractState.nominalRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));
			contractState.feeAccrued = contractState.feeAccrued.add(contractTerms.feeRate.floatMult(contractState.nominalValue).floatMult(contractState.timeFromLastEvent));

			if ((contractTerms.scalingEffect == ScalingEffect.I00)
				|| (contractTerms.scalingEffect == ScalingEffect.IN0)
				|| (contractTerms.scalingEffect == ScalingEffect.I0M)
				|| (contractTerms.scalingEffect == ScalingEffect.INM)
			) {
				contractState.interestScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, timestamp, contractState, contractTerms)
			}
			if ((contractTerms.scalingEffect == ScalingEffect._0N0)
				|| (contractTerms.scalingEffect == ScalingEffect._0NM)
				|| (contractTerms.scalingEffect == ScalingEffect.IN0)
				|| (contractTerms.scalingEffect == ScalingEffect.INM)
			) {
				contractState.nominalScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, timestamp, contractState, contractTerms)
			}

			contractState.lastEventTime = timestamp;
			return contractState;
		}
		if (eventType == EventType.TD) {
			contractState.timeFromLastEvent = yearFraction(
				shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
				shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
				contractTerms.dayCountConvention
			);
			contractState.nominalValue = 0;
			contractState.nominalRate = 0;
			contractState.nominalAccrued = 0;
			contractState.feeAccrued = 0;
			contractState.lastEventTime = timestamp;
			return contractState;
		}
		revert("PAMEngine.stateTransitionFunction: ATTRIBUTE_NOT_FOUND");
	}

	/**
	 * calculates the payoff for the current time based on the contract terms,
	 * state and the event type
	 * @param timestamp current timestamp
	 * @param contractTerms terms of the contract
	 * @param contractState current state of the contract
	 * @param eventType event type
	 * @return payoff
	 */
	function payoffFunction(
		uint256 timestamp,
		ContractTerms memory contractTerms,
		ContractState memory contractState,
		EventType eventType
	)
		private
		pure
		returns (int256 payoff)
	{
		if (eventType == EventType.AD) return 0;
		if (eventType == EventType.CD) return 0;
		if (eventType == EventType.IPCI) return 0;
		if (eventType == EventType.RRY) return 0;
		if (eventType == EventType.RR) return 0;
		if (eventType == EventType.SC) return 0;
		if (eventType == EventType.FP) {
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
								contractTerms.dayCountConvention
							)
							.floatMult(contractTerms.feeRate)
							.floatMult(contractState.nominalValue)
						)
				);
			}
		}
		if (eventType == EventType.IED) {
			return (
				performanceIndicator(contractState.contractStatus)
				* roleSign(contractTerms.contractRole)
				* (-1)
				* contractTerms.notionalPrincipal
					.add(contractTerms.premiumDiscountAtIED)
			);
		}
		if (eventType == EventType.IP) {
			return (
				performanceIndicator(contractState.contractStatus)
				* contractState.interestScalingMultiplier
					.floatMult(
						contractState.nominalAccrued
						.add(
							yearFraction(
								shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
								shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
								contractTerms.dayCountConvention
							)
							.floatMult(contractState.nominalRate)
							.floatMult(contractState.nominalValue)
						)
					)
			);
		}
		if (eventType == EventType.PP) {
			return (
				performanceIndicator(contractState.contractStatus)
				* roleSign(contractTerms.contractRole)
				* 0 // riskFactor(timestamp, contractState, contractTerms, contractTerms.objectCodeOfPrepaymentModel)
				* contractState.nominalValue
			);
		}
		if (eventType == EventType.PRD) {
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
							contractTerms.dayCountConvention
						)
						.floatMult(contractState.nominalRate)
						.floatMult(contractState.nominalValue)
					)
			);
		}
		if (eventType == EventType.PR) {
			return (
				performanceIndicator(contractState.contractStatus)
				* contractState.nominalScalingMultiplier
					.floatMult(contractState.nominalValue)
			);
		}
		if (eventType == EventType.PY) {
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
							contractTerms.dayCountConvention
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
							contractTerms.dayCountConvention
						)
						.floatMult(contractState.nominalValue)
						.floatMult(param)
				);
			}
		}
		if (eventType == EventType.TD) {
			return (
				performanceIndicator(contractState.contractStatus)
				* roleSign(contractTerms.contractRole)
				* contractTerms.priceAtPurchaseDate
					.add(contractState.nominalAccrued)
					.add(
						yearFraction(
							shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
							shiftCalcTime(timestamp, contractTerms.businessDayConvention, contractTerms.calendar),
							contractTerms.dayCountConvention
						)
						.floatMult(contractState.nominalRate)
						.floatMult(contractState.nominalValue)
					)
			);
		}
		revert("PAMEngine.payoffFunction: ATTRIBUTE_NOT_FOUND");
	}
}
