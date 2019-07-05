const PAMEngine = artifacts.require('PAMEngine.sol')

const { getTestCases } = require('../helper/tests')
const { parseEventFromEth } = require('../helper/parser')
const { removeNullEvents } = require('../helper/schedule')


contract('PAMEngine', () => {

  before(async () => {    
    this.PAMEngineInstance = await PAMEngine.new()
    this.testCases = await getTestCases( "PAM" )
  })

  const evaluateEventSchedule = async (contractTerms) => {
    const initialContractState = await this.PAMEngineInstance.computeInitialState(contractTerms, {})
    const protoEventSchedule = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      contractTerms,
      contractTerms.statusDate,
      contractTerms.maturityDate
    )

    const evaluatedSchedule = []
    let contractState = initialContractState

    for (let i = 0; i < protoEventSchedule.length; i++) {
      if (protoEventSchedule[i].scheduledTime == 0) { break; }
      const { 0: nextContractState, 1: contractEvent } = await this.PAMEngineInstance.computeNextStateForProtoEvent(
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
    const terms = this.testCases['10001'].terms
    const initialState = await this.PAMEngineInstance.computeInitialState(terms, {})
    assert.isTrue(Number(initialState['lastEventTime']) === Number(terms['statusDate']))
  })

  it('should yield all events', async () => {
    const terms = this.testCases['10001'].terms
    let protoEventSchedule = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      terms, 
      terms['statusDate'],
      terms['maturityDate'],
    )
    assert.isTrue(removeNullEvents(protoEventSchedule).length > 0)
  })

  it('should yield correct segment of events', async () => {
    const terms = this.testCases['10001'].terms
    const entireProtoEventSchedule = removeNullEvents(
      await this.PAMEngineInstance.computeProtoEventScheduleSegment(
        terms, 
        terms['statusDate'],
        terms['maturityDate'],
      )
    )

    let protoEventSchedule = []
    let lastEventTime = terms['statusDate'] 
    let timestamp = terms['statusDate'] + (terms['maturityDate'] - terms['statusDate']) / 4

    response = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      terms, 
      lastEventTime,
      timestamp
    )
    protoEventSchedule = [...response]

    lastEventTime = timestamp
    timestamp = terms['statusDate'] + (terms['maturityDate'] - terms['statusDate']) / 2

    response = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      terms, 
      lastEventTime,
      timestamp
    )
    protoEventSchedule = [...protoEventSchedule, ...response]
    
    lastEventTime = timestamp
    timestamp = terms['maturityDate']

    response = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
      terms, 
      lastEventTime,
      timestamp
    )
    protoEventSchedule = [...protoEventSchedule, ...response]
    
    protoEventSchedule = removeNullEvents(protoEventSchedule)
    assert.isTrue(protoEventSchedule.toString() === entireProtoEventSchedule.toString())
  })

  it('should yield the next contract state and the contract events', async() => {
    const terms = this.testCases['10001'].terms
    const initialState = await this.PAMEngineInstance.computeInitialState(terms, {})
    await this.PAMEngineInstance.computeNextState(terms, initialState, terms['maturityDate'])
  })

  it('should yield the expected evaluated contract schedule for test PAM10001', async () => {
    const testDetails = this.testCases['10001']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test PAM10002', async () => {
    const testDetails = this.testCases['10002']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  /*
  // TODO: implement AISDA
  it('should yield the expected evaluated contract schedule for test PAM10003', async () => {
    const testDetails = this.testCases['10003']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])
  
    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })
  */

  it('should yield the expected evaluated contract schedule for test PAM10004', async () => {
    const testDetails = this.testCases['10004']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test PAM10005', async () => {
    const testDetails = this.testCases['10005']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  /*
    // TODO: implement BDC
  it('should yield the expected evaluated contract schedule for test PAM10006', async () => {
    const testDetails = this.testCases['10006']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

    // TODO: implement BDC
  it('should yield the expected evaluated contract schedule for test PAM10007', async () => {
    const testDetails = this.testCases['10007']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

    // TODO: implement BDC
  it('should yield the expected evaluated contract schedule for test PAM10008', async () => {
    const testDetails = this.testCases['10008']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

    // TODO: implement BDC
  it('should yield the expected evaluated contract schedule for test PAM10009', async () => {
    const testDetails = this.testCases['10009']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

    // TODO: implement BDC
  it('should yield the expected evaluated contract schedule for test PAM10010', async () => {
    const testDetails = this.testCases['10010']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  // TODO: implement BDC
  it('should yield the expected evaluated contract schedule for test PAM10011', async () => {
    const testDetails = this.testCases['10011']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })
  */

  /*
  // TODO: Purchase/Termination
  it('should yield the expected evaluated contract schedule for test PAM10012', async () => {
    const testDetails = this.testCases['10012']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })
  */

  /*
  it('should yield the expected evaluated contract schedule for test PAM10013', async () => {
    const testDetails = this.testCases['10013']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })
  */

  it('should yield the expected evaluated contract schedule for test PAM10014', async () => {
    const testDetails = this.testCases['10014']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test PAM10015', async () => {
    const testDetails = this.testCases['10015']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test PAM10016', async () => {
    const testDetails = this.testCases['10016']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test PAM10017', async () => {
    const testDetails = this.testCases['10017']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })
 
  it('should yield the expected evaluated contract schedule for test PAM10018', async () => {
    const testDetails = this.testCases['10018']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  /*
  // TODO: Purchase/Termination
  it('should yield the expected evaluated contract schedule for test PAM10019', async () => {
    const testDetails = this.testCases['10019']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })
  */

  /*
  // TODO: Rate Reset
  it('should yield the expected evaluated contract schedule for test PAM10020', async () => {
    const testDetails = this.testCases['10020']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test PAM10021', async () => {
    const testDetails = this.testCases['10021']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })

  it('should yield the expected evaluated contract schedule for test PAM10022', async () => {
    const testDetails = this.testCases['10022']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })
 
  it('should yield the expected evaluated contract schedule for test PAM10023', async () => {
    const testDetails = this.testCases['10023']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  }) 
  */

  /*
  // TODO: A365 issue
  it('should yield the expected evaluated contract schedule for test PAM10024', async () => {
    const testDetails = this.testCases['10024']
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    assert.deepEqual(evaluatedSchedule, testDetails['results'])
  })
  */

})
