pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./LoanProduct.sol";

contract FinocialLoan {

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
        CollateralStatus collateralStatus;
    }

    struct LoanData {

        uint256 loanAmount;
        uint256 interest;
        uint128 duration;
        uint256 createdOn;
        uint256 startedOn;
        uint256 outstandingAmount;
        address borrower;
        address lender;
        LoanStatus loanStatus;
        CollateralData collateral;
        address loanProduct;

    }

    LoanData loan;

    IERC20 public ERC20;

    event CollateralTransferToLoanFailed(address, address, uint256);
    event CollateralTransferToLoanSuccessful(address, address, uint256);
    event FundTransferToLoanSuccessful(address, address, uint256);
    event FundTransferToBorrowerSuccessful(address, address, uint256);

    constructor(uint256 _loanAmount, uint128 _duration,
        uint256 _interest, address _collateralAddress,
        uint256 _collateralAmount, address _borrower, address _lender) public {
        loan.loanAmount = _loanAmount;
        loan.interest = _interest;
        loan.duration = _duration;
        loan.createdOn = now;
        loan.borrower = _borrower;
        loan.lender = _lender;
        loan.loanStatus = LoanStatus.INACTIVE;
        loan.collateral = CollateralData(_collateralAddress, _collateralAmount, CollateralStatus.WAITING);
    }

    function transferCollateralToLoan() public {

        ERC20 = IERC20(loan.collateral.collateralAddress);

        if(loan.collateral.collateralAmount > ERC20.allowance(msg.sender, address(this))) {
            emit CollateralTransferToLoanFailed(msg.sender, address(this), loan.collateral.collateralAmount);
            revert();
        }

        loan.collateral.collateralStatus = CollateralStatus.ARRIVED;
        loan.loanStatus = LoanStatus.ACTIVE;

        ERC20.transferFrom(msg.sender, address(this), loan.collateral.collateralAmount);

        emit CollateralTransferToLoanSuccessful(msg.sender, address(this), loan.collateral.collateralAmount);

    }

    function approveLoanRequest() public payable {

        require(msg.value >= loan.loanAmount, "Sufficient funds not transferred");
        require(loan.loanStatus == LoanStatus.ACTIVE, "Incorrect loan status");

        loan.lender = msg.sender;
        loan.loanStatus = LoanStatus.FUNDED;

        emit FundTransferToLoanSuccessful(msg.sender, address(this), msg.value);

        loan.startedOn = now;

        address(uint160(loan.borrower)).transfer(loan.loanAmount);

        emit FundTransferToBorrowerSuccessful(address(this), loan.borrower, loan.loanAmount);

    }

    function getLoanData() view public returns (uint256 _loanAmount, uint128 _duration,
        uint256 _interest, address _collateralAddress,
        uint256 _collateralAmount, address _borrower, address _lender) {
        return (loan.loanAmount, loan.duration, loan.interest, loan.collateral.collateralAddress,
            loan.collateral.collateralAmount, loan.borrower, loan.lender);
    }
}
