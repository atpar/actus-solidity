const fs = require('fs')

const { 
  parseTermsFromPath, 
  parseResultsFromPath, 
  fromPrecision, 
  unixToISO 
} = require('../../actus-resources/parser');

const TEST_TERMS_FILE_CSV = './actus-resources/ref-test-terms/pam-test-terms.csv';
const TEST_RESULTS_DIR_CSV = './actus-resources/ref-test-results/';
const TEST_TERMS_DIR = './actus-resources/test-terms/';
const TEST_RESULTS_DIR = './actus-resources/test-results/';
 

async function getTestCases () {
  if (fs.existsSync(TEST_TERMS_FILE_CSV)) {
    return parseTermsFromPath(TEST_TERMS_FILE_CSV);
  }

  const testCases = {};
  fs.readdirSync(TEST_TERMS_DIR).forEach((fileName) => {
    if (fileName.split('.')[1] !== 'json') { return; }
    const testCaseName = Number(fileName.split('.')[0].split('-')[2]);
    testCases[testCaseName] = require('../.' + TEST_TERMS_DIR + fileName);
  });

  return testCases;
}

async function getDefaultTerms () {
  return (await getTestCases())['10001'];
}

async function getTestResults () {
  const testResults = {};
  
  if (fs.existsSync(TEST_RESULTS_DIR_CSV)) {
    const files = [];

    fs.readdirSync(TEST_RESULTS_DIR_CSV).forEach((fileName) => {
      if (fileName.split('.')[1] !== 'csv') { return; }
      files.push(fileName);
    });

    let promises = files.map(async (fileName) => {
      const result = await parseResultsFromPath(TEST_RESULTS_DIR_CSV + fileName);
      let testName = fileName.split('.')[0].slice(9, 14);
      testResults[testName] = result;
    });

    await Promise.all(promises);
  } else {
    fs.readdirSync(TEST_RESULTS_DIR).forEach((fileName) => {
      if (fileName.split('.')[1] !== 'json') { return; }
      const testResultName = Number(fileName.split('.')[0].split('-')[2]);
      testResults[testResultName] = require('../.' + TEST_RESULTS_DIR + fileName);
    });
  }

  return testResults;
}

function toTestEvent (contractEvent, contractState) {
  return {
    'eventDate': unixToISO(contractEvent['scheduledTime']),
    'eventType': contractEvent['eventType'],
    'eventValue': fromPrecision(contractEvent['payoff']),
    'nominalValue': fromPrecision(contractState['nominalValue']),
    'nominalRate': fromPrecision(contractState['nominalRate']),
    'nominalAccrued': fromPrecision(contractState['nominalAccrued'])
  };
}

module.exports = { getTestCases, getDefaultTerms, getTestResults, toTestEvent }
