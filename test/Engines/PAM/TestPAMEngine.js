const PAMEngine = artifacts.require('PAMEngine.sol');

const { getDefaultTestTerms } = require('../../helper/tests');
const { removeNullEvents } = require('../../helper/schedule');


contract('PAMEngine', () => {

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
    await this.PAMEngineInstance.computeNextState(this.terms, initialState, this.terms['maturityDate']);
  });

  it('should yield the same evaluated events for computeNextState and computeNextStateForProtoEvent', async () => {
    const initialState = await this.PAMEngineInstance.computeInitialState(this.terms, {});

    const protoEventSchedule = removeNullEvents(await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      this.terms, 
      this.terms['statusDate'],
      this.terms['maturityDate'],
    ));

    const endTimestamp = protoEventSchedule[Math.floor(protoEventSchedule.length / 2)].scheduleTime;

    const { 0: state_computeNextState, 1: events_computeNextState } = await this.PAMEngineInstance.computeNextState(
      this.terms, 
      initialState, 
      endTimestamp
    );

    let state_computeNextStateForProtoEvent = initialState;
    let events_computeNextStateForProtoEvent = [];

    for (let i = 0; i < 20; i ++) {
      if (protoEventSchedule[i].scheduleTime > endTimestamp) { break; }

      const { 0: nextState_computeNextStateForProtoEvent, 1: contractEvent } = await this.PAMEngineInstance.computeNextStateForProtoEvent(
        this.terms, 
        state_computeNextStateForProtoEvent, 
        protoEventSchedule[i], 
        protoEventSchedule[i].scheduleTime
      );

      contractEvent[4] = endTimestamp;
      contractEvent.actualEventTime = endTimestamp;

      state_computeNextStateForProtoEvent = nextState_computeNextStateForProtoEvent;
      events_computeNextStateForProtoEvent.push(contractEvent);
    }

    assert.deepEqual(state_computeNextState, state_computeNextStateForProtoEvent);
    assert.deepEqual(removeNullEvents(events_computeNextState), removeNullEvents(events_computeNextStateForProtoEvent));
  });

  it('should yield all events', async () => {
    const protoEventSchedule = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      this.terms, 
      this.terms['statusDate'],
      this.terms['maturityDate'],
    );

    assert.isTrue(removeNullEvents(protoEventSchedule).length > 0);
  });

  it('should yield correct segment of events', async () => {
    const entireProtoEventSchedule = removeNullEvents(
      await this.PAMEngineInstance.computeProtoEventScheduleSegment(
        this.terms, 
        this.terms['statusDate'],
        this.terms['maturityDate'],
      )
    );

    let protoEventSchedule = [];
    let lastEventTime = this.terms['statusDate'];
    let timestamp = this.terms['statusDate'] + (this.terms['maturityDate'] - this.terms['statusDate']) / 4;

    response = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      this.terms, 
      lastEventTime,
      timestamp
    );
    protoEventSchedule = [...response];

    lastEventTime = timestamp;
    timestamp = this.terms['statusDate'] + (this.terms['maturityDate'] - this.terms['statusDate']) / 2;

    response = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      this.terms, 
      lastEventTime,
      timestamp
    );
    protoEventSchedule = [...protoEventSchedule, ...response];
    
    lastEventTime = timestamp;
    timestamp = this.terms['maturityDate'];

    response = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      this.terms, 
      lastEventTime,
      timestamp
    );
    protoEventSchedule = [...protoEventSchedule, ...response];
    
    protoEventSchedule = removeNullEvents(protoEventSchedule);
    
    assert.isTrue(protoEventSchedule.toString() === entireProtoEventSchedule.toString());
  });

  // Payment Delay
  it('should', async () => {
    let protoEventSchedule = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      this.terms,
      this.terms['statusDate'],
      this.terms['maturityDate']
    );

    // insert Payment Delay Event
    protoEventSchedule.splice(6, 0, [ ...protoEventSchedule[5] ]);
    protoEventSchedule[6].scheduleTime = protoEventSchedule[5].scheduleTime;
    protoEventSchedule[6].eventType = '22';
    protoEventSchedule[6].pofType = '22';
    protoEventSchedule[6].stfType = '22';
    protoEventSchedule[6][3]= '22';
    protoEventSchedule[6][5] = '22';
    protoEventSchedule[6][6] = '22';

    protoEventSchedule = removeNullEvents(protoEventSchedule);

    let state = await this.PAMEngineInstance.computeInitialState(this.terms, {});
    const evaluatedEventSchedule = [];

    for (let i = 0; i < protoEventSchedule.length; i ++) {
      const { 0: nextState, 1: contractEvent } = await this.PAMEngineInstance.computeNextStateForProtoEvent(
        this.terms, 
        state, 
        protoEventSchedule[i], 
        protoEventSchedule[i].scheduleTime
      );

      state = nextState;
      evaluatedEventSchedule.push({ state, event: contractEvent });
    }

    console.log(evaluatedEventSchedule);
  });
});
