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
Oracle = artifacts.require("./External/PriceFeeder.sol");
contract("Provable API query", function(accounts){
  var admin = accounts[0];

  describe("Get Price From API", ()=> {
    var oracle;

    before('Initialize and Deploy SmartContracts', async () => {
      oracle = await Oracle.new();
    });

    it('should create new loan offer and return loan contract address', async() => {
      var receipt = await oracle.updatePrice( "0x0d8775f648430679a709e98d2b0cb6250d2887ef", {
        from: admin,
        gas: 3000000
      });

      oracleContractAddress = receipt.logs[0].args[1];

      assert.notEqual(oracleContractAddress, 0x0, "Oracle wasnt created correctly");

    });
  })
})
