pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./FinocialLoan.sol";

contract Finocial is Ownable, Pausable {

    address[] public loans;

    constructor() public {

    }

    event LoanContractCreated(address, address);

    function createNewLoanRequest(uint256 _loanAmount, uint128 _duration,
        uint256 _interest, address _collateralAddress,
        uint256 _collateralAmount, uint256 _collateralPriceInETH) public returns(address _loanContractAddress) {

            _loanContractAddress = address (new FinocialLoan(_loanAmount, _duration, _interest, _collateralAddress, _collateralAmount, _collateralPriceInETH, msg.sender, address(0)));

            loans.push(_loanContractAddress);

            emit LoanContractCreated(msg.sender, _loanContractAddress);

            return _loanContractAddress;
    }

    function getAllLoans() public view returns(address[] memory){
        return loans;
    }

}
