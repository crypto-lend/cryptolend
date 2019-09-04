var LoanCreator = artifacts.require("./LoanContract.sol");
var LoanContract = artifacts.require("./LoanContract.sol");
var StandardToken = artifacts.require("./StandardToken.sol");
const helper = require("./truffleTestHelpers");

contract("Test Sept", function(accounts) {

  var admin = accounts[0];
  var borrower = accounts[1];
  var lender = accounts[2];

  var loanofferer = accounts[3];
  var loanofferAcceptor = accounts[4];

  var loanRequest = {
    loanAmount: web3.utils.toWei('0.006', 'ether'),
    duration: 60,
    interest: 100,
    collateralAddress: "0",
    collateralAmount: 5000,
    collateralPrice: web3.utils.toWei('0.00001', 'ether'),
    borrower: borrower,
    lender: lender,
    loanContractAddress: "0",
    //outstandingAmount: "0.00615",
    repayments: ["0.003105", "0.003045"]
  };

  var metadata = {ltv:1,int:50,sym:"SYM"};

  metadata = web3.utils.asciiToHex(metdata.toString());


  var loanOffer = {
    loanAmount: web3.utils.toWei('0.006', 'ether'),
    duration: 60,
    acceptedCollateralMetadata : metadata,
    interest: 100,
    ltv: 40,
    collateralAddress: "0",
    collateralAmount: 5000,
    collateralPrice: web3.utils.toWei('0.00001', 'ether'),
    borrower: loanofferAcceptor,
    lender: loanofferer,
    loanContractAddress: "0",
    //outstandingAmount: "0.00615",
    //repayments: ["0.003105", "0.003045"]
  };



  describe("Scenario 1: Loan Request Cycle - without getting to repayments", () => {

    var loanCreator, standardToken, loanContractAddress;

    before('Initialize and Deploy SmartContracts', async () => {

      loanCretor = await LoanCreator.new();
      standardToken = await StandardToken.new("Test Tokens", "TTT", 18, 10000000);

      await standardToken.transfer(borrower, 1000000, {
        from: admin,
        gas: 300000
      });

      loanRequest.collateralAddress = standardToken.address;
    });

    it('should create new loan request and return loan contract address', async() => {

      var receipt = await loanCretor.createNewLoanRequest(loanRequest.loanAmount, loanRequest.duration,
        loanRequest.interest, loanRequest.collateralAddress, loanRequest.collateralAmount, loanRequest.collateralPrice, {
        from: loanRequest.borrower,
        gas: 3000000
      });

	  // when txn is mined successfully. when block number != null it should give you loan contract address from logs
      loanRequest.loanContractAddress = receipt.logs[0].args[1];

      assert.notEqual(loanRequest.loanContractAddress, 0x0, "Loan Contract wasnt created correctly");

    });

	it('should initiate transfer of collateral', async() => {

		var receipt = await standardToken.approve(loanRequest.loanContractAddress, loanRequest.collateralAmount, {
        from: loanRequest.borrower,
        gas: 300000
      });

	    // check for this transaction mined then only prompt for actual transfer after borrower's approval
	});

	if('should transfer collateral to loanContract', async() => {

	    var loanContract = await LoanContract.at(loanRequest.loanContractAddress);

        await loanContract.transferCollateralToLoan({
        from: loanRequest.borrower,
        gas: 300000
      });

		 var loan = await loanContract.getLoanData.call();

         assert.equal(loan[5], 2, "Loan Contract status in not ACTIVE");
         assert.equal(loan[10], 1, "Loan Collateral status is not ARRIVED");
        // what does asserting to 1 mean?
	});


    it('should return all loans', async() => {

      var loans = await loanCretor.getAllLoans.call();

      assert.notEqual(loans.length, 0, "Loans not returned correctly");

    });


    it('should get loan data from loan contract', async() => {

      var loanContract = await LoanContract.at(loanRequest.loanContractAddress);
      var loan = await loanContract.getLoanData.call();

      assert.notEqual(loan, undefined, "Loan Data not correct");
      // UI job would be filtering on the loan status = request
    });


    it('should approve loan request and transfer funds to borrower', async() => {

      var borrower_previous_balance = await await web3.eth.getBalance(loanRequest.borrower);

      var loanContract = await LoanContract.at(loanRequest.loanContractAddress);

      var receipt = await loanContract.approveLoanRequest({
        from: loanRequest.lender,
        value: loanRequest.loanAmount,
        gas: 300000
      });

      var loan = await loanContract.getLoanData.call();

      assert.equal(loan[5], 3, "Loan Contract status is not FUNDED");
      assert.equal(await web3.eth.getBalance(loanRequest.borrower),
        parseInt(borrower_previous_balance) + parseInt(loanRequest.loanAmount),
        "Correct amount not transferred to BORROWER");
      assert.equal(loan[13], loanRequest.lender, "Correct lender address not set");
    });


});


  describe("Scenario Provable - Try to update price. Test PriceFeeder", () => {



});


  describe("Scenario 2: Loan Offer Cycle - Without getting to repayments", () => {

    var loanCreator, standardToken, loanContractAddress;

    before('Initialize and Deploy SmartContracts', async () => {

      loanCretor = await LoanCreator.new();
      standardToken = await StandardToken.new("Test Tokens", "TTT", 18, 10000000);

      await standardToken.transfer(loanOffer.borrower, 1000000, {
        from: admin,
        gas: 300000
      });

      //loanRequest.collateralAddress = standardToken.address;
	  // need more token contracts
    });

	 it('should create new loan offer and return loan contract address', async() => {

      var receipt = await loanCretor.createNewLoanOffer(loanOffer.loanAmount, loanOffer.duration,
        loanOffer.acceptedCollateralMetadata, {
        from: loanOffer.lender,
        gas: 3000000
      });

	  // when txn is mined successfully. when block number != null it should give you loan contract address from logs
      loanOffer.loanContractAddress = receipt.logs[0].args[1];

      assert.notEqual(loanOffer.loanContractAddress, 0x0, "Loan Contract wasnt created correctly");
    });

	if('should initiate and fund loan from lender', async() => {

		var loanContract = await LoanContract.at(loanOffer.loanContractAddress);
		var receipt = await loanContract.transferFundsToLoan({
        from: loanOffer.lender,
        value: loanOffer.loanAmount,
        gas: 300000});

		var loan = await loanContract.getLoanData.call();
        assert.equal(loan[5], 3, "Loan Contract status is not FUNDED");
	});

    it('should return all loans', async() => {

      var loans = await loanCretor.getAllLoans.call();

      assert.notEqual(loans.length, 0, "Loans not returned correctly");

    });


    it('should get loan data from loan contract', async() => {

      var loanContract = await LoanContract.at(loanOffer.loanContractAddress);
      var loan = await loanContract.getLoanData.call();

      assert.notEqual(loan, undefined, "Loan Data not correct");
      // UI job would be filtering on the loan status = offer
	  // UI job would be to prase metadata and display choices in front of borrower for each loan offers
    });

	// borrower selects take this loan ^ choices are presented

	// clicks submit on particular choice of collateral
	it('should accept+ enrich the loan', async() => {

		var loanContract = await LoanContract.at(loanOffer.loanContractAddress);
		var receipt = await loanContract.acceptNenrichLoan(loanOffer.interest, loanOffer.collateralAddress, loanOffer.collateralAmount, loanOffer.collateralPrice, loanOffer.ltv, {
        from: loanOffer.borrower,
        gas: 3000000
      })

	    //check for event
		console.log(receipt.logs);
       	var loan = await loanContract.getLoanData.call();
        assert.equal(loan[12], loanOffer.borrower, "Correct borrower address not set");

	});

	//next window prompt for collateral transfer
	it('should initiate transfer of collateral', async() => {

		var receipt = await standardToken.approve(loanOffer.loanContractAddress, loanOffer.collateralAmount, {
        from: loanOffer.borrower,
        gas: 300000
      });

	    // check for this transaction mined then only prompt for actual transfer after borrower's approval
	});

	if('should transfer collateral to loanContract', async() => {

    // hey let's check price here to meet LTV again and test price feeder?

	    var loanContract = await LoanContract.at(loanOffer.loanContractAddress);
		var borrower_previous_balance = await await web3.eth.getBalance(loanOffer.borrower);

        var receipt = await loanContract.transferCollateralToLoan({
        from: loanOffer.borrower,
        gas: 300000
      });

		var testAddress = receipt.logs[1].args[0];
		// should have went in the if scenario
		// also check for loanstartedOn event!

		// should trasnfer funds to borrower
		assert.equal(await web3.eth.getBalance(loanOffer.borrower),
        parseInt(borrower_previous_balance) + parseInt(loanOffer.loanAmount),
        "Correct amount not transferred to BORROWER");

		var loan = await loanContract.getLoanData.call();

         assert.equal(loan[5], 2, "Loan Contract status in not ACTIVE");
         assert.equal(loan[10], 1, "Loan Collateral status is not ARRIVED");

	});

});

})
