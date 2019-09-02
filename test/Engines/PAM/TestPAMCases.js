const PAMEngine = artifacts.require('PAMEngine.sol');

const { compareTestResults } = require('../../helper/tests');
const { parseToTestEvent } = require('../../helper/parser');


contract('PAMEngine', () => {

  before(async () => {    
    this.PAMEngineInstance = await PAMEngine.new();
		this.testTerms =  {"contractType":0,"calendar":0,"contractRole":0,"creatorID":"0x0000000000000000000000000000000000000000000000000000000000000000","counterpartyID":"0x0000000000000000000000000000000000000000000000000000000000000000","dayCountConvention":1,"businessDayConvention":0,"endOfMonthConvention":0,"currency":"0x0000000000000000000000000000000000000000","scalingEffect":0,"penaltyType":0,"feeBasis":0,"contractDealDate":1577893471,"statusDate":1577893471,"initialExchangeDate":1577979871,"maturityDate":1585752271,"terminationDate":0,"purchaseDate":0,"capitalizationEndDate":0,"cycleAnchorDateOfInterestPayment":1580571871,"cycleAnchorDateOfRateReset":0,"cycleAnchorDateOfScalingIndex":0,"cycleAnchorDateOfFee":0,"cycleAnchorDateOfPrincipalRedemption":0,"notionalPrincipal":"0x3635c9adc5dea00000","nominalInterestRate":"0x58d15e176280000","feeAccrued":0,"accruedInterest":0,"rateMultiplier":0,"rateSpread":0,"feeRate":0,"nextResetRate":0,"penaltyRate":0,"premiumDiscountAtIED":0,"priceAtPurchaseDate":0,"nextPrincipalRedemptionPayment":0,"cycleOfInterestPayment":{"i":"1","p":2,"s":0,"isSet":true},"cycleOfRateReset":{"i":"0","p":0,"s":0,"isSet":false},"cycleOfScalingIndex":{"i":"0","p":0,"s":0,"isSet":false},"cycleOfFee":{"i":"0","p":0,"s":0,"isSet":true},"cycleOfPrincipalRedemption":{"i":"0","p":0,"s":0,"isSet":false},"lifeCap":0,"lifeFloor":0,"periodCap":0,"periodFloor":0};
  });

  const evaluateEventSchedule = async (terms) => {
    const initialState = await this.PAMEngineInstance.computeInitialState(terms, {});
    const protoEventSchedule = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      terms,
      terms.statusDate,
      terms.maturityDate
    );

    const evaluatedSchedule = [];
    let state = initialState;

    for (let i = 0; i < 20; i++) {
      if (protoEventSchedule[i].scheduleTime == 0) { break; }
      const { 0: nextContractState, 1: contractEvent } = await this.PAMEngineInstance.computeNextStateForProtoEvent(
        terms, 
        state, 
        protoEventSchedule[i], 
        protoEventSchedule[i].scheduleTime
      );

      state = nextContractState;

      evaluatedSchedule.push(parseToTestEvent(contractEvent, state));
    }

    return evaluatedSchedule;
  };

  it('should yield the expected evaluated contract schedule for test case', async () => {
    const evaluatedSchedule = await evaluateEventSchedule(this.testTerms);

    console.log(evaluatedSchedule);
  });
});

