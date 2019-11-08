const web3Utils = require('web3-utils');
const BigNumber = require('bignumber.js');

// const EventDefinitions = require('../../actus-resources/definitions/EventDefinitions.json');
const EventDefinitions = require('actus-dictionary/actus-dictionary-event.json').event;
const TermsDefinitions = require('actus-dictionary/actus-dictionary-terms.json').terms;
const CoveredTerms = require('../../actus-resources/definitions/covered-terms.json');

const PRECISION = 18; // solidity precision


const isoToUnix = (date) => {
  return (new Date(date + 'Z')).getTime() / 1000;
}

const unixToISO = (unix) => {
  return new Date(unix * 1000).toISOString();
}

const toHex = (value) => {  
  return web3Utils.asciiToHex(value);
}

const getIndexOfAttribute = (attribute, value) => {
  return TermsDefinitions[attribute].allowedValues.indexOf(value);
}

const toPrecision = (value) => {
  return web3Utils.toHex(new BigNumber(value).shiftedBy(PRECISION));
}

const fromPrecision = (value) => {
  return (new BigNumber(value).shiftedBy(-PRECISION).toNumber());
}

const roundToDecimals = (value, decimals) => {
  decimals = (decimals > 2) ? (decimals - 2) : decimals;
  // console.log(value, decimals, numberOfDecimals(value));
 
  const roundedValue = Number(BigNumber(value).decimalPlaces(decimals));
  const decimalDiff = decimals - numberOfDecimals(roundedValue);

  if (decimalDiff > 0) {
    // return Number(String(value).substring(0, String(value).length - (numberOfDecimals(value) - decimals)));  
    return Number(value.toFixed(decimals));
  }

  return roundedValue; 
}

const numberOfDecimals = (number) => {
  return (String(number).split('.')[1] || []).length;
}

const parseCycleToIPS = (cycle) => {
  if (!cycle || cycle === '') { return { i: 0, p: 0, s: 0, isSet: false }; }

  const pOptions = ['D', 'W', 'M', 'Q', 'H', 'Y'];

  let i = String(cycle).slice(0, -2);
  let p = pOptions.indexOf(String(cycle).slice(-2, -1));
  let s = (String(cycle).slice(-1) === '+') ? 0 : 1;

  return { i: i, p: p, s: s, isSet: true };
}

const parsePeriodToIP = (period) => {
  if (!period  || period === '') { return { i: 0, p: 0, isSet: false }; }

  const pOptions = ['D', 'W', 'M', 'Q', 'H', 'Y'];

  let i = String(cycle).slice(0, -2);
  let p = pOptions.indexOf(String(cycle).slice(-2, -1));

  return { i: i, p: p, isSet: true };
}

const parseTermsFromObject = (terms) => {
  const parsedTerms = {};

  for (const attribute of CoveredTerms) {
    const value = terms[attribute];

    // console.log(attribute); 

    if (TermsDefinitions[attribute].type === 'Enum' || TermsDefinitions[attribute].type === 'Enum[]') {
      parsedTerms[attribute] = (value) ? getIndexOfAttribute(attribute, value) : 0;
    } else if (TermsDefinitions[attribute].type === 'Varchar') {
      parsedTerms[attribute] = toHex((value) ? value : '');
    } else if (TermsDefinitions[attribute].type === 'Real') {
      parsedTerms[attribute] = (value) ? toPrecision(value) : 0;
    } else if (TermsDefinitions[attribute].type === 'Timestamp') {
      parsedTerms[attribute] = (value) ? isoToUnix(value) : 0;
    } else if (TermsDefinitions[attribute].type === 'Cycle') {
      parsedTerms[attribute] = parseCycleToIPS(value);
    } else if (TermsDefinitions[attribute].type === 'Period') {
      parsedTerms[attribute] = parsePeriodToIP(value);
    } else if (TermsDefinitions[attribute].type === 'ContractStructure') {
      parsedTerms[attribute] = { object: toHex(''), contractReferenceType: 0, contractReferenceRole: 0 };
    }
  }

  parsedTerms['currency'] = '0x0000000000000000000000000000000000000000';

  return parsedTerms;
}

const parseResultsFromObject = (schedule) => {  
  const parsedResults = [];

  for (const event of schedule) {
    const eventTypeIndex = EventDefinitions.eventType.allowedValues.indexOf(event['eventType']);

    if (eventTypeIndex === 0) { continue; } // filter out AD events
    parsedResults.push({
      eventDate: new Date(event['eventDate'] + 'Z').toISOString(),
      eventType: eventTypeIndex.toString(),
      eventValue: Number(event['eventValue']),
      notionalPrincipal: Number(event['notionalPrincipal']),
      nominalInterestRate: Number(event['nominalInterestRate']),
      accruedInterest: Number(event['accruedInterest']),
    });
  }

  return parsedResults;
}

function parseToTestEvent (eventType, eventTime, payoff, state) {
  return {
    eventDate: unixToISO(eventTime),
    eventType: String(eventType),
    eventValue: fromPrecision(payoff),
    notionalPrincipal: fromPrecision(state['notionalPrincipal']),
    nominalInterestRate: fromPrecision(state['nominalInterestRate']),
    accruedInterest: fromPrecision(state['accruedInterest']),
  };
}

module.exports = { 
  parseTermsFromObject, 
  parseResultsFromObject, 
  parseToTestEvent, 
  fromPrecision, 
  unixToISO, 
  roundToDecimals, 
  numberOfDecimals
}
