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
* The above copyright notice and this permission notice shall be included in all
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
var Finocial = artifacts.require('./contracts/Finocial.sol');
var LoanCreator = artifacts.require('./contracts/LoanCreator.sol');
var StandardToken = artifacts.require('./contracts/StandardToken.sol');
var PriceFeeder = artifacts.require('./contracts/External/PriceFeeder.sol');
module.exports = async function(deployer, network, accounts) {

  deployer.deploy(Finocial);
  deployer.deploy(PriceFeeder);
  deployer.deploy(LoanCreator);

  /**
  * below deployment should be only for Development
  */
  const standardToken = await deployer.deploy(StandardToken, "Test Tokens", "TTT", 18, 10000000000);

}
