/*
    Copyright 2019 Finocial IO

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.0;

/**
*      Access control—that is, "who is allowed to do this thing"—is incredibly
*      important in the world of smart contracts. The access control of your
*      contract may govern who can mint tokens, vote on proposals, freeze transfers,
*      and many others. It is therefore critical to understand how you implement it, lest someone else
**/


import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract LoanProduct is Ownable {

  string public LOAN_PRODUCT_GLOBAL_NAME;
  uint public EXPIRY_DATE;
  // Currency Configuration
  uint public BASE_CURRENY;
  uint public DECIMAL_PLACES_FOR_CALCULATION;
  uint public INSTALLMENT_IN_MULTIPLES;

  // Loan Product Terms and Agreement

  // DEFAULT_PRINCIPAL
  // MIN_PRINCIPAL
  // MAX_PRINCIPAL
  //
  // // This means that how many a lender wish to have repayment or number of repayments for borrower to accept it could be 1 or n
  // DEFAULT_REPAYMENT
  // MIN_REPAYMENT
  // MAX_REPAYMENT
  // // Like loan repayment every 1 month , week , day
  // REPAID_EVERY
  //
  // //
  // MIN_INTEREST
  // MAX_INTEREST
  // DEFAULT_INTEREST
  //
  // // Difference of days when loan product if loan has been borrowed or accepted by borrower when does the repayent chart is prepared
  // DIFFERENCE_DAY
  //
  // // Loan settings
  // AMORTIZATION_TYPE // EQUAL INSTALLMENT or Equal Principal Payments - All principal amounts will be equal but the repayment and interest amounts will vary with each repayment.
  // REPAYMENT_STRAETGY // HOW ONE PAYMENT IS GOING TO GET  DEDUCTED IF There are parts like principal, interest, fees, penalty
  // INTEREST_METHOD // FLAT // DECLINING
  // INTEREST_CALCULATION_PERIOD // SAME As Repayment or Daily Will Calculate the interest on DAILY basis example: Month of February has 28 days and it will calculate interest for 28 days,
  // DAYS_YEAR
  // DAYS_MONTH
  // ARREARS_TOLERANCE
  // NO_DAYS_LOAN_OVERDUE_MOVING_TO_ARREARS
  // NO_DAYS_FOR_NPA
  //
  // // INTEREST_RECALCULATION
  // PRE_CLOSURE_INTEREST_RULE //TILL PRECLOUSRE_DATE or TILL FREQUENCY DATE
  // ADVANCE_PAYMENT_ADJUSTMENT //REDUCE EMI, REDUCE Installment, Reschedule Repayments
  // INTEREST_RECALCULATION_COMPUNDING_ON // None, Fee, Interest, Fees+Interest
  // FREQUENCY_FOR_RECALCULATE_OUTSTANDING_PRINCIPAL
  // FREQUENCY_INTERVAL_FOR_RECALCULATION
  // ARREARS_RECOGNIZATION_BASED_ON_ORIGINAL_SCHEDULE
  //
  // //FUNDS_COLLATERAL_SEttings
  //
  // FUNDS_ON_HOLD //true /false
  // HOLD_%
  //
  //






}
