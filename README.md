# **ACTUS** Solidity

[![Build Status](https://travis-ci.org/atpar/actus-solidity.svg?branch=master)](https://travis-ci.org/atpar/actus-solidity)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![npm version](http://img.shields.io/npm/v/actus-solidity.svg?style=flat)](https://npmjs.org/package/actus-solidity "View this project on npm")

**DISCLAIMER: THIS IS A WORK IN PROGRESS AND NOT AUDITED. USE IT AT YOUR OWN RISK.**

Solidity implementation of **ACTUS** Contract Types (https://www.actusfrf.org/algorithmic-standard)

Demo: [**ACTUS Solidity Calculator**](https://www.atpar.io/actus-solidity-tool/dist/index.html) running on Görli Testnet.

## Smart Contracts

### Core
Contains banking-grade financial logic such as ACTUS day-count & end-of-month conventions, ACTUS datatypes and floating point arithmetic used throughout all ACTUS engines. 

### Engines
Contains ACTUS state machine engines for each ACTUS Contract Type. An Engine implements the state transition & payoff functions and the schedule generation logic for an ACTUS Contract Type. Engines are stateless smart contracts, thus can be used on-chain as well as off-chain (e.g. by using the EVM as a TEE).

## Development

### Requirements
- `NPM` (>=6.8.0)
- `truffle` and `ganache-cli`
- `jq` (only for generating artifacts)
```sh
npm install -g truffle
npm install -g ganache-cli
```

### Run
1. install dependencies
```sh
# contracts/
yarn install
```

2. deploy contracts and run tests
```sh
# contracts/
yarn test
```

### Deployments
| Network  | FloatMath                                  | PAMEngine                                  |
|----------|--------------------------------------------|--------------------------------------------|
| Görli    | 0x43A0949A2ddC4C79c76fFb52c43e6727385055ef | 0x8071beF6f7Ce023816Eba322428E46F22A41A5D5 |
| Kovan    | 0x28BdF7Aa723eAd1DeDd7788EF8E460ce33190E27 | 0x14Fa37eb13c8Bc8C1Ee9DF965857eC879A095D73 |
| Rinkeby  | 0x28BdF7Aa723eAd1DeDd7788EF8E460ce33190E27 | 0x14Fa37eb13c8Bc8C1Ee9DF965857eC879A095D73 | 
| Ropsten  | 0x28BdF7Aa723eAd1DeDd7788EF8E460ce33190E27 | 0x14Fa37eb13c8Bc8C1Ee9DF965857eC879A095D73 |

## Implemented Conventions
- [x] Contract-Role-Sign-Convention (for PAM)
- [x] Contract-Default-Convention

### Business-Day-Count-Conventions
- [x] SCF (Shift/Calculate following)
- [x] SCMF (Shift/Calculate modified following)
- [x] CSF (Calculate/Shift following)
- [x] CSMF (Calculate/Shift modified following)
- [x] SCP (Shift/Calculate preceding)
- [x] SCMP (Shift/Calculate modified preceding)
- [x] CSP (Calculate/Shift preceding)
- [x] CSMP (Calculate/Shift modified preceding)

### Year-Fraction-Conventions (Day-Count-Methods)
- [x] A/AISDA (Actual Actual ISDA)
- [x] A/360 (Actual Three Sixty)
- [x] A/365 (Actual Three Sixty Five)
- [ ] 30E/360ISDA (Thirty E Three Sixty ISDA)
- [x] 30E/360 (Thirty E Three Sixty)
- [ ] 30/360 (Thirty Three Sixty)
- [ ] BUS/252 (Business Two Fifty Two)
- [x] 1/1

### End-Of-Month-Conventions
- [x] Same Day Shift
- [x] End-Of-Month Shift
