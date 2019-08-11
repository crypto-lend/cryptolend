pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

library LoanMath {

    using SafeMath for uint256;

    uint256 constant DECIMAL_PLACES = 4;
    uint256 constant REPAYMENT_CYCLE_DURATION = 30;

    function getRepaymentNumber(
        uint256 loanStartDate,
        uint128 duration) view internal
        returns(
            uint256 repaymentNumber) {

        uint256 currentLoanDuration = now.sub(loanStartDate).div(1 minutes);

        if( currentLoanDuration <= duration ){
            repaymentNumber = currentLoanDuration.div(REPAYMENT_CYCLE_DURATION).add(1);
            return repaymentNumber;
        } else {
            return (0);
        }
    }

    function getAverageMonthlyInterest(uint256 principal, uint256 interestRate, uint256 totalLoanRepayments) pure internal returns(uint256){
        return (principal.mul(interestRate)).mul(totalLoanRepayments.add(1)).div(totalLoanRepayments.mul(10**DECIMAL_PLACES).mul(2));
    }

    function getPlatformFeeAmount(uint256 principal, uint256 platformFeeRate) pure internal returns(uint256 fees) {
        return  (principal.mul(platformFeeRate)).div(10**DECIMAL_PLACES);
    }

    function calculateRepaymentAmount(uint256 principal, uint256 monthlyInterest, uint256 fees, uint256 totalLoanRepayments) pure internal returns(uint256 amount) {

        amount = principal.div(totalLoanRepayments).add(monthlyInterest.add(fees));

        return amount;
    }

    function calculateTotalLoanRepaymentAmount(uint256 principal, uint256 interestRate, uint256 platformFeeRate, uint256 duration) pure internal returns(uint256) {
      uint256 totalRepayments = getTotalNumberOfRepayments(duration);
      uint256 interest = (principal.mul(interestRate)).mul(totalRepayments.add(1)).div((10**DECIMAL_PLACES).mul(2));
      uint256 fees = getPlatformFeeAmount(principal,platformFeeRate);
      return principal.add(interest.add(fees));

    }

    function getTotalNumberOfRepayments(uint256 duration) pure internal returns(uint256 totalRepaymentsNumber) {
        totalRepaymentsNumber = uint256(duration).div(REPAYMENT_CYCLE_DURATION);
        return totalRepaymentsNumber;
    }

    function getRemainingRepaymentAmount(uint256 totalRepaymentAmount, uint256 repaidAmount) pure internal returns(uint256) {
        return totalRepaymentAmount.sub(repaidAmount);
    }

    function calculateCollateralAmountToDeduct(uint256 remainingAmount, uint256 collateralValue) pure internal returns(uint256) {
        return remainingAmount.div(collateralValue);
    }

    function getTotalCollateralValue(uint256 collateralPrice, uint256 collateralAmount) pure internal returns(uint256) {
        return collateralAmount.mul(collateralPrice);
    }

}
