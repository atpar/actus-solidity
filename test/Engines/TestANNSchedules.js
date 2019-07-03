const ANNEngine = artifacts.require('ANNEngine.sol')

const { getTestCases } = require('../helper/tests')
const { parseEventFromEth } = require('../helper/parser')
const { removeNullEvents } = require('../helper/schedule')


contract('ANNEngine', () => {

  before(async () => {    
    this.ANNEngineInstance = await ANNEngine.new()
    this.testCases = await getTestCases( "ANN" )
  })

  const evaluateEventSchedule = async (contractTerms) => {
    const initialContractState = await this.ANNEngineInstance.computeInitialState(contractTerms, {})
    const protoEventSchedule = await this.ANNEngineInstance.computeProtoEventScheduleSegment(
      contractTerms,
      contractTerms.statusDate,
      contractTerms.maturityDate
    )

    const evaluatedSchedule = []
    let contractState = initialContractState

    for (let i = 0; i < 20; i++) {
      if (protoEventSchedule[i].scheduledTime == 0) { break; }
      const { 0: nextContractState, 1: contractEvent } = await this.ANNEngineInstance.computeNextStateForProtoEvent(
        contractTerms, 
        contractState, 
        protoEventSchedule[i], 
        protoEventSchedule[i].scheduledTime
      )

      contractState = nextContractState

      evaluatedSchedule.push(parseEventFromEth(contractEvent, contractState))
    }

    return evaluatedSchedule
  }

  it('should yield the initial contract state', async () => {
    const initialState = await this.ANNEngineInstance.computeInitialState(this.testCases['20001'].terms, {})
    assert.isTrue(Number(initialState['lastEventTime']) === Number(this.testCases['20001'].terms['statusDate']))
  })

  it('should yield all events', async () => {
    let protoEventSchedule = await this.ANNEngineInstance.computeProtoEventScheduleSegment(
      this.testCases['20001'].terms, 
      this.testCases['20001'].terms['statusDate'],
      this.testCases['20001'].terms['maturityDate'],
    )
    assert.isTrue(removeNullEvents(protoEventSchedule).length > 0)
  })

  it('should yield the expected evaluated contract schedule for test ANN-20001', async () => {
    const testDetails = this.testCases['20001']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    console.log(evaluatedSchedule)
    console.log(testDetails.results)

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

/*
  it('should yield the expected evaluated contract schedule for test ANN-20002', async () => {
    const testDetails = this.testCases['20002']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20003', async () => {
    const testDetails = this.testCases['20003']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])
    
    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20004', async () => {
    const testDetails = this.testCases['20004']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })
 
  it('should yield the expected evaluated contract schedule for test ANN-20005', async () => {
    const testDetails = this.testCases['20005']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20006', async () => {
    const testDetails = this.testCases['20006']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20007', async () => {
    const testDetails = this.testCases['20007']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20008', async () => {
    const testDetails = this.testCases['20008']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20009', async () => {
    const testDetails = this.testCases['20009']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20010', async () => {
    const testDetails = this.testCases['20010']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20011', async () => {
    const testDetails = this.testCases['20011']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20012', async () => {
    const testDetails = this.testCases['20012']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20013', async () => {
    const testDetails = this.testCases['20013']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20014', async () => {
    const testDetails = this.testCases['20014']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20015', async () => {
    const testDetails = this.testCases['20015']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20016', async () => {
    const testDetails = this.testCases['20016']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20017', async () => {
    const testDetails = this.testCases['20017']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20018', async () => {
    const testDetails = this.testCases['20018']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20019', async () => {
    const testDetails = this.testCases['20019']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20020', async () => {
    const testDetails = this.testCases['20020']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20021', async () => {
    const testDetails = this.testCases['20021']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20022', async () => {
    const testDetails = this.testCases['20022']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20024', async () => {
    const testDetails = this.testCases['20024']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test ANN-20025', async () => {
    const testDetails = this.testCases['20025']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })
*/
})
