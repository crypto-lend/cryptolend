pragma solidity ^0.4.11;


/**
    @title Ownable
    @dev The Ownable contract has an owner address, and provides basic authorization control 
        functions, this simplifies the implementation of "user permissions". The owner can also
        kill the contract to prevent further use of it.
 */
contract Ownable {
    address public owner;

    /**
        @dev Throws if called by any account other than the owner. 
    */
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    /** 
        @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
    */
    function Ownable() {
        owner = msg.sender;
    }

    /**
        @dev Allows the current owner to transfer control of the contract to a newOwner.
        @param newOwner The address to transfer ownership to. 
    */
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    /**
        @dev Allows the current owner to kill the contract and redeem its funds
    */
    function kill() onlyOwner { 
        selfdestruct(owner); 
    }

}
