pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./libs/LoanMath.sol";

contract FinocialLoan {

    using SafeMath for uint256;

    uint256 constant PLATFORM_FEE_RATE = 100;
    address constant WALLET_1 = 0x88347aeeF7b66b743C46Cb9d08459784FA1f6908;

    enum LoanStatus {
        INACTIVE,
        ACTIVE,
        FUNDED,
        REPAID,
        DEFAULT
    }

    enum CollateralStatus {
        WAITING,
        ARRIVED,
        RETURNED,
        DEFAULT
    }

    struct CollateralData {

        address collateralAddress;
        uint256 collateralAmount;
        uint256 collateralPrice;
        CollateralStatus collateralStatus;
    }

    struct LoanData {

        uint256 loanAmount;
        uint256 interestRate;
        uint128 duration;
        uint256 createdOn;
        uint256 startedOn;
        uint256 outstandingAmount;
        address borrower;
        address lender;
        LoanStatus loanStatus;
        CollateralData collateral;

    }

    LoanData loan;

    IERC20 public ERC20;

    uint256 public remainingCollateralAmount = 0;

    struct Repayment {
        uint256 repaidOn;
        uint256 amount;
        uint256 repaymentNumber;
    }

    uint256[] public repayments;

    event CollateralTransferToLoanFailed(address, uint256);
    event CollateralTransferToLoanSuccessful(address, uint256);
    event FundTransferToLoanSuccessful(address, uint256);
    event FundTransferToBorrowerSuccessful(address, uint256);
    event LoanRepaid(address, uint256);
    event CollateralTransferReturnedToBorrower(address, uint256);
    event CollateralClaimedByLender(address, uint256);

    modifier OnlyBorrower {
        require(msg.sender == loan.borrower, "Not Authorised");
        _;
    }

    modifier OnlyLender {
        require(msg.sender == loan.lender, "Not Authorised");
        _;
    }

    constructor(uint256 _loanAmount, uint128 _duration,
        uint256 _interestRate, address _collateralAddress,
        uint256 _collateralAmount, uint256 _collateralPriceInETH, address _borrower, address _lender) public {
        loan.loanAmount = _loanAmount;
        loan.interestRate = _interestRate;
        loan.duration = _duration;
        loan.createdOn = now;
        loan.borrower = _borrower;
        loan.lender = _lender;
        loan.loanStatus = LoanStatus.INACTIVE;
        loan.outstandingAmount = LoanMath.calculateTotalLoanRepaymentAmount(_loanAmount, _interestRate, PLATFORM_FEE_RATE, _duration);
        remainingCollateralAmount = _collateralAmount;
        loan.collateral = CollateralData(_collateralAddress, _collateralAmount, _collateralPriceInETH, CollateralStatus.WAITING);
    }

    function transferCollateralToLoan() public {

        ERC20 = IERC20(loan.collateral.collateralAddress);

        if(loan.collateral.collateralAmount > ERC20.allowance(msg.sender, address(this))) {
            emit CollateralTransferToLoanFailed(msg.sender, loan.collateral.collateralAmount);
            revert();
        }

        loan.collateral.collateralStatus = CollateralStatus.ARRIVED;
        loan.loanStatus = LoanStatus.ACTIVE;

        ERC20.transferFrom(msg.sender, address(this), loan.collateral.collateralAmount);

        emit CollateralTransferToLoanSuccessful(msg.sender, loan.collateral.collateralAmount);

    }

    function approveLoanRequest() public payable {

        require(msg.value >= loan.loanAmount, "Sufficient funds not transferred");
        require(loan.loanStatus == LoanStatus.ACTIVE, "Incorrect loan status");

        loan.lender = msg.sender;
        loan.loanStatus = LoanStatus.FUNDED;

        emit FundTransferToLoanSuccessful(msg.sender, msg.value);

        loan.startedOn = now;

        address(uint160(loan.borrower)).transfer(loan.loanAmount);

        emit FundTransferToBorrowerSuccessful(loan.borrower, loan.loanAmount);

    }

    function getLoanData() view public returns (
        uint256 _loanAmount, uint128 _duration, uint256 _interest, uint256 startedOn, LoanStatus _loanStatus,
        address _collateralAddress, uint256 _collateralAmount, uint256 _collateralPrice, CollateralStatus _collateralStatus,
        uint256 _outstandingAmount, uint256 _remainingCollateralAmount,
        address _borrower, address _lender) {

        return (loan.loanAmount, loan.duration, loan.interestRate, loan.startedOn, loan.loanStatus,
            loan.collateral.collateralAddress, loan.collateral.collateralAmount,
            loan.collateral.collateralPrice, loan.collateral.collateralStatus,
            loan.outstandingAmount, remainingCollateralAmount,
            loan.borrower, loan.lender);

    }

    function getPaidRepaymentsCount() view public returns (uint256) {
      return repayments.length;
    }

    function getAllPaidRepayments() view public returns(uint256[] memory){
      return repayments;
    }

    function getCurrentRepaymentNumber() view public returns(uint256) {
      return LoanMath.getRepaymentNumber(loan.startedOn, loan.duration);
    }

    function getRepaymentAmount(uint256 repaymentNumber) view public returns(uint256 amount, uint256 monthlyInterest, uint256 fees){

        uint256 totalLoanRepayments = LoanMath.getTotalNumberOfRepayments(loan.duration);

        monthlyInterest = LoanMath.getAverageMonthlyInterest(loan.loanAmount, loan.interestRate, totalLoanRepayments);

        if(repaymentNumber == 1)
            fees = LoanMath.getPlatformFeeAmount(loan.loanAmount, PLATFORM_FEE_RATE);
        else
            fees = 0;

        amount = LoanMath.calculateRepaymentAmount(loan.loanAmount, monthlyInterest, fees, totalLoanRepayments);

        return (amount, monthlyInterest, fees);
    }

    function repayLoan() public payable {

        require(now <= loan.startedOn + loan.duration * 1 minutes, "Loan Duration Expired");

        uint256 repaymentNumber = LoanMath.getRepaymentNumber(loan.startedOn, loan.duration);

        (uint256 amount, , uint256 fees) = getRepaymentAmount(repaymentNumber);

        require(msg.value >= amount, "Required amount not transferred");

        if(fees != 0){
            transferToWallet1(fees);
        }
        uint256 toTransfer = amount.sub(fees);

        loan.outstandingAmount = loan.outstandingAmount.sub(msg.value);

        if(loan.outstandingAmount <= 0)
            loan.loanStatus = LoanStatus.REPAID;

        repayments.push(repaymentNumber);

        address(uint160(loan.lender)).transfer(toTransfer);

        emit LoanRepaid(msg.sender, amount);

    }

    function transferToWallet1(uint256 fees) private {
        address(uint160(WALLET_1)).transfer(fees);
    }

    function returnCollateralToBorrower() public OnlyBorrower {

        require(now > loan.startedOn + loan.duration * 1 minutes, "Loan Still Active");
        require(loan.collateral.collateralStatus != CollateralStatus.RETURNED, "Collateral Already Returned");

        ERC20 = IERC20(loan.collateral.collateralAddress);

        uint256 collateralAmountToDeduct = LoanMath.calculateCollateralAmountToDeduct(loan.outstandingAmount, loan.collateral.collateralPrice);

        loan.collateral.collateralStatus = CollateralStatus.RETURNED;

        remainingCollateralAmount = collateralAmountToDeduct;

        ERC20.transfer(msg.sender, loan.collateral.collateralAmount.sub(collateralAmountToDeduct));

        emit CollateralTransferReturnedToBorrower(msg.sender, loan.collateral.collateralAmount.sub(collateralAmountToDeduct));

    }

    function claimCollateralByLender() public OnlyLender {

        require(now > loan.startedOn + loan.duration * 1 minutes, "Loan Still Active");
        require(loan.loanStatus != LoanStatus.DEFAULT, "Collateral Claimed Already");

        if(loan.outstandingAmount > 0) {

            uint256 collateralAmountToTransfer = LoanMath.calculateCollateralAmountToDeduct(loan.outstandingAmount, loan.collateral.collateralPrice);

            remainingCollateralAmount = remainingCollateralAmount.sub(collateralAmountToTransfer);

            loan.loanStatus = LoanStatus.DEFAULT;

            ERC20 = IERC20(loan.collateral.collateralAddress);

            ERC20.transfer(msg.sender, collateralAmountToTransfer);

            emit CollateralClaimedByLender(msg.sender, collateralAmountToTransfer);
        }
    }

}
