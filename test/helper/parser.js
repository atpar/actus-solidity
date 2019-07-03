const web3Utils = require('web3-utils')
const BigNumber = require('bignumber.js')
const csv = require('csvtojson')

const ContractEventDefinitions = require('../../actus-resources/definitions/ContractEventDefinitions.json')
const ContractTermsDefinitions = require('../../actus-resources/definitions/ContractTermsDefinitions.json')
const CoveredTerms = require('../../actus-resources/definitions/covered-terms.json')

const PRECISION = 18
const DIGITS = 10000000000000

const isoToUnix = (date) => {
  return (new Date(date + 'Z')).getTime() / 1000
}

const unixToISO = (unix) => {
  return new Date(unix * 1000).toISOString()
}

const toHex = (value) => {  
  return web3Utils.asciiToHex(value); // return web3Utils.toHex(value)
}

const getIndexOfAttribute = (attribute, value) => {
  return ContractTermsDefinitions[attribute].options.indexOf(value)
}

const toPrecision = (value) => {
  return web3Utils.toHex(new BigNumber(value).shiftedBy(PRECISION))
}

const fromPrecision = (value) => {
  return Math.round((value * 10 ** -PRECISION) * DIGITS) / DIGITS
}

const capitalize = (str) => {
  return String(str).charAt(0).toUpperCase() + String(str).slice(1);
}

const parseCycleToIPS = (cycle) => {
  if (cycle === '' || !cycle) { return { i: 0, p: 0, s: 0, isSet: false } }

  const pOptions = ['D', 'W', 'M', 'Q', 'H', 'Y']

  let i = String(cycle).slice(0, -2)
  let p = pOptions.indexOf(String(cycle).slice(-2, -1))
  let s = (String(cycle).slice(-1) === '+') ? 0 : 1

  return { i: i, p: p, s: s, isSet: true }
}


const parseTermsFromObject = (terms) => {
  const parsedTerms = {}

  for (const attribute of CoveredTerms) {
    const value = terms[attribute]

    if (ContractTermsDefinitions[attribute].type === 'enum') {
      parsedTerms[attribute] = (value) ? getIndexOfAttribute(attribute, value) : 0
    } else if (ContractTermsDefinitions[attribute].type === 'text') {
      parsedTerms[attribute] = toHex((value) ? value : '')
    } else if (ContractTermsDefinitions[attribute].type === 'number') {
      parsedTerms[attribute] = (value) ? toPrecision(value) : 0
    } else if (ContractTermsDefinitions[attribute].type === 'date') {
      parsedTerms[attribute] = (value) ? isoToUnix(value) : 0
    } else if (ContractTermsDefinitions[attribute].type === 'cycle') {
      parsedTerms[attribute] = parseCycleToIPS(value)
    }
  }

  parsedTerms['currency'] = '0x0000000000000000000000000000000000000000'

  return parsedTerms;
}

const parseResultsFromObject = (schedule) => {  
  const parsedResults = []

  for (const event of schedule) {
    const eventTypeIndex = ContractEventDefinitions.eventType.options.indexOf(event['eventType'])
    if (eventTypeIndex === 2) { continue } // filter out AD events
    parsedResults.push({
      'eventDate': new Date(event['eventDate'] + 'Z').toISOString(),
      'eventType': eventTypeIndex.toString(),
      'eventValue': Number(event['eventValue']),
      'nominalValue': Number(event['nominalValue']),
      'nominalRate': Number(event['nominalRate']),
      'nominalAccrued': Number(event['nominalAccrued'])
    })
  }

  return parsedResults
}

function parseEventFromEth (contractEvent, contractState) {
  return {
    'eventDate': unixToISO(contractEvent['actualEventTime']),
    'eventType': contractEvent['eventType'],
    'eventValue': fromPrecision(contractEvent['payoff']),
    'nominalValue': fromPrecision(contractState['nominalValue']),
    'nominalRate': fromPrecision(contractState['nominalRate']),
    'nominalAccrued': fromPrecision(contractState['nominalAccrued'])
  };
}

module.exports = { parseTermsFromObject, parseResultsFromObject, parseEventFromEth, fromPrecision, unixToISO }
