const PAMEngine = artifacts.require('PAMEngine.sol');

const { getDefaultTestTerms } = require('../../helper/tests');
const { parseTermsToLifecycleTerms, parseTermsToGeneratingTerms } = require('../../helper/parser');
const { 
  parseProtoEventSchedule,
  decodeProtoEvent,
  sortProtoEvents,
  removeNullProtoEvents
} = require('../../helper/schedule');


contract('PAMEngine', () => {

  const computeProtoEventScheduleSegment = async (terms, segmentStart, segmentEnd) => {
    const protoEventSchedule = [];
      
    protoEventSchedule.push(... await this.PAMEngineInstance.computeNonCyclicScheduleSegment(
      terms,
      segmentStart,
      segmentEnd
    ));
    protoEventSchedule.push(... await this.PAMEngineInstance.computeCyclicScheduleSegment(
      terms,
      segmentStart,
      segmentEnd,
      4 // FP
    ));
    protoEventSchedule.push(... await this.PAMEngineInstance.computeCyclicScheduleSegment(
      terms,
      segmentStart,
      segmentEnd,
      8 // IP
    ));
    protoEventSchedule.push(... await this.PAMEngineInstance.computeCyclicScheduleSegment(
      terms,
      segmentStart,
      segmentEnd,
      18 // PR
    ));
    
    return sortProtoEvents(removeNullProtoEvents(protoEventSchedule));
  }

  before(async () => {        
    this.PAMEngineInstance = await PAMEngine.new();
    this.terms = await getDefaultTestTerms('PAM');
    this.generatingTerms = parseTermsToGeneratingTerms(this.terms);
    this.lifecycleTerms = parseTermsToLifecycleTerms(this.terms);
  });

  it('should yield the initial contract state', async () => {
    const initialState = await this.PAMEngineInstance.computeInitialState(this.lifecycleTerms, {});
    assert.isTrue(Number(initialState['lastEventTime']) === Number(this.generatingTerms['statusDate']));
  });

  it('should yield the next next contract state and the contract events', async() => {
    const initialState = await this.PAMEngineInstance.computeInitialState(this.lifecycleTerms, {});
    const protoEventSchedule = await this.PAMEngineInstance.computeNonCyclicScheduleSegment(
      this.generatingTerms,
      this.generatingTerms.contractDealDate,
      this.generatingTerms.maturityDate
    )
    const nextState = await this.PAMEngineInstance.computeStateForEvent(
      this.lifecycleTerms,
      initialState,
      protoEventSchedule[0],
      decodeProtoEvent(protoEventSchedule[0]).scheduleTime
    );

    assert.equal(Number(nextState.lastEventTime), decodeProtoEvent(protoEventSchedule[0]).scheduleTime);
  });

  it('should yield correct segment of events', async () => {
    const completeProtoEventSchedule = parseProtoEventSchedule(await computeProtoEventScheduleSegment(
      this.generatingTerms,
      this.generatingTerms.contractDealDate,
      this.generatingTerms.maturityDate
    ));

    let protoEventSchedule = [];
    let lastEventTime = this.generatingTerms['statusDate'];
    let timestamp = this.generatingTerms['statusDate'] + (this.generatingTerms['maturityDate'] - this.generatingTerms['statusDate']) / 4;

    protoEventSchedule.push(... await computeProtoEventScheduleSegment(
      this.generatingTerms, 
      lastEventTime,
      timestamp
    ));

    lastEventTime = timestamp;
    timestamp = this.generatingTerms['statusDate'] + (this.generatingTerms['maturityDate'] - this.generatingTerms['statusDate']) / 2;

    protoEventSchedule.push(... await computeProtoEventScheduleSegment(
    this.generatingTerms, 
    lastEventTime,
      timestamp
    ));
    
    lastEventTime = timestamp;
    timestamp = this.generatingTerms['maturityDate'];

    protoEventSchedule.push(... await computeProtoEventScheduleSegment(
      this.generatingTerms, 
      lastEventTime,
      timestamp
    ));
    
    protoEventSchedule = parseProtoEventSchedule(sortProtoEvents(protoEventSchedule));
    
    assert.isTrue(protoEventSchedule.toString() === completeProtoEventSchedule.toString());
  });

  it('should yield the state of each event', async () => {
    const initialState = await this.PAMEngineInstance.computeInitialState(this.lifecycleTerms, {});

    const protoEventSchedule = removeNullProtoEvents(await computeProtoEventScheduleSegment(
      this.generatingTerms,
      this.generatingTerms.contractDealDate,
      this.generatingTerms.maturityDate
    ));

    let state = initialState;

    for (protoEvent of protoEventSchedule) {
      const nextState = await this.PAMEngineInstance.computeStateForEvent(
        this.lifecycleTerms,
        state,
        protoEvent,
        decodeProtoEvent(protoEvent).scheduleTime
      );

      state = nextState;
    }
  })
});
