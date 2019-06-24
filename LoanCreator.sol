pragma solidity^0.4.12;

import "./LoanContract.sol";
import './Utils/strings.sol';
import "./ENS/AbstractENS.sol";
import "./ENS/HashRegistrarSimplified.sol";
import "./Utils/ERC20.sol";

/**
    @title LoanCreator
    @notice The LoanCreator contract manages smartcredit Loans
    @dev The contract has references to the following external contracts:
            - Registrar Contract from ENS - To verify and transfer domain ownership
            - Reference to LoanContract contract: To deploy new loan contract
                    after fund arrival from lender. Lender will be owner of contract.
            - Loan: Struct type to store loan related information on loan creator contract
            - loans: mapping of a Loan with the orderBookId from the off-chain DB.
            - loanCounter: keeps record of the number of loan requests created.

*/

contract LoanCreator {

    using strings for *;

    AbstractENS public ens;
    Registrar public registrar;


    struct Loan {
        address borrower;
        uint256 principal;
        uint256 duration;
        uint256 interest;
        address tokenAddress;
        uint256 tokenAmount;
        address lender;
        uint256 loanId;
        uint256 fundAmount;
        address loanContractAddr;
    }

    mapping(uint => Loan) public loans;

    uint public loanCounter;

    //Loan Creator contract owner
    address private _owner;

    event FundsTransferedToBorrower(address indexed contractAddress, address indexed borrower);
    event FundsArrived(address indexed from, address indexed to, uint indexed loanId, uint256 amount);
    event LoanContractCreated(address indexed from, uint indexed loanId, address indexed lender, address loan);
    event CollateralDetailsUpdated(address indexed borrower, uint indexed orderBookId);
    event CollateralTransferedToLoan(address indexed from, address indexed to, uint256 indexed loanId);


    modifier onlyOwner(){
        require(msg.sender == _owner);
        _;
    }

    /**
     * constructor to set the loan creator contract deployer as owner
    */
    constructor() public{
        _owner = msg.sender;
    }


    /**
     * @dev Creates loan contract with lender as the owner
     * @param orderBookId The order book Id from the off-chain DB
    */
    function createLoanContract(uint orderBookId) private {

            uint256 _principal = loans[orderBookId].principal;
            uint256 _interest = loans[orderBookId].interest;
            uint256 _duration = loans[orderBookId].duration;
            address _borrower = loans[orderBookId].borrower;
            address _lender = loans[orderBookId].lender;
            address out = new LoanContract(_principal, _duration, _interest,
                        loans[orderBookId].loanId, _lender, _borrower,
                        loans[orderBookId].tokenAddress, loans[orderBookId].tokenAmount);
            loanCounter++;
            loans[orderBookId].loanContractAddr = out;
            
        emit LoanContractCreated(this, orderBookId, _lender, out);
            transferFundsToBorrower(out, orderBookId);

    }


    /**
     * @dev Transfer funds to borrower after the loan contract creation
     * @param _loanContractAddress The deployed loan contract address
     * @param orderBookId The order book Id from the off-chain DB
    */
    function transferFundsToBorrower(address _loanContractAddress, uint orderBookId) private{

            LoanContract loanContract = LoanContract(_loanContractAddress);

            address borrower = loanContract.getBorrowerAddress();
            uint256 amount = loanContract.getPrincipal();
            borrower.transfer(amount);
            loans[orderBookId].fundAmount = 0;          // use safe math here to subtract loan amount from fund

            loanContract.setLoanActive();

        emit FundsTransferedToBorrower(_loanContractAddress, borrower);
            transferCollateralToLoan(_loanContractAddress, orderBookId);


    }


    /**
     * @dev Transfer Collateral to loan contract
     * @param _loanContractAddress The deployed loan contract address
     * @param orderBookId The order book Id from the off-chain DB
    */
    function transferCollateralToLoan(address _loanContractAddress, uint256 orderBookId) private {

            address tokenAddress = loans[orderBookId].tokenAddress;
            uint256 tokenAmount = loans[orderBookId].tokenAmount;
            ERC20 token = ERC20(tokenAddress);
            token.transfer(_loanContractAddress, tokenAmount);

        emit CollateralTransferedToLoan( this, _loanContractAddress, orderBookId);
    }


    /**
     * @dev Update the loan creator contract after a loan request is created
     *  and collateral is successfully transferred to escrow (Loan Creator Contract)
     * @param _borrower The borrower ethereum address
     * @param _principal The principal amount
     * @param _duration The duration of the Loan
     * @param _interest The interest for the Loan
     * @param _tokenAddress The ERC20 token contract address
     * @param _tokenAmount The token amount transferred
     * @param orderBookId The order book Id from the off-chain DB
    */
    function updateCollateralArrival(address _borrower, uint256 _principal, uint256 _duration,
        uint256 _interest, address _tokenAddress,
        uint256 _tokenAmount, uint orderBookId) onlyOwner external{
            require(loans[orderBookId].borrower == 0);
           loans[orderBookId] = Loan(_borrower,_principal,_duration,_interest,_tokenAddress, _tokenAmount, 0,0,0,0);
        emit CollateralDetailsUpdated(_borrower, orderBookId);
    }


    /**
     * @dev Transfer funds to escrow after loan request approval by lender
     * @param _loanId The loan Id from the off-chain DB
     * @param orderBookId The order book Id from the off-chain DB
    */
    function transferFunds(uint _loanId, uint orderBookId) public payable {

            /**
            * Add function to get the actual fund amount when msg.valeue will contain the
            * fee also which could be 0.1% of the loan amount
            */
            require(loans[orderBookId].principal == msg.value);
            require(loans[orderBookId].loanContractAddr == 0x0);

            loans[orderBookId].lender = msg.sender;
            loans[orderBookId].loanId = _loanId;
            loans[orderBookId].fundAmount = msg.value;

        emit FundsArrived(msg.sender, this, _loanId, msg.value);
            createLoanContract(orderBookId);
    }


    /**
        @dev Throws if called by any account.
    */
    function() payable public{
        // revert();
    }

    /**
     *  @notice Function to kill the loan contract
     */
    function killLoanContract(address loanContractAddress) onlyOwner public {
        LoanContract loanContract = LoanContract(loanContractAddress);
        loanContract.kill(_owner);
    }

    /**
     *  @notice this is test function to test the amount of ether stored in the contract
     *  Will be removed in PROD
     */
    function getMainBalance() public view returns(uint) {
        return address(this).balance;
    }

    /**
     * function to get the loan getLoanDetails
    */
    function getLoanDetails(uint orderBookId) view public returns(address, uint256, address, address){
        address loanAddr = loans[orderBookId].loanContractAddr;
        uint256 funds = loans[orderBookId].fundAmount;
        address lender = loans[orderBookId].lender;
        address borrower = loans[orderBookId].borrower;
        return (loanAddr, funds, lender, borrower);
    }

    /**
     * @notice these functions will be removed in prod. Only for testing and dev purposes
    */
    function transferFundsBack() onlyOwner public {
        _owner.transfer(address(this).balance);
    }


    /**
     *  @notice function to kill the order book contract
     */
    function kill() onlyOwner public {
        selfdestruct(_owner);
    }


}
