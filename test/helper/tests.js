const { 
  parseTermsFromObject, 
  parseResultsFromObject,
  roundToDecimals,
  numberOfDecimals
} = require('./parser');

const TEST_TERMS_DIR = './actus-resources/tests/';
 

async function getTestCases (contract) {
  const testCases = require('../.' + TEST_TERMS_DIR + "actus-tests-" + contract + ".json");
  const testCaseNames = Object.keys(testCases);

  const parsedCases = {};
  testCaseNames.forEach( (name) => {
    const caseDetails = {};
    caseDetails['terms'] = parseTermsFromObject(testCases[name].terms);
    caseDetails['results'] = parseResultsFromObject(testCases[name].results);
    parsedCases[name] = caseDetails;
  });

  return parsedCases;
}

function compareTestResults (actualResults, expectedResults) {
  const numberOfEvents = (actualResults.length > expectedResults.length) ? actualResults.length : expectedResults.length;

  for (let i = 0; i < numberOfEvents; i++) {
    const actualEvent = actualResults[i];
    const expectedEvent = expectedResults[i];

    const decimalsEventValue = (numberOfDecimals(actualEvent.eventValue) < numberOfDecimals(expectedEvent.eventValue)) 
      ? numberOfDecimals(actualEvent.eventValue)
      : numberOfDecimals(expectedEvent.eventValue);

    const decimalsNominalValue = (numberOfDecimals(actualEvent.nominalValue) < numberOfDecimals(expectedEvent.nominalValue)) 
      ? numberOfDecimals(actualEvent.nominalValue)
      : numberOfDecimals(expectedEvent.nominalValue);

    const decimalsNominalAccrued = (numberOfDecimals(actualEvent.nominalAccrued) < numberOfDecimals(expectedEvent.nominalAccrued)) 
      ? numberOfDecimals(actualEvent.nominalAccrued)
      : numberOfDecimals(expectedEvent.nominalAccrued);

    assert.deepEqual({
      eventDate: actualEvent.eventDate,
      eventType: actualEvent.eventType,
      eventValue: roundToDecimals(actualEvent.eventValue, decimalsEventValue),
      nominalValue: roundToDecimals(actualEvent.nominalValue, decimalsNominalValue),
      nominalRate: actualEvent.nominalRate,
      nominalAccrued: roundToDecimals(actualEvent.nominalAccrued, decimalsNominalAccrued)
    }, {  
      eventDate: expectedEvent.eventDate,
      eventType: expectedEvent.eventType,
      eventValue: roundToDecimals(expectedEvent.eventValue, decimalsEventValue),
      nominalValue: roundToDecimals(expectedEvent.nominalValue, decimalsNominalValue),
      nominalRate: expectedEvent.nominalRate,
      nominalAccrued: roundToDecimals(expectedEvent.nominalAccrued, decimalsNominalAccrued)
    });
  }
}

module.exports = { getTestCases, compareTestResults }
