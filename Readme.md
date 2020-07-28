# Crypto-lend (finocial)

[![Build Status](https://travis-ci.org/upscaletech/finocial.eth.svg?branch=master)](https://travis-ci.org/upscaletech/finocial)

Finocial Protocol has been created to provide a secure, flexible, open source foundation for decentralized loan marketplace on the Ethereum blockchain (as of now). We provide the pieces necessary to create a decentralized lending exchange, including the requisite lending assets, clearing and collateral pool infrastructure, enabling third parties to build applications for lending.

Join our telegram community to interact with members of our dev staff and other contributors.

## Future

We aim to build

`decentralized credit rating`
`collecting mechanism - external - internal`
`payment channels`

## Dependencies

This project uses Node.js version 8.10.0 - 8.11.3.

If you are running multiple versions of Node.js, consider using Node Version Manager (nvm). nvm is an easy way to configure and manage different Node.js versions to work with your projects.

## Getting Started?

A Makefile is provided for easy setup of the environment.

Some pre-requisites are required in order to utilize the Makefile.

`git clone https://github.com/crypto-lend/cryptolend.eth.git # clone this repository`

From here you will be able to use make commands assuming npm is already installed.

Assuming you have npm already, Install truffle

`make install truffle`

`make install_deps`

## Running ETH Bridge

`npx ethereum-bridge -a 9 -H 127.0.0.1 -p 9545 --dev`

## Tests

Start truffle and its development blockchain with

`make start_console`

Run the example migrations as well as the accompanying tests inside the truffle console

```
truffle(develop)> migrate --reset
truffle(develop)> test

```

### Running tests with coverage enabled

The most convenient way to run tests with coverage enabled is to run them with help of Docker orchestration. This ensures, that the coverage results will match the ones on Travis CI.

We are working on it.


## Contribution

Want to hack on Finocial Protocol? Awesome!

Finocial Protocol is an Open Source project and we welcome contributions of all sorts. There are many ways to help, from reporting issues, contributing code, and helping us improve our community.

Ready to jump in? Check docs.finocial.com/#contributing.
