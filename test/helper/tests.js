const fs = require('fs')

const { 
  parseTermsFromObject, 
  parseResultsFromObject, 
  fromPrecision, 
  unixToISO 
} = require('./parser');

const TEST_TERMS_DIR = './actus-resources/tests/';
 

async function getTestCases ( contract ) {
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

module.exports = { getTestCases }
