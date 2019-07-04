var Finocial = artifacts.require("./Finocial.sol");
var FinocialLoan = artifacts.require("./FinocialLoan.sol");
var StandardToken = artifacts.require("./StandardToken.sol");

contract("Finocial", function(accounts) {

  var admin = accounts[0];
  var borrower = accounts[1];
  var lender = accounts[2];

  describe("Scenario 1: Create Loan Request", () => {

    var finocial, standardToken, loanContractAddress;

    before('Initialize and Deploy SmartContracts', async () => {

      finocial = await Finocial.new();
      standardToken = await StandardToken.new("Test Tokens", "TTT", 18, 10000000);

      await standardToken.transfer(borrower, 10000, {
        from: admin,
        gas: 300000
      });
    });

    it('should create new loan request and return loan contract address', async() => {

      var receipt = await finocial.createNewLoanRequest(web3.utils.toWei('10', 'ether'), 10, 2, standardToken.address, 100, {
        from: borrower,
        gas: 3000000
      });

      loanContractAddress = receipt.logs[0].args[1];

      assert.notEqual(loanContractAddress, 0x0, "Loan Contract wasnt created correctly");

    });

    it('should return all loans', async() => {

      var loans = await finocial.getAllLoans.call();

      assert.notEqual(loans.length, 0, "Loans not returned correctly");

    });

    it('should get loan data from loan contract', async() => {

      var finocialLoan = await FinocialLoan.at(loanContractAddress);
      var loan = await finocialLoan.getLoanData.call();

      assert.notEqual(loan, undefined, "Loan Data not correct");

    })

  })
})
