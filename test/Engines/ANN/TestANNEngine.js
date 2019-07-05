const ANNEngine = artifacts.require('ANNEngine.sol');

const { getTestCases } = require('../../helper/tests');
const { removeNullEvents } = require('../../helper/schedule');


contract('ANNEngine', () => {

  before(async () => {        
    this.ANNEngineInstance = await ANNEngine.new();
    this.testCases = await getTestCases( "ANN" )
  });

  it('should yield the initial contract state', async () => {
    const terms = this.testCases['20001'].terms
    const initialState = await this.ANNEngineInstance.computeInitialState(terms, {});
    assert.isTrue(Number(initialState['lastEventTime']) === Number(terms['statusDate']));
  });

  it('should yield all events', async () => {
    const terms = this.testCases['20001'].terms
    let protoEventSchedule = await this.ANNEngineInstance.computeProtoEventScheduleSegment(
      terms, 
      terms['statusDate'],
      terms['maturityDate'],
    );

    assert.isTrue(removeNullEvents(protoEventSchedule).length > 0);
  });

  it('should yield correct segment of events', async () => {
    const terms = this.testCases['20001'].terms
    const entireProtoEventSchedule = removeNullEvents(
      await this.ANNEngineInstance.computeProtoEventScheduleSegment(
        terms, 
        terms['statusDate'],
        terms['maturityDate'],
      )
    );


    let protoEventSchedule = [];
    let lastEventTime = terms['statusDate'];
    let timestamp = terms['statusDate'] + (terms['maturityDate'] - terms['statusDate']) / 4;

    response = await this.ANNEngineInstance.computeProtoEventScheduleSegment(
      terms, 
      lastEventTime,
      timestamp
    );
    protoEventSchedule = [...response];

    lastEventTime = timestamp;
    timestamp = terms['statusDate'] + (terms['maturityDate'] - terms['statusDate']) / 2;

    response = await this.ANNEngineInstance.computeProtoEventScheduleSegment(
      terms, 
      lastEventTime,
      timestamp
    );
    protoEventSchedule = [...protoEventSchedule, ...response];
    
    lastEventTime = timestamp;
    timestamp = terms['maturityDate'];

    response = await this.ANNEngineInstance.computeProtoEventScheduleSegment(
      terms, 
      lastEventTime,
      timestamp
    );
    protoEventSchedule = [...protoEventSchedule, ...response];
    
    protoEventSchedule = removeNullEvents(protoEventSchedule);
    
    assert.isTrue(protoEventSchedule.toString() === entireProtoEventSchedule.toString());
  });

  it('should yield the next next contract state and the contract events', async() => {
    const terms = this.testCases['20001'].terms
    const initialState = await this.ANNEngineInstance.computeInitialState(terms, {});
    await this.ANNEngineInstance.computeNextState(terms, initialState, terms['maturityDate']);
  });
});
