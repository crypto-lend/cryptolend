var Finocial = artifacts.require("./Finocial.sol");
var FinocialLoan = artifacts.require("./FinocialLoan.sol");
var StandardToken = artifacts.require("./StandardToken.sol");
const helper = require("./truffleTestHelpers");

contract("Test 3", function(accounts) {

  var admin = accounts[0];
  var borrower = accounts[1];
  var lender = accounts[2];

  var loanRequest = {
    loanAmount: web3.utils.toWei('0.06', 'ether'),
    duration: 90,
    interest: 100,
    collateralAddress: "0",
    collateralAmount: 50000,
    collateralPrice: web3.utils.toWei('0.001', 'ether'),
    borrower: borrower,
    lender: lender,
    loanContractAddress: "0",
    outstandingAmount: "0.0618",
    repayments: ["0.021", "0.0204", "0.0204"]
  };

  describe("Scenario 1: All repayments paid", () => {

    var finocial, standardToken, loanContractAddress;

    before('Initialize and Deploy SmartContracts', async () => {

      finocial = await Finocial.new();
      standardToken = await StandardToken.new("Test Tokens", "TTT", 18, 10000000);

      await standardToken.transfer(borrower, 1000000, {
        from: admin,
        gas: 300000
      });

      loanRequest.collateralAddress = standardToken.address;
    });

    it('should create new loan request and return loan contract address', async() => {

      var receipt = await finocial.createNewLoanRequest(loanRequest.loanAmount, loanRequest.duration,
        loanRequest.interest, loanRequest.collateralAddress, loanRequest.collateralAmount, loanRequest.collateralPrice, {
        from: loanRequest.borrower,
        gas: 3000000
      });

      loanRequest.loanContractAddress = receipt.logs[0].args[1];

      assert.notEqual(loanRequest.loanContractAddress, 0x0, "Loan Contract wasnt created correctly");

    });

    it('should return all loans', async() => {

      var loans = await finocial.getAllLoans.call();

      assert.notEqual(loans.length, 0, "Loans not returned correctly");

    });

    it('should get loan data from loan contract', async() => {

      var finocialLoan = await FinocialLoan.at(loanRequest.loanContractAddress);
      var loan = await finocialLoan.getLoanData.call();

      assert.notEqual(loan, undefined, "Loan Data not correct");

    });

    it('should transfer collateral to loanContract', async() => {

      await standardToken.approve(loanRequest.loanContractAddress, loanRequest.collateralAmount, {
        from: loanRequest.borrower,
        gas: 300000
      });

      var finocialLoan = await FinocialLoan.at(loanRequest.loanContractAddress);

      await finocialLoan.transferCollateralToLoan({
        from: loanRequest.borrower,
        gas: 300000
      });

      var loan = await finocialLoan.getLoanData.call();

      assert.equal(loan[4], 1, "Loan Contract status in not ACTIVE");
      assert.equal(loan[8], 1, "Loan Collateral status is not ARRIVED");

    });

    it('should approve loan request and transfer funds to borrower', async() => {

      var borrower_previous_balance = await await web3.eth.getBalance(loanRequest.borrower);

      var finocialLoan = await FinocialLoan.at(loanRequest.loanContractAddress);

      await finocialLoan.approveLoanRequest({
        from: loanRequest.lender,
        value: loanRequest.loanAmount,
        gas: 300000
      });

      var loan = await finocialLoan.getLoanData.call();

      assert.equal(loan[4], 2, "Loan Contract status is not FUNDED");
      assert.equal(await web3.eth.getBalance(loanRequest.borrower),
        parseInt(borrower_previous_balance) + parseInt(loanRequest.loanAmount),
        "Correct amount not transferred to BORROWER");
      assert.equal(loan[12], loanRequest.lender, "Correct lender address not set");
    });

    it("should get correct repayment amounts", async() => {

      var finocialLoan = await FinocialLoan.at(loanRequest.loanContractAddress);

      let count = 0;
      loanRequest.repayments.forEach(async function(repayment){
          ++count;
          var r = await finocialLoan.getRepaymentAmount.call(count);

          assert.equal(parseInt(r.amount), web3.utils.toWei(repayment, 'ether'), "Repayment " + count + " is not correct");
      });

    });


    it("should be able to repay the first loan repayment and transfer fee to platform", async() => {

      var lender_previous_balance = await web3.eth.getBalance(loanRequest.lender);
      //var platform_previous_balance = await web3.eth.getBalance(loanRequest.lender);
      var finocialLoan = await FinocialLoan.at(loanRequest.loanContractAddress);

      var r1 = await finocialLoan.getRepaymentAmount.call(1);

      await finocialLoan.repayLoan({
        from: loanRequest.borrower,
        value: parseInt(r1.amount),
        gas: 300000
      });

      var loan = await finocialLoan.getLoanData.call();

      assert.equal(parseInt(loan[9]), parseInt(web3.utils.toWei(loanRequest.outstandingAmount, 'ether')) - parseInt(r1.amount), "Outstanding Amount for repayment number 1 is not correct");
      assert.equal(await web3.eth.getBalance(loanRequest.lender),
        parseInt(lender_previous_balance) + parseInt(r1.amount) - parseInt(r1.fees),
        "Correct amount not transferred to Lender");
    });

    it("should be able to repay the remaining loan repayment", async() => {

      var lender_previous_balance = await await web3.eth.getBalance(loanRequest.lender);

      var finocialLoan = await FinocialLoan.at(loanRequest.loanContractAddress);

      for(let i=1; i< loanRequest.repayments.length; i++){

          await helper.advanceTime(1980);

          var r = await finocialLoan.getRepaymentAmount.call(i+1);

          await finocialLoan.repayLoan({
            from: loanRequest.borrower,
            value: parseInt(r.amount),
            gas: 300000
          });

      };

      var loan = await finocialLoan.getLoanData.call();

      assert.equal(parseInt(loan[9]), 0, "Outstanding Amount after all repayments is not correct");
      // assert.equal(await web3.eth.getBalance(loanRequest.lender),
      //   parseInt(lender_previous_balance) + parseInt(r2.amount) - parseInt(r2.fees),
      //   "Correct amount not transferred to Lender");
    });

    // it("should get all paid repayment data", async() => {
    //
    //   var finocialLoan = await FinocialLoan.at(loanRequest.loanContractAddress);
    //
    //   var paidRepaymentsCount = await finocialLoan.getPaidRepaymentsCount.call();
    //
    //   var repayments = [];
    //   for(let i=0; i < paidRepaymentsCount; i++) {
    //       var repayment = await finocialLoan.repayments.call(0);
    //       repayments.push(repayment);
    //   }
    //
    //   assert.equal(parseInt(repayments[0].amount), web3.utils.toWei('0.003105', 'ether'),  )
    // })

    it('should return collateral to borrower after loan expiration', async() => {

      await helper.advanceTime(1980);

      var finocialLoan = await FinocialLoan.at(loanRequest.loanContractAddress);

      await finocialLoan.returnCollateralToBorrower({
        from: loanRequest.borrower,
        gas: 300000
      });

      var loan = await finocialLoan.getLoanData.call();

      assert.equal(loan[8], 2, "Collateral Status not set to RETURNED");
      assert.equal(parseInt(loan[10]), 0, "Complete Collateral not returned");

    });

  });

  describe("Scenario 2: Repayments defaulted", () => {

    var finocial, standardToken, loanContractAddress;

    before('Initialize and Deploy SmartContracts', async () => {

      finocial = await Finocial.new();
      standardToken = await StandardToken.new("Test Tokens", "TTT", 18, 10000000);

      await standardToken.transfer(borrower, 100000, {
        from: admin,
        gas: 300000
      });

      loanRequest.collateralAddress = standardToken.address;

      var receipt = await finocial.createNewLoanRequest(loanRequest.loanAmount, loanRequest.duration,
        loanRequest.interest, loanRequest.collateralAddress, loanRequest.collateralAmount, loanRequest.collateralPrice, {
        from: loanRequest.borrower,
        gas: 3000000
      });

      loanRequest.loanContractAddress = receipt.logs[0].args[1];

      await standardToken.approve(loanRequest.loanContractAddress, loanRequest.collateralAmount, {
        from: loanRequest.borrower,
        gas: 300000
      });

      var finocialLoan = await FinocialLoan.at(loanRequest.loanContractAddress);

      await finocialLoan.transferCollateralToLoan({
        from: loanRequest.borrower,
        gas: 300000
      });

      await finocialLoan.approveLoanRequest({
        from: loanRequest.lender,
        value: loanRequest.loanAmount,
        gas: 300000
      });

      var r1 = await finocialLoan.getRepaymentAmount.call(1);

      await finocialLoan.repayLoan({
        from: loanRequest.borrower,
        value: parseInt(r1.amount),
        gas: 300000
      });

      await helper.advanceTime(3960);

      var r3 = await finocialLoan.getRepaymentAmount.call(3);
      await finocialLoan.repayLoan({
        from: loanRequest.borrower,
        value: parseInt(r3.amount),
        gas: 300000
      });

      await helper.advanceTime(4000);

    });


    it("shouldn't let borrower repay loan after loan expiration", async() => {

      let addError;

      var finocialLoan = await FinocialLoan.at(loanRequest.loanContractAddress);

      var r2 = await finocialLoan.getRepaymentAmount.call(2);

      try {
        await finocialLoan.repayLoan({
          from: loanRequest.borrower,
          value: parseInt(r2.amount),
          gas: 300000
        });
      } catch (e) {
        addError = e
      }


      assert.notEqual(addError, undefined, 'Transaction should be reverted');

    });

    it('should return collateral to borrower partially', async() => {

      var finocialLoan = await FinocialLoan.at(loanRequest.loanContractAddress);

      await finocialLoan.returnCollateralToBorrower({
        from: loanRequest.borrower,
        gas: 300000
      });

      var loan = await finocialLoan.getLoanData.call();

      assert.equal(loan[8], 2, "Collateral Status not set to RETURNED");
      assert.notEqual(parseInt(loan[10]), 0, "Partial Collateral not returned");

    });

    it('should return remaining collateral to lender', async() => {

      var finocialLoan = await FinocialLoan.at(loanRequest.loanContractAddress);

      await finocialLoan.claimCollateralByLender({
        from: loanRequest.lender,
        gas: 300000
      });

      var loan = await finocialLoan.getLoanData.call();

      assert.equal(loan[4], 4, "Loan Status not set to DEFAULT");
      assert.equal(parseInt(loan[10]), 0, "Complete Collateral not returned");

    });

  });

})
