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
| Network  | ANNEngine                                  | PAMEngine                                  | SignedMath                                 |
|----------|--------------------------------------------|--------------------------------------------|--------------------------------------------|
| Görli    | 0xBDB1624D894A62b4fB3B3D9bE20b1F69Ba969cD4 | 0x27bd9D7c156AF2BC60e0B2b458D716e080066697 | 0xA439Cb9be1e31358FeD7cFEc57eE6B874a7a3289 |
| Kovan    | 0xBDB1624D894A62b4fB3B3D9bE20b1F69Ba969cD4 | 0x27bd9D7c156AF2BC60e0B2b458D716e080066697 | 0xA439Cb9be1e31358FeD7cFEc57eE6B874a7a3289 |
| Rinkeby  | 0x79aFF6FaC942ad4CA873FCE04620DcC3870c90CC | 0x28dD300d7518F630fF7724e6292AC3f5F317Bb84 | 0x8aA89C3D119f2f3BE4709cDEE50c0acaab6F5ffB |
| Ropsten  | 0x79aFF6FaC942ad4CA873FCE04620DcC3870c90CC | 0x28dD300d7518F630fF7724e6292AC3f5F317Bb84 | 0x8aA89C3D119f2f3BE4709cDEE50c0acaab6F5ffB |

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
