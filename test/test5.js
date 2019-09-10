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
var LoanContract = artifacts.require("./LoanContract.sol");
var LoanCreator = artifacts.require("./LoanCreator.sol");
var StandardToken = artifacts.require("./StandardToken.sol")
const helper = require("./truffleTestHelpers");
const web3 = provider()


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
  acceptedCollateralMetadata : metadata,
  interest: 100,
  ltv: 40,
  collateralAddress: "0x",
  collateralAmount: 5000,
  collateralPrice: web3.utils.toWei('0.00001', 'ether'),
  borrower: borrower,
  lender: lender,
  loanContractAddress: "0",
  //outstandingAmount: "0.00615",
  repayments: ["0.003105", "0.003045"]
};
  describe("Scenario 1: Create Loan Offer", () => {

    var finocial, loanContractAddress;

    before('Initialize and Deploy SmartContracts', async () => {
      finocial = await LoanCreator.new();
      standardToken = await StandardToken.new("Test Tokens", "TTT", 18, 10000000);

      await standardToken.transfer(borrower, 1000000, {
        from: admin,
        gas: 300000
      });

      loanOffer.collateralAddress = standardToken.address;
    });


    it('should create new loan offer and return loan contract address', async() => {

      var receipt = await finocial.createNewLoanOffer(loanOffer.loanAmount, loanOffer.duration,
        loanOffer.acceptedCollateralMetadata, {
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

      var finocialLoan = await LoanContract.at(loanOffer.loanContractAddress);
      var loan = await finocialLoan.getLoanData.call();

      assert.notEqual(loan, undefined, "Loan Data not correct");

    });

    it('should fund loan from the lender side', async() => {
      var finocialLoan = await LoanContract.at(loanOffer.loanContractAddress);
      await finocialLoan.transferFundsToLoan({
        from: lender,
        value: loanOffer.loanAmount,
        gas: 30000
    });

    var loan = await finocialLoan.getLoanData.call();

    assert.equal(loan[5], 3, "Loan Contract status is not FUNDED");
  });



  it('borrower should accept the loan createad by lender', async() => {
    var finocialLoan = await LoanContract.at(loanOffer.loanContractAddress);
    var receipt = await finocialLoan.acceptLoanOffer(loanOffer.interest, loanOffer.collateralAddress, loanOffer.collateralAmount, loanOffer.collateralPrice, loanOffer.ltv,{
      from: borrower,
      gas: 300000
    })
    
    //var checkInterestUpdate = receipt.logs[0].args[0];

    var loan = await finocialLoan.getLoanData.call();
    assert.equal(loan[12], loanOffer.borrower, "Correct borrower address not set");
    assert.equal(loan[2], loanOffer.interest, "Interest rate enrichment failed");
  })

  it('borrower should transfer the collateral once accepted the loan', async() => {

    await standardToken.approve(loanOffer.loanContractAddress, loanOffer.collateralAmount, {
      from: borrower,
      gas: 300000
    });

    var finocialLoan = await LoanContract.at(loanOffer.loanContractAddress);
    var borrower_previous_balance = await await web3.eth.getBalance(loanOffer.borrower);
    
    

    await finocialLoan.transferCollateralToLoan({
      from: borrower,
      gas: 300000
    })

    var loan = await finocialLoan.getLoanData.call();

    assert.equal(loan[5], 2, "Loan Contract status in not ACTIVE");
    assert.equal(loan[10], 1, "Loan Collateral status is not ARRIVED");
    assert.equal(await web3.eth.getBalance(loanOffer.borrower),
        parseInt(borrower_previous_balance) + parseInt(loanOffer.loanAmount),
        "Correct amount not transferred to BORROWER");
  })
    
    
   it("should get correct repayment amounts", async() => {

      var finocialLoan = await LoanContract.at(loanOffer.loanContractAddress);

      let count = 0;
      loanOffer.repayments.forEach(async function(repayment){
          ++count;
          var r = await finocialLoan.getRepaymentAmount.call(count);

          assert.equal(parseInt(r.amount), web3.utils.toWei(repayment, 'ether'), "Repayment " + count + " is not correct");
      });

    });
    
    // it("should be able to call make failed repayments", async() => {
         
       });


  });


})
