pragma solidity ^0.4.12;

import "./Utils/SafeMath.sol";
import "./Utils/ERC20.sol";


/**
 *  @title LoanContract
 *  @notice The LoanContract keeps the record of a loan request or loan offer created.
 *  It manages the ENS collateral and fund transfer between Lender and borrower
 *          - ensDomainName: The name of the domain against which the loan is borrowed.
            - ensDomainHash: Sha of the domain name.
            - timestamp: Start date of the loan
            - borrower: Borrower who is the owner of the collateral.
            - lender: Lender who is funding the loan.
            - amount: The loan amount.
            - duration: The duration of the loan.
            - interestRate: The interest rate for the specific loan.
            - status: The status of the loan. Can be:
                - UNFUNDED: The loan not funded yet.
                - FUNDED: The loan is funded now.
                - CLOSED: The loan cycle is closed now.
                - DEFAULT: The loan period has expired, but the loan amount has not been paid.
            - ensStatus: The status of the ENS transfer. Can be:
                - TRANSFERED: The ENS transfered to loan contract as collateral.
                - NOTTRANSFERED: The ENS not transfered to loan contract as collateral.

 */

contract LoanContract {

    using SafeMath for uint256;

    address private borrower;
    address private lender;
    address private loanCreator;

    /* Will be removed in prod. Required for testing purposes*/
    address private admin = 0x8fAF15DFB86aDFC862C5952B776de2dCe7A36c99;

    enum LoanStatus {
        OPEN,
        UNFUNDED,
        FUNDED,
        ACTIVE,
        REPAID,
        CLOSED,
        DEFAULTED
    }

    enum ENSStatus {
        TRANSFERED,
        NOTTRANSFERED
    }


    uint256 public amount;
    uint256 public duration;
    uint256 public interestRate;

    bytes32 public ensDomainHash;
    string public ensDomainName;

    uint256 public createdOn;
    uint256 public updatedOn;
    uint256 public expiresOn;

    uint256 public riskRating;
    uint256 public loanId;

    address public tokenAddress;
    uint256 public tokenAmount;

    LoanStatus public loanStatus;

    ENSStatus public ensStatus;


    modifier onlyLoanCreator {
        require(msg.sender == loanCreator);
        _;
    }

    modifier onlyBorrower {
        require(msg.sender == borrower);
        _;
    }

    modifier onlyLender {
        require(msg.sender == lender);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    event TransferedCollateralToBorrower(address indexed loanContract, address indexed borrower, uint256 indexed loanId);
    event LoanRepaid(address indexed loanContract, address indexed from, uint256 indexed loanId);
    event LoanDefaulted(address indexed loanContract, address to, address indexed claimer, uint256 indexed loanId);
    /**
     * @notice The LoanContract constructor sets the following values
     *      - The owner of the contract
     *      - The amount of loan
     *      - The duration of the loan
     *      - Interest to be charged
     *      - Loan status to UNFUNDED
     *      - ENS status to NOTTRANSFERED
     *      - riskRating for the loan
     *      - ContractType either LENDER or BORROWER
     */

    constructor (uint256 _principal, uint256 _duration,
        uint256 _interest, uint _loanId, address _lender, address _borrower,
        address _tokenAddress, uint256 _tokenAmount)
        public {

            amount = _principal;
            duration = _duration; //In minutes
            interestRate = _interest;

            loanId = _loanId;
            loanStatus = LoanStatus.FUNDED;

            tokenAddress = _tokenAddress;
            tokenAmount = _tokenAmount;

            createdOn = now;
            updatedOn = now;

            borrower = _borrower;
            lender = _lender;

            loanCreator = msg.sender;  // Required for calling the function of this contract from Loan Creator Contract
    }

    /**
     * @notice This function returns loan details for the current loan contract
     *
     * @return _principal The amount of the loan
     * @return _duration The duration of the loan
     * @return _interest The interest for the loan
     * @return _ensDomainHash and _ensDomainName that is transfered as collateral
     * @return _riskRating riskRating for the loan
     * @return _status LoanStatus
     */
    function getLoanInfo()
        public view
        returns (address _loanAddress, uint256 _principal, uint256 _duration ,
                uint256 _interest, bytes32 _ensDomainHash, string _ensDomainName,
                uint256 _riskRating, LoanStatus _status){
        _principal = amount;
        _duration = duration;
        _interest = interestRate;
        _ensDomainHash = ensDomainHash;
        _ensDomainName = ensDomainName;
        _riskRating = riskRating;
        _status = loanStatus;
        return (this,_principal, _duration, _interest, _ensDomainHash, _ensDomainName, _riskRating, _status);
    }

    /**
     * @dev Function to required to transfer ether to a contract
     *
     */
    function() payable public{
    }

    function setLoanActive() external onlyLoanCreator {
        loanStatus = LoanStatus.ACTIVE;
        expiresOn = now + duration * 1 minutes;
        updatedOn = now;
    }

    function setAppliedForLoan() external {
        loanStatus = LoanStatus.UNFUNDED;
    }


    /**
     *  @notice Sets the ensStatus to TRANSFERED when a user transfers ens to this contract.
     *
     *  @param _ensDomainHash The hash of the ensDomain
     *  @param _ensDomainName The name of the ensDomain
     */
    function setENSArrived(bytes32 _ensDomainHash, string _ensDomainName) external {
        ensDomainHash = _ensDomainHash;
        ensDomainName = _ensDomainName;
        ensStatus = ENSStatus.TRANSFERED;
    }

    /**
     *  @notice Sets the loanStatus to FUNDED when a lender transfer loan amount to this contract
     */
    function setFundsArrived() external {
        loanStatus = LoanStatus.FUNDED;
    }

    /**
     *  @notice Sets the lender address when a user funds a loan
     *
     *  @param _lender The user funding the loan
     */
    function setLenderAddress(address _lender) external {
        lender = _lender;
    }

    /**
     *  @notice Sets the borrower address when a user applys for a loan
     *
     *  @param _borrower the user applying for loan
     */
    function setBorrowerAddress(address _borrower) external {
        borrower = _borrower;
    }


    /**
     * @dev The function for repaying the loan on and before the loan expires
     *  checks the loan status to be active
    */
    function repayLoan() public payable {

        require(uint(loanStatus) == 3 && now <= expiresOn);

        // Add actual amount to be repaid based on the duration and interest rate
        require(msg.value == amount);    //change it to check if msg.value >= actual amount to be repaid

        lender.transfer(msg.value);
        loanStatus = LoanStatus.REPAID;

    emit LoanRepaid(this, msg.sender, loanId);
        transferCollateralToBorrower();
    }


    /**
     * @dev function to transfer collateral to borrower after loan repayment
    */
    function transferCollateralToBorrower() private {

        require(uint(loanStatus) == 4);

        ERC20 token = ERC20(tokenAddress);
        token.transfer(borrower, tokenAmount);
        tokenAmount = 0;

        endLoan();
    emit TransferedCollateralToBorrower(this, borrower, loanId);
    }

    /**
     * @dev function for updating the loan status to close on loan repayment
    */
    function endLoan() private {
        require(tokenAmount == 0);
        loanStatus = LoanStatus.CLOSED;
    }

    /**
     * @dev function to claim collateral if the loan is not repaid with the loan period
     * @param to Address to which collateral has to be transferred. Only lender can call this function
    */
    function claimCollateral(address to) onlyLender public {
        require(uint(loanStatus) == 3 && now >= expiresOn);

        loanStatus = LoanStatus.DEFAULTED;

        ERC20 token = ERC20(tokenAddress);
        token.transfer(to, tokenAmount);
        tokenAmount = 0;
    emit LoanDefaulted(this, to, msg.sender, loanId);
    }

    function getBorrowerAddress() view public returns(address) {
        return borrower;
    }

    function getPrincipal() view public returns(uint256) {
        return amount;
    }

    function getLoanId() view public returns(uint256) {
        return loanId;
    }


    /**
     *  @notice this is test function to test the amount of ether stored in the contract
     *  Will be removed in PROD
     */
    function getMainBalance() public view returns(uint) {
        return this.balance;
    }

     /**
     * @dev to be called in case ETH get stuck in contract.
     * Will be removed in PROD. Only for dev
    */
    function transferFundsBack() onlyAdmin public {
        admin.transfer(this.balance);
    }

    /**
     * @dev to be called in case collateral get stuck in contract.
     * Will be removed in PROD. Only for dev
    */
    function transferCollateral() onlyAdmin public {
        ERC20 token = ERC20(tokenAddress);
        token.transfer(admin, tokenAmount);
    }

    /**
     *  @notice function for destroying a contract state.
     */
    function kill(address recipient) external {
        selfdestruct(recipient);
    }
    //TODO: function to transfer capability to manage the ENS name while the deed contract stays with this contract.

}
