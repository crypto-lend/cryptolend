#!/usr/bin/env bash

# if we are on master and it has a tag, prepare build artifacts for npm package
if [[ -v TRAVIS_TAG ]]
then
  npm install
  npm install -g truffle@5.0.10
  truffle compile --all
fi
