pragma solidity ^0.5.9;

/** 
 * @title kyc phase 2
 * @dev Implements kyc contract
 */
contract KYC{

    // define addmin user
    address admin;
    
    //define customer
    struct Customer {
        string userName;                //Username of the customer (primary identifier)
        string data;                    //Customer Data or identity documents provided by the customer.
        bool kycStatus;                 // kycStatus
        uint upVotes;                   // number of downvotes received from other banks over the customer data 
        uint downVotes;                 // number of upvotes received from other banks over the customer dat
        address bank;                   //unique address of the bank that validated the customer account
    }
    
    //define Bank
    struct Bank{
        string bankName;                //name of the bank/organisation.
        address ethAddress;             //unique Ethereum address of the bank/organisation
        uint complaints;
        uint kycCount;
        bool isAllowedToVote;
        string regNumber;               //registration number for the bank.
    }
    
    //define kyc Request 
    struct Request{
        string userName;
        address bank;
        string data;
    }
    
    // mapping (list) of customers
    mapping(string => Customer) customers;

    //mapping (list) of banks
    mapping(address => Bank) banks;
    
    //mapping of KYC requests 
    mapping(string => Request) requests;

    /** 
     * constructor function
     *      - Define Admin user 
     */
     
     constructor() public {
         
         //when the contract is deployed, set the account address as the admin user;
         admin = msg.sender;    
     }

    /** 
     * Create add a customer to the customer list.
     */
     
    function addCustomer(string memory _userName, string memory _customerData) public {

        //validate if customer is present in the database
        require(customers[_userName].bank == address(0), "Customer is already present, please call modifyCustomer to edit the customer data");
        
        customers[_userName].userName = _userName;
        customers[_userName].data = _customerData;
        customers[_userName].bank = msg.sender;
        
        //set KYC status = false for new customer & reset upvotes and downvotes
        customers[_userName].kycStatus = false;         
        customers[_userName].upVotes = 0;                
        customers[_userName].downVotes = 0;              
        
    }

    /** 
     * This function allows a bank to modify a customer's data.
     */
        
    function modifyCustomer(string memory _userName, string memory _newcustomerData) 
             public 
             customerExists(_userName) {
        
        customers[_userName].data = _newcustomerData;
        
        //set KYC status = false when customer data is updated and reset upvotes and downVotes
        customers[_userName].kycStatus = false;         
        customers[_userName].upVotes = 0;                
        customers[_userName].downVotes = 0;     
    }    
    
    modifier customerExists(string memory _userName) {
        //validate if customer is present in the database
        require(customers[_userName].bank != address(0), "could not find the customer in the database");
        _;
        
    }
    
    /** 
     * View Customer - This function allows a bank to view the details of a customer.
     */

    function viewCustomer(string memory _userName) 
             public 
             view 
             customerExists(_userName) 
             returns (string memory, string memory, bool, uint, uint, address) {
        
        //return all parms for the customer
        return (customers[_userName].userName, 
                customers[_userName].data, 
                customers[_userName].kycStatus, 
                customers[_userName].upVotes, 
                customers[_userName].downVotes, 
                customers[_userName].bank);
    }
    
    /** 
     * Add Request - This function allows a bank to raise KYC request for a customer given that the customer has provided additional information for the same to the bank
     * 
     */
    
    modifier bankExists(address _bank) {
        // Validate if bank is a valid bank
        require(banks[_bank].ethAddress != address(0),"Address is not a valid bank ");
        _;
    }
    
    
    function raiseKYC(string memory _userName, string memory _customerDataHash) 
             public
             bankExists(msg.sender)
             customerExists(_userName) {
        

        //update if KYC aleady exists (update data for same customer and bank )
        if (requests[_userName].bank == msg.sender) {
            
            //validate if customer data has changed
            require(keccak256(abi.encodePacked(requests[_userName].data)) != keccak256(abi.encodePacked(_customerDataHash)),"Request already exists");
            
            //if there is a change in data hash, update KYC request
            requests[_userName].data = _customerDataHash;
            
        } else {
            //create new KYC request for the customer
            requests[_userName].userName = _userName;
            requests[_userName].bank = msg.sender;
            requests[_userName].data = _customerDataHash;
        }
    }
    
    /** 
     * Remove Request - This function allows a bank to remove KYC request of a customer. 
     */
    
    function removeKYC(string memory _userName) 
             public
             bankExists(msg.sender)
             customerExists(_userName) {
        
        //validate if bank is requesting for KYC created by self
        require(requests[_userName].bank == msg.sender,"request is not created by the bank");
        
        //remove KYC request
        delete requests[_userName];
    }
    
    /** 
     * Upvote Customers - This function allows a bank to cast an upvote for a customer.
     */

    function upVoteCustomer(string memory _username) public {
        
    }
     
    /** 
     * Downvote Customers - This function allows a bank to cast a downvote for a customer. 
     */
    
    function downVoteCustomer(string memory _username) public {
        
        //if one-third of the total number of banks downvote the customer, then the KYC status is set to false


        //For the KYC status to be true for any customer, the number of upvotes should be greater than the number of downvotes        
        
        
    }
    
    /** 
     * Get Bank Complaints - This function is used to fetch bank complaints from the smart contract. 
     * 
     */


    /** 
     * View Bank Details - This function is used to fetch the bank details.
     * 
     */

    /** 
     * Report Bank - This function is used to report a complaint against any bank in the network.
     * 
     */
     
     function reportBank(address _bank, string memory _bankName) public {

        //modify the isAllowedToVote status of the bank -
        //  - if any bank gets reported more than one-third of the banks present in the network, it will not be allowed to do KYC anymore.
        //  - admin can update the isAllowedToVote status any time to false
        
     }

    /**
     * Addmin Interface  
     */
     
     
     
    /** 
     * Report Bank - This function is used to report a complaint against any bank in the network.
     * 
     */
     
     

     
    /** 
     * Report Bank - This function is used to report a complaint against any bank in the network.
     * 
     */
}