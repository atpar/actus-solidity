# **ACTUS** Solidity

[![Build Status](https://travis-ci.org/atpar/actus-solidity.svg?branch=master)](https://travis-ci.org/atpar/actus-solidity)

Solidity implementation of **ACTUS** Contract Types (https://www.actusfrf.org/algorithmic-standard)

## Smart Contracts

### Core
Contains banking-grade financial logic such as ACTUS day-count & end-of-month conventions, ACTUS datatypes and floating point arithmetic used throughout all ACTUS engines. 

### Engines
Contains ACTUS state machine engines for each ACTUS Contract Type. An Engine implements the state transition & payoff functions and the schedule generation logic for an ACTUS Contract Type. An Engine is a stateless smart contract that can be used in various ways (e.g. on-chain or off-chain state derivation).

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
