const PAMEngine = artifacts.require('PAMEngine.sol');

const { getTestCases, compareTestResults } = require('../../helper/tests');
const { parseToTestEvent, parseTermsToLifecycleTerms, parseTermsToGeneratingTerms} = require('../../helper/parser');
const {
  decodeProtoEvent,
  sortProtoEvents,
  removeNullProtoEvents
} = require('../../helper/schedule');

contract('PAMEngine', () => {

  const computeProtoEventScheduleSegment = async (terms, segmentStart, segmentEnd) => {
    const generatingTerms = parseTermsToGeneratingTerms(terms);
    const protoEventSchedule = [];
      
    protoEventSchedule.push(... await this.PAMEngineInstance.computeNonCyclicProtoEventScheduleSegment(
      generatingTerms,
      segmentStart,
      segmentEnd
    ));
    protoEventSchedule.push(... await this.PAMEngineInstance.computeCyclicProtoEventScheduleSegment(
      generatingTerms,
      segmentStart,
      segmentEnd,
      4 // FP
    ));
    protoEventSchedule.push(... await this.PAMEngineInstance.computeCyclicProtoEventScheduleSegment(
      generatingTerms,
      segmentStart,
      segmentEnd,
      8 // IP
    ));
    protoEventSchedule.push(... await this.PAMEngineInstance.computeCyclicProtoEventScheduleSegment(
      generatingTerms,
      segmentStart,
      segmentEnd,
      18 // RR
    ));
    
    return sortProtoEvents(removeNullProtoEvents(protoEventSchedule));
  }

  before(async () => {    
    this.PAMEngineInstance = await PAMEngine.new();
    this.testCases = await getTestCases('PAM');
  });

  const evaluateEventSchedule = async (terms) => {
    const lifecycleTerms = parseTermsToLifecycleTerms(terms);
    const generatingTerms = parseTermsToGeneratingTerms(terms);

    const initialState = await this.PAMEngineInstance.computeInitialState(lifecycleTerms, {});
    const protoEventSchedule = removeNullProtoEvents(await computeProtoEventScheduleSegment(
      generatingTerms,
      generatingTerms.contractDealDate,
      generatingTerms.maturityDate
    ));

    const evaluatedSchedule = [];
    let state = initialState;

    for (protoEvent of protoEventSchedule) {
      const { eventType, scheduleTime } = decodeProtoEvent(protoEvent);

      if (scheduleTime == 0) { break; }

      const payoff = await this.PAMEngineInstance.computePayoffForProtoEvent(
        lifecycleTerms,
        state,
        protoEvent,
        scheduleTime
      );
      const nextState = await this.PAMEngineInstance.computeStateForProtoEvent(
        lifecycleTerms, 
        state, 
        protoEvent, 
        scheduleTime
      );
      
      state = nextState;

      const eventTime = await this.PAMEngineInstance.computeEventTimeForProtoEvent(protoEvent, lifecycleTerms, {});

      evaluatedSchedule.push(parseToTestEvent(eventType, eventTime, payoff, state));
    }

    return evaluatedSchedule;
  };

  it('should yield the expected evaluated contract schedule for test PAM10001', async () => {
    const testDetails = this.testCases['10001'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test PAM10002', async () => {
    const testDetails = this.testCases['10002'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test PAM10003', async () => {
    const testDetails = this.testCases['10003'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);
  
    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test PAM10004', async () => {
    const testDetails = this.testCases['10004'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms'])

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test PAM10005', async () => {
    const testDetails = this.testCases['10005'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test PAM10006', async () => {
    const testDetails = this.testCases['10006'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test PAM10007', async () => {
    const testDetails = this.testCases['10007'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test PAM10008', async () => {
    const testDetails = this.testCases['10008'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test PAM10009', async () => {
    const testDetails = this.testCases['10009'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test PAM10010', async () => {
    const testDetails = this.testCases['10010'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test PAM10011', async () => {
    const testDetails = this.testCases['10011'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  /*
  // TODO: Purchase/Termination
  it('should yield the expected evaluated contract schedule for test PAM10012', async () => {
    const testDetails = this.testCases['10012'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });
  */

  // TODO: Precision Error
  // it('should yield the expected evaluated contract schedule for test PAM10013', async () => {
  //   const testDetails = this.testCases['10013'];
  //   const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

  //   compareTestResults(evaluatedSchedule, testDetails['results']);
  // });

  it('should yield the expected evaluated contract schedule for test PAM10014', async () => {
    const testDetails = this.testCases['10014'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test PAM10015', async () => {
    const testDetails = this.testCases['10015'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test PAM10016', async () => {
    const testDetails = this.testCases['10016'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test PAM10017', async () => {
    const testDetails = this.testCases['10017'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });
 
  it('should yield the expected evaluated contract schedule for test PAM10018', async () => {
    const testDetails = this.testCases['10018'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);    

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  // TODO: Purchase/Termination
  // it('should yield the expected evaluated contract schedule for test PAM10019', async () => {
  //   const testDetails = this.testCases['10019'];
  //   const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

  //   compareTestResults(evaluatedSchedule, testDetails['results']);
  // });

  /*
  // TODO: Rate Reset
  it('should yield the expected evaluated contract schedule for test PAM10020', async () => {
    const testDetails = this.testCases['10020'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test PAM10021', async () => {
    const testDetails = this.testCases['10021'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });

  it('should yield the expected evaluated contract schedule for test PAM10022', async () => {
    const testDetails = this.testCases['10022'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });
 
  it('should yield the expected evaluated contract schedule for test PAM10023', async () => {
    const testDetails = this.testCases['10023'];
    const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

    compareTestResults(evaluatedSchedule, testDetails['results']);
  });
  */

  // TODO: A365 issue
  // it('should yield the expected evaluated contract schedule for test PAM10024', async () => {
  //   const testDetails = this.testCases['10024'];
  //   const evaluatedSchedule = await evaluateEventSchedule(testDetails['terms']);

  //   compareTestResults(evaluatedSchedule, testDetails['results']);
  // });
});
