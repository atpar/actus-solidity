const PAMEngine = artifacts.require('PAMEngine.sol');

const { getTestCases } = require('../../helper/tests');
const { removeNullEvents } = require('../../helper/schedule');


contract('PAMEngine', () => {

  before(async () => {        
    this.PAMEngineInstance = await PAMEngine.new();
    this.testCases = await getTestCases( "PAM" )
  });

  it('should yield the initial contract state', async () => {
    const terms = this.testCases['10001'].terms
    const initialState = await this.PAMEngineInstance.computeInitialState(terms, {});
    assert.isTrue(Number(initialState['lastEventTime']) === Number(terms['statusDate']));
  });

  it('should yield all events', async () => {
    const terms = this.testCases['10001'].terms
    let protoEventSchedule = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      terms, 
      terms['statusDate'],
      terms['maturityDate'],
    );

    assert.isTrue(removeNullEvents(protoEventSchedule).length > 0);
  });

  it('should yield correct segment of events', async () => {
    const terms = this.testCases['10001'].terms
    const entireProtoEventSchedule = removeNullEvents(
      await this.PAMEngineInstance.computeProtoEventScheduleSegment(
        terms, 
        terms['statusDate'],
        terms['maturityDate'],
      )
    );


    let protoEventSchedule = [];
    let lastEventTime = terms['statusDate'];
    let timestamp = terms['statusDate'] + (terms['maturityDate'] - terms['statusDate']) / 4;

    response = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      terms, 
      lastEventTime,
      timestamp
    );
    protoEventSchedule = [...response];

    lastEventTime = timestamp;
    timestamp = terms['statusDate'] + (terms['maturityDate'] - terms['statusDate']) / 2;

    response = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      terms, 
      lastEventTime,
      timestamp
    );
    protoEventSchedule = [...protoEventSchedule, ...response];
    
    lastEventTime = timestamp;
    timestamp = terms['maturityDate'];

    response = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      terms, 
      lastEventTime,
      timestamp
    );
    protoEventSchedule = [...protoEventSchedule, ...response];
    
    protoEventSchedule = removeNullEvents(protoEventSchedule);
    
    assert.isTrue(protoEventSchedule.toString() === entireProtoEventSchedule.toString());
  });

  it('should yield the next next contract state and the contract events', async() => {
    const terms = this.testCases['10001'].terms
    const initialState = await this.PAMEngineInstance.computeInitialState(terms, {});
    await this.PAMEngineInstance.computeNextState(terms, initialState, terms['maturityDate']);
  });
});
