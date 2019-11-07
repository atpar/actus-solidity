const PAMEngine = artifacts.require('PAMEngine.sol');

const { getDefaultTestTerms } = require('../../helper/tests');
const { 
  parseProtoEventSchedule,
  decodeProtoEvent,
  sortProtoEvents,
  removeNullProtoEvents
} = require('../../helper/schedule');


contract('PAMEngine', () => {

  const computeProtoEventScheduleSegment = async (terms, segmentStart, segmentEnd) => {
    const protoEventSchedule = [];
      
    protoEventSchedule.push(... await this.PAMEngineInstance.computeNonCyclicProtoEventScheduleSegment(
      terms,
      segmentStart,
      segmentEnd
    ));
    protoEventSchedule.push(... await this.PAMEngineInstance.computeCyclicProtoEventScheduleSegment(
      terms,
      segmentStart,
      segmentEnd,
      4 // FP
    ));
    protoEventSchedule.push(... await this.PAMEngineInstance.computeCyclicProtoEventScheduleSegment(
      terms,
      segmentStart,
      segmentEnd,
      8 // IP
    ));
    protoEventSchedule.push(... await this.PAMEngineInstance.computeCyclicProtoEventScheduleSegment(
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
  });

  it('should yield the initial contract state', async () => {
    const initialState = await this.PAMEngineInstance.computeInitialState(this.terms, {});
    assert.isTrue(Number(initialState['lastEventTime']) === Number(this.terms['statusDate']));
  });

  it('should yield the next next contract state and the contract events', async() => {
    const initialState = await this.PAMEngineInstance.computeInitialState(this.terms, {});
    const protoEventSchedule = await this.PAMEngineInstance.computeNonCyclicProtoEventScheduleSegment(
      this.terms,
      this.terms.contractDealDate,
      this.terms.maturityDate
    )
    const nextState = await this.PAMEngineInstance.computeStateForProtoEvent(
      this.terms,
      initialState,
      protoEventSchedule[0],
      decodeProtoEvent(protoEventSchedule[0]).scheduleTime
    );

    assert.equal(Number(nextState.lastEventTime), decodeProtoEvent(protoEventSchedule[0]).scheduleTime);
  });

  it('should yield correct segment of events', async () => {
    const completeProtoEventSchedule = parseProtoEventSchedule(await computeProtoEventScheduleSegment(
      this.terms,
      this.terms.contractDealDate,
      this.terms.maturityDate
    ));

    let protoEventSchedule = [];
    let lastEventTime = this.terms['statusDate'];
    let timestamp = this.terms['statusDate'] + (this.terms['maturityDate'] - this.terms['statusDate']) / 4;

    protoEventSchedule.push(... await computeProtoEventScheduleSegment(
      this.terms, 
      lastEventTime,
      timestamp
    ));

    lastEventTime = timestamp;
    timestamp = this.terms['statusDate'] + (this.terms['maturityDate'] - this.terms['statusDate']) / 2;

    protoEventSchedule.push(... await computeProtoEventScheduleSegment(
    this.terms, 
    lastEventTime,
      timestamp
    ));
    
    lastEventTime = timestamp;
    timestamp = this.terms['maturityDate'];

    protoEventSchedule.push(... await computeProtoEventScheduleSegment(
      this.terms, 
      lastEventTime,
      timestamp
    ));
    
    protoEventSchedule = parseProtoEventSchedule(sortProtoEvents(protoEventSchedule));
    
    assert.isTrue(protoEventSchedule.toString() === completeProtoEventSchedule.toString());
  });

  it('should yield the state of each ProtoEvent', async () => {
    const initialState = await this.PAMEngineInstance.computeInitialState(this.terms, {});

    const protoEventSchedule = removeNullProtoEvents(await computeProtoEventScheduleSegment(
      this.terms,
      this.terms.contractDealDate,
      this.terms.maturityDate
    ));

    let state = initialState;

    for (protoEvent of protoEventSchedule) {
      const nextState = await this.PAMEngineInstance.computeStateForProtoEvent(
        this.terms,
        state,
        protoEvent,
        decodeProtoEvent(protoEvent).scheduleTime
      );

      state = nextState;
    }
  })
});
