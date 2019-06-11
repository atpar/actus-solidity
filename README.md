# **ACTUS** Solidity

[![Build Status](https://travis-ci.org/atpar/actus-solidity.svg?branch=master)](https://travis-ci.org/atpar/actus-solidity)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![npm version](http://img.shields.io/npm/v/actus-solidity.svg?style=flat)](https://npmjs.org/package/actus-solidity "View this project on npm")

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
| Görli    | 0x9240caa74A84C9b0648A1FB1fa5a7F4d9250C313 | 0x598e2Ea93b68F8a0B5fDb259E81ee59f10f7ac4A |
| Kovan    | 0xd48E171D4869271e0ED90C7B0F131a01988ab50e | 0xF3cff5a88aFf021976bb1Fa421Ed2f5d4C299E32 |
| Rinkeby  | 0xd48E171D4869271e0ED90C7B0F131a01988ab50e | 0xF3cff5a88aFf021976bb1Fa421Ed2f5d4C299E32 | 
| Ropsten  | 0xd48E171D4869271e0ED90C7B0F131a01988ab50e | 0xF3cff5a88aFf021976bb1Fa421Ed2f5d4C299E32 |

## Implemented Conventions
- [x] Contract-Role-Sign-Convention (for PAM)
- [x] Contract-Default-Convention

### Business-Day-Count-Conventions
- [ ] SCF (Shift/Calculate following)
- [ ] SCMF (Shift/Calculate modified following)
- [ ] CSF (Calculate/Shift following)
- [ ] CSMF (Calculate/Shift modified following)
- [ ] SCP (Shift/Calculate preceding)
- [ ] SCMP (Shift/Calculate modified preceding)
- [ ] CSP (Calculate/Shift preceding)
- [ ] CSMP (Calculate/Shift modified preceding)

### Year-Fraction-Conventions (Day-Count-Methods)
- [x] A/AISDA (Actual Actual ISDA)
- [x] A/360 (Actual Three Sixty)
- [x] A/365 (Actual Three Sixty Five)
- [ ] 30E/360ISDA (Thirty E Three Sixty ISDA)
- [x] 30E/360 (Thirty E Three Sixty)
- [ ] 30/360 (Thirty Three Sixty)
- [x] 1/1

### End-Of-Month-Conventions
- [x] Same Day Shift
- [x] End-Of-Month Shift
