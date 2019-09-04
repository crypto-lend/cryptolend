/**
* MIT License
*
* Copyright (c) 2019 Finocial
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice ad this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
const Web3 = require('web3')
Oracle = artifacts.require("./PriceFeeder.sol");
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:9545'))
const { waitForEvent } = require('./truffleTestHelpers')


contract("Provable API query", function(accounts){
  let pricefrom
  const gasAmt = 3e6
  const address = accounts[0]

  beforeEach(async () => (
      { contract } = await Oracle.deployed(),
      { methods, events } = new web3.eth.Contract(
        contract._jsonInterface,
        contract._address
      )
    ))


    it('Should log a new Provable Query', async () => {
    const { events } = await methods
      .update('0x0d8775f648430679a709e98d2b0cb6250d2887ef')
      .send({
        from: address,
        gas: gasAmt
      })
    const description = events.LogNewProvableQuery.returnValues.description
    assert.strictEqual(
      description,
      'Provable query was sent, standing by for the answer...',
      'Provable query incorrectly logged!'
    )
  })


  it('Callback should log a new contract price', async () => {
    const {
      returnValues: {
        price
      }
    } = await waitForEvent(events.LogNewPrice)
    pricefrom = price
    assert.isAbove(
      parseFloat(price),
      0,
      'A price should have been retrieved from Provable call!'
    )
  })

})
