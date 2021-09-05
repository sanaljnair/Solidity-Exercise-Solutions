pragma solidity ^0.5.9;

/** 
 * @title kyc phase 1
 * @dev Implements kyc contract
 */
contract kyc {
    
    //define customer
    struct customer {
        bytes32 username;                //Username of the customer (primary identifier)
        bytes32 customerData;            //Customer Data or identity documents provided by the customer.
        address bank;                   //unique address of the bank that validated the customer account
    }
    
    //define Bank
    struct bank{
        bytes32 bankName;                //name of the bank/organisation.
        address ethAddress;             //unique Ethereum address of the bank/organisation
        bytes32 regNumber;               //registration number for the bank.
    }
    
    //list of customers
    mapping(bytes32 => customer) public customers;
    
    
    mapping(address => bank) public banks;
    
    
    
    /** 
     * Create add a customer to the customer list.
     */
     
    function addCustomer(bytes32 _userName, bytes32 _customerData) public {
        
        //validate if customer is already present
        require(customers[_userName].bank == address(0),"customer exists");
        
        customers[_userName].username = _userName;
        customers[_userName].customerData = _customerData;
        customers[_userName].bank = msg.sender;
        
    } 
    
    /** 
     * This function allows a bank to modify a customer's data.
     */
     
    function modifyCustomer(bytes32 _username,bytes32 _customerData) public {
        //validate if customer is present in the database
        require(customers[_username].bank != address(0),"could not find the customer in the database");

        customers[_username].customerData = _customerData;
        
    }
    
    /** 
     * This function allows a bank to view the details of a customer.
     */
    function modifyCustomer(bytes32 _username) public view returns(bytes32, bytes32, address){
        
        //validate if customer is present in the database
        require(customers[_username].bank != address(0),"could not find the customer in the database");
        
        return(customers[_username].username, customers[_username].customerData, customers[_username].bank);
    }
    
    
}