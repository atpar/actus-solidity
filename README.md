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
| Görli    | 0x28dD300d7518F630fF7724e6292AC3f5F317Bb84 | 0x8aA89C3D119f2f3BE4709cDEE50c0acaab6F5ffB | 0x8E533B1af22E29B0FeF5D2Fd6DcC2dfD1be2269E |
| Kovan    | 0x8E533B1af22E29B0FeF5D2Fd6DcC2dfD1be2269E | 0x8Cc6f30555ed640252c7aDf214d061C9441EF445 | 0x6F71E63A636C8C2C592EF47EBfe023CAd725e923 |
| Rinkeby  | 0x53E3f61b38A9Ec180BdA2D969b70ec9925827f2F | 0x24e382D58f5dbdB02B7e5bd652CeD52309dB075d | 0x5cA2E34C49930f0C6E663672F38Dfc21C9a95382 |
| Ropsten  | 0x53E3f61b38A9Ec180BdA2D969b70ec9925827f2F | 0x24e382D58f5dbdB02B7e5bd652CeD52309dB075d | 0x5cA2E34C49930f0C6E663672F38Dfc21C9a95382 |

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
