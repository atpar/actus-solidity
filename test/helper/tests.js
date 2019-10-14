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

async function getDefaultTestTerms (contract) {
  const testCases = await getTestCases(contract);

  return testCases[Object.keys(testCases)[0]].terms;
}

function compareTestResults (actualResults, expectedResults) {
  const numberOfEvents = (actualResults.length > expectedResults.length) ? actualResults.length : expectedResults.length;

  for (let i = 0; i < numberOfEvents; i++) {
    const actualEvent = actualResults[i];
    const expectedEvent = expectedResults[i];

    const decimalsEventValue = (numberOfDecimals(actualEvent.eventValue) < numberOfDecimals(expectedEvent.eventValue)) 
      ? numberOfDecimals(actualEvent.eventValue)
      : numberOfDecimals(expectedEvent.eventValue);

    const decimalsNominalValue = (numberOfDecimals(actualEvent.notionalPrincipal) < numberOfDecimals(expectedEvent.notionalPrincipal)) 
      ? numberOfDecimals(actualEvent.notionalPrincipal)
      : numberOfDecimals(expectedEvent.notionalPrincipal);

    const decimalsNominalAccrued = (numberOfDecimals(actualEvent.accruedInterest) < numberOfDecimals(expectedEvent.accruedInterest)) 
      ? numberOfDecimals(actualEvent.accruedInterest)
      : numberOfDecimals(expectedEvent.accruedInterest);

    assert.deepEqual({
      eventDate: actualEvent.eventDate,
      eventType: actualEvent.eventType,
      eventValue: roundToDecimals(actualEvent.eventValue, decimalsEventValue),
      notionalPrincipal: roundToDecimals(actualEvent.notionalPrincipal, decimalsNominalValue),
      nominalInterestRate: actualEvent.nominalInterestRate,
      accruedInterest: roundToDecimals(actualEvent.accruedInterest, decimalsNominalAccrued)
    }, {  
      eventDate: expectedEvent.eventDate,
      eventType: expectedEvent.eventType,
      eventValue: roundToDecimals(expectedEvent.eventValue, decimalsEventValue),
      notionalPrincipal: roundToDecimals(expectedEvent.notionalPrincipal, decimalsNominalValue),
      nominalInterestRate: expectedEvent.nominalInterestRate,
      accruedInterest: roundToDecimals(expectedEvent.accruedInterest, decimalsNominalAccrued)
    });
  }
}

module.exports = { getTestCases, getDefaultTestTerms, compareTestResults }
