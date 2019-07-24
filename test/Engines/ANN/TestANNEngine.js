const ANNEngine = artifacts.require('ANNEngine.sol');

const { getTestCases } = require('../../helper/tests');
const { removeNullEvents } = require('../../helper/schedule');


contract('ANNEngine', () => {

  before(async () => {        
    this.ANNEngineInstance = await ANNEngine.new();
    this.terms = (await getTestCases('ANN'))['20001'].terms;
  });

  it('should yield the initial contract state', async () => {
    const initialState = await this.ANNEngineInstance.computeInitialState(this.terms, {});
    assert.isTrue(Number(initialState['lastEventTime']) === Number(this.terms['statusDate']));
  });

  it('should yield the next next contract state and the contract events', async() => {
    const initialState = await this.ANNEngineInstance.computeInitialState(this.terms, {});
    await this.ANNEngineInstance.computeNextState(this.terms, initialState, this.terms['maturityDate']);
  });

  it('should yield the same evaluated events for computeNextState and computeNextStateForProtoEvent', async () => {
    const initialState = await this.ANNEngineInstance.computeInitialState(this.terms, {});

    const protoEventSchedule = removeNullEvents(await this.ANNEngineInstance.computeProtoEventScheduleSegment(
      this.terms, 
      this.terms['statusDate'],
      this.terms['maturityDate'],
    ));

    const endTimestamp = protoEventSchedule[Math.floor(protoEventSchedule.length / 2)].scheduleTime;

    const { 0: state_computeNextState, 1: events_computeNextState } = await this.ANNEngineInstance.computeNextState(
      this.terms, 
      initialState, 
      endTimestamp
    );

    let state_computeNextStateForProtoEvent = initialState;
    let events_computeNextStateForProtoEvent = [];

    for (let i = 0; i < 20; i ++) {
      if (protoEventSchedule[i].scheduleTime > endTimestamp) { break; }

      const { 0: nextState_computeNextStateForProtoEvent, 1: contractEvent } = await this.ANNEngineInstance.computeNextStateForProtoEvent(
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
    let protoEventSchedule = await this.ANNEngineInstance.computeProtoEventScheduleSegment(
      this.terms, 
      this.terms['statusDate'],
      this.terms['maturityDate'],
    );

    assert.isTrue(removeNullEvents(protoEventSchedule).length > 0);
  });

  it('should yield correct segment of events', async () => {
    const entireProtoEventSchedule = removeNullEvents(
      await this.ANNEngineInstance.computeProtoEventScheduleSegment(
        this.terms, 
        this.terms['statusDate'],
        this.terms['maturityDate'],
      )
    );

    let protoEventSchedule = [];
    let lastEventTime = this.terms['statusDate'];
    let timestamp = this.terms['statusDate'] + (this.terms['maturityDate'] - this.terms['statusDate']) / 4;

    response = await this.ANNEngineInstance.computeProtoEventScheduleSegment(
      this.terms, 
      lastEventTime,
      timestamp
    );
    protoEventSchedule = [...response];

    lastEventTime = timestamp;
    timestamp = this.terms['statusDate'] + (this.terms['maturityDate'] - this.terms['statusDate']) / 2;

    response = await this.ANNEngineInstance.computeProtoEventScheduleSegment(
      this.terms, 
      lastEventTime,
      timestamp
    );
    protoEventSchedule = [...protoEventSchedule, ...response];
    
    lastEventTime = timestamp;
    timestamp = this.terms['maturityDate'];

    response = await this.ANNEngineInstance.computeProtoEventScheduleSegment(
      this.terms, 
      lastEventTime,
      timestamp
    );
    protoEventSchedule = [...protoEventSchedule, ...response];
    
    protoEventSchedule = removeNullEvents(protoEventSchedule);
    
    assert.isTrue(protoEventSchedule.toString() === entireProtoEventSchedule.toString());
  });
});
