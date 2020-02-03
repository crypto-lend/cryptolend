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
