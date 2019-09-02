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
var FinocialLoan = artifacts.require("./LoanContract.sol");
var Finocial = artifacts.require("./LoanCreator.sol");
const helper = require("./truffleTestHelpers");
const web3 = require('web3');

const eth3 = new web3(helper.provider());

contract("Should Create Loan Offer", function(accounts) {

  var admin = accounts[0];
  var borrower = accounts[1];
  var lender = accounts[2];

  metdata =  {
  "array": [
    1,
    2,
    3
  ],
  "boolean": true,
  "color": "#82b92c",
  "null": null,
  "number": 123,
  "object": {
    "a": "b",
    "c": "d",
    "e": "f"
  },
  "string": "Hello World"
};
// converting the above
metadata = web3.utils.asciiToHex(metdata.toString())
var loanOffer = {
    loanAmount: web3.utils.toWei('0.006', 'ether'),
    duration: 60,
    acceptedCollateralsMetadata: metadata
  };

  describe("Scenario 1: Create Loan Offer", () => {

    var finocial, loanContractAddress;

    before('Initialize and Deploy SmartContracts', async () => {
      finocial = await Finocial.new();
    });


    it('should create new loan offer and return loan contract address', async() => {

      var receipt = await finocial.createNewLoanOffer(loanOffer.loanAmount, loanOffer.duration,
        loanOffer.acceptedCollateralsMetadata, {
        from: lender,
        gas: 3000000
      });

      loanOffer.loanContractAddress = receipt.logs[0].args[1];

      assert.notEqual(loanOffer.loanContractAddress, 0x0, "Loan offer Contract wasnt created correctly");

    });

    it('should return all loans', async() => {

      var loans = await finocial.getAllLoans.call();

      assert.notEqual(loans.length, 0, "Loans not returned correctly");

    });

    it('should get loan data from loan contract', async() => {

      var finocialLoan = await FinocialLoan.at(loanOffer.loanContractAddress);
      var loan = await finocialLoan.getLoanData.call();

      assert.notEqual(loan, undefined, "Loan Data not correct");

    });

    it('should fund loan from the lender side', async() => {

      var lender_previous_balance =  await web3.eth.getBalance(lender);

      var finocialLoan = await FinocialLoan.transferFundsToLoan({
        from: lender,
        value: loanOffer.loanAmount,
        gas: 30000
    });

    var loan = await finocialLoan.getLoanData.call();

    assert.equal(loan[4], 2, "Loan Contract status is not FUNDED");
    assert.equal(await web3.eth.getBalance(lender),
      parseInt(lender_previous_balance) + parseInt(loanOffer.loanAmount),
      "Correct amount not transferred to loan Contract");
    assert.equal(loan[12], lender, "Correct lender address not set");
  });


  it('borrower should accept the loan createad by lender', async() => {

    var finocialLoan = await FinocialLoan.acceptLoanOffer({

    })
  })

  it('borrower should transfer the collateral once accepted the loan', async() => {

    var finocialLoan = await FinocialLoan.transferCollateralToLoan({

    })
  })


  it('borrower makes  first repayment on time', async() => {

    var finocialLoan = await FinocialLoan.repayLoan({

    })
  })


  });


})
