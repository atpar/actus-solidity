const ANNEngine = artifacts.require('ANNEngine.sol');

const { getTestCases } = require('../../helper/tests');
const { parseToTestEvent } = require('../../helper/parser');


contract('ANNEngine', () => {

  before(async () => {    
    this.ANNEngineInstance = await ANNEngine.new();
    this.testCases = await getTestCases('ANN');
  })

  const evaluateEventSchedule = async (terms) => {
    const initialState = await this.ANNEngineInstance.computeInitialState(terms, {});
    const protoEventSchedule = await this.ANNEngineInstance.computeProtoEventScheduleSegment(
      terms,
      terms.statusDate,
      terms.maturityDate
    );

    const evaluatedSchedule = [];
    let state = initialState;

    for (let i = 0; i < protoEventSchedule.length; i++) {
      if (protoEventSchedule[i].scheduleTime == 0) { break; }
      const { 0: nextContractState, 1: contractEvent } = await this.ANNEngineInstance.computeNextStateForProtoEvent(
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

  it('should yield the expected evaluated contract schedule for test ANN-20001', async () => {
    const testDetails = this.testCases['20001'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  /*
  // exceeds max schedule size!
  it('should yield the expected evaluated contract schedule for test ANN-20002', async () => {
    const testDetails = this.testCases['20002'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });
  */

  it('should yield the expected evaluated contract schedule for test ANN-20003', async () => {
    const testDetails = this.testCases['20003'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);
    
    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20004', async () => {
    const testDetails = this.testCases['20004'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });
 
  it('should yield the expected evaluated contract schedule for test ANN-20005', async () => {
    const testDetails = this.testCases['20005'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20006', async () => {
    const testDetails = this.testCases['20006'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  // for the remaining cases: annuity amount calculator needs to be implemented
  // and state space initialization updated
  /*
  it('should yield the expected evaluated contract schedule for test ANN-20007', async () => {
    const testDetails = this.testCases['20007'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20008', async () => {
    const testDetails = this.testCases['20008'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20009', async () => {
    const testDetails = this.testCases['20009'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20010', async () => {
    const testDetails = this.testCases['20010'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20011', async () => {
    const testDetails = this.testCases['20011'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20012', async () => {
    const testDetails = this.testCases['20012'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20013', async () => {
    const testDetails = this.testCases['20013'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20014', async () => {
    const testDetails = this.testCases['20014'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20015', async () => {
    const testDetails = this.testCases['20015'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20016', async () => {
    const testDetails = this.testCases['20016'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20017', async () => {
    const testDetails = this.testCases['20017'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20018', async () => {
    const testDetails = this.testCases['20018'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20019', async () => {
    const testDetails = this.testCases['20019'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20020', async () => {
    const testDetails = this.testCases['20020'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20021', async () => {
    const testDetails = this.testCases['20021'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20022', async () => {
    const testDetails = this.testCases['20022'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20023', async () => {
    const testDetails = this.testCases['20023'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20024', async () => {
    const testDetails = this.testCases['20024'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20025', async () => {
    const testDetails = this.testCases['20025'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20026', async () => {
    const testDetails = this.testCases['20026'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20027', async () => {
    const testDetails = this.testCases['20028'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20029', async () => {
    const testDetails = this.testCases['20029'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test ANN-20030', async () => {
    const testDetails = this.testCases['20030'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    assert.deepEqual(evaluatedSchedule, testDetails['results']);
  });
  */
});
