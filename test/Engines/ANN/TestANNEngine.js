const ANNEngine = artifacts.require('ANNEngine.sol');

const { getTestCases } = require('../../helper/tests');
const { removeNullEvents } = require('../../helper/schedule');


contract('ANNEngine', () => {

  before(async () => {        
    this.ANNEngineInstance = await ANNEngine.new();
    this.terms = (await getTestCases( "ANN" ))['20001'].terms;
  });

  it('should yield the initial contract state', async () => {
    const initialState = await this.ANNEngineInstance.computeInitialState(this.terms, {});
    assert.isTrue(Number(initialState['lastEventTime']) === Number(this.terms['statusDate']));
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

  it('should yield the next next contract state and the contract events', async() => {
    const initialState = await this.ANNEngineInstance.computeInitialState(this.terms, {});
    await this.ANNEngineInstance.computeNextState(this.terms, initialState, this.terms['maturityDate']);
  });
});
