pragma solidity^0.4.11;

import './Utils/Ownable.sol';
import './Utils/strings.sol';
import './ENS/HashRegistrarSimplified.sol';

/**
    @title ENSCollateralManager
    @notice The ENSCollateralManager contract inherits the Ownable contract, and
        manages the ENS Domain transfer.
    @dev The contract has references to the following external contracts:
            Registrar Contract from ENS - To verify and transfer domain ownership
*/

contract ENSCollateralManager is Ownable {

    using strings for *;

    AbstractENS public ens;
    Registrar public registrar;
    address public OrderBook;


    modifier onlyOrderBook(){
        assert(msg.sender == OrderBook);
        _;
    }


    /**
     *  @dev ENSCollateralManager constructor sets the addresses for the ENS registrar and registry
     *      and gets the contracts instance at those addresses
     */
    function ENSCollateralManager() public {
        address _ensAddress = 0x112234455c3a32fd11230c42e7bccd4a84e02010;
        address _registrarAddress = 0xc19fd9004b5c9789391679de6d766b981db94610;
        ens = AbstractENS(_ensAddress);
        registrar = Registrar(_registrarAddress);
    }

    /**
     *  @dev Fetches the details of the Deed from the ENS Registrar for a ENS Domain
     *
     *  @param _ensDomainHash The hash of the ENS domain
     *  @return address The address of the _currentDeedOwner
     *  @return uint The value of ether stored in the deed
     */
    function getENSCollateralInfo(bytes32 _ensDomainHash) public view
        returns (address, uint) {
            var (_mode, _deedAddress, _timestamp, _value, _highestBid) = registrar.entries(_ensDomainHash);
            _mode;
            _highestBid;
            _timestamp;
            Deed _deedContract = Deed(_deedAddress);
            address _currentDeedOwner = _deedContract.owner();
            return  (_currentDeedOwner, _value);
    }

    /**
     *  @dev Transfer full ownership of the ENS domain to the new owner
     *
     *  @param _ensDomainHash The hash of the ENS domain to be transfered
     *  @param _newOwner The address of the new owner
     *  @return True if successfully transfered the ENS
     */
    function transferENSCollateral(bytes32 _ensDomainHash, address _newOwner) public payable returns(bool){
        var(_mode, _deedAddress, _timestamp, _value, _highestBid) = registrar.entries(_ensDomainHash);
        _mode;
        _highestBid;
        Deed _deedContract = Deed(_deedAddress);
        require(_deedContract.owner() == msg.sender);
        registrar.transfer(_ensDomainHash, _newOwner);
        return true;
    }

    /**
     *  @dev gets the address of the ENS domain owner
     *
     *  @param _ensDomainHash The hash of the ENS domain
     *  @return address The address of the owner of ENS domain
     */
    function getOwnerAddress(bytes32 _ensDomainHash) public view returns(address){
        address ownerAddr = ens.owner(_ensDomainHash);
        return ownerAddr ;
    }

      /**
    * @dev Calculates labelHash of ENS name
    * @param name string Plaintext ENS name
    * @return bytes32 ENS labelHash, hashed label of the name
    */
    function getLabelHash(string name) public returns(bytes32) {
        return sha3(name.toSlice().split(".".toSlice()).toString());
    }
}
