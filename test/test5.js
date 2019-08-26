var Finocial = artifacts.require("./LoanContract.sol");
var FinocialLoan = artifacts.require("./LoanCreator.sol");
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
console.log(metdata);
metadata = web3.utils.asciiToHex(metdata.toString())
console.log(metadata);
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

  });


})
