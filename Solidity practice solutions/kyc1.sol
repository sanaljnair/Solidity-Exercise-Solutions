pragma solidity ^0.5.9;

/** 
 * @title kyc phase 2
 * @dev Implements kyc contract
 */
contract KYC{

    // define addmin user
    address admin;
    uint public noOfBanks;
    
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
         noOfBanks = 0;
     }

    /****************************************************************************************
     * Addmin functions  ********************************************************************
     */
     
    /** 
     * Add Bank - This function is used by the admin to add a bank to the KYC Contract. 
     * 
     */
    modifier isAdmin(address _sender) {
        require(_sender == admin,"Not authorised for admin transactions");
        _;
    }
    
    function addBank(string memory _bankName,address _ethAddress,string memory _regNumber)
             public 
             isAdmin(msg.sender){
                 
        //validate bank does not exists for same address
        require(banks[_ethAddress].ethAddress == address(0),"Another bank exists with same address");
        
        banks[_ethAddress].bankName = _bankName;
        banks[_ethAddress].ethAddress = _ethAddress;
        banks[_ethAddress].complaints = 0;
        banks[_ethAddress].kycCount = 0;
        banks[_ethAddress].isAllowedToVote = true;
        banks[_ethAddress].regNumber = _regNumber;
        
        noOfBanks += 1;
    }
     
     
    /** 
     * Modify Bank isAllowedToVote - This function can only be used by the admin to change the status of isAllowedToVote of any of the banks at any point in time.
     * 
     */
    
    function modifyisAllowedToVote(address _ethAddress,bool _isAllowedToVote)
             public 
             isAdmin(msg.sender) 
             bankExists(_ethAddress) {
        
        banks[_ethAddress].isAllowedToVote = _isAllowedToVote;             //check 
        
        if (banks[_ethAddress].isAllowedToVote = false) {
            noOfBanks -= 1;
        }
    }
    
    /** 
     * Remove Bank - This function is used by the admin to remove a bank from the KYC Contract. You need to verify whether the user trying to call this function is the admin or not.
     * 
     */
    function removeBank(address _ethAddress) 
             public 
             isAdmin(msg.sender) 
             bankExists(_ethAddress) {
        
        //remove bank from the mapping
        delete banks[_ethAddress];
        
        noOfBanks -= 1;
    }

    /****************************************************************************************
     * bank functions  **********************************************************************
     */


    /** 
     * Create add a customer to the customer list.
     *      - Validate Bank Exists
     */
     
    function addCustomer(string memory _userName, string memory _customerData) 
             public
             bankExists(msg.sender) {

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
     *      - validate bank Exists
     *      - validate customer Exists
     */
        
    function modifyCustomer(string memory _userName, string memory _newcustomerData) 
             public
             bankExists(msg.sender)
             customerExists(_userName) {
        
        //vlidate if data has changed 
        require(keccak256(abi.encodePacked(customers[_userName].data)) != keccak256(abi.encodePacked(_newcustomerData)),"Customer Data has not changed");
        
        //Update Customer Data
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
     *      - validate customer exists
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
     *      - validate sender is a valid bank 
     *      - validate customer is a valid customer
     *      - if KYC exists then update else create new
     *      - validate if data is same as the data provided by customer the respective bank
     */
    
    modifier bankExists(address _bank) {
        // Validate if address is a valid bank
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
            
            //KYC data should be same as that provided to the bank
            require(keccak256(abi.encodePacked(_customerDataHash)) == keccak256(abi.encodePacked(customers[_userName].data)),"Data is not same as customer data");
            
            //create new KYC request for the customer
            requests[_userName].userName = _userName;
            requests[_userName].bank = msg.sender;
            requests[_userName].data = _customerDataHash;
        }
    }
    
    /** 
     * Remove Request - This function allows a bank to remove KYC request of a customer. 
     *      - validate sender is a valid bankExists (redundant: as it is checking if same bank has created the KYC)
     *      - validate sender is the same bank who created KYC request
     *      - validate if the customer is valid
     */
    
    function removeKYC(string memory _userName) 
             public
             //bankExists(msg.sender)
             customerExists(_userName) {
        
        //validate if bank is requesting for KYC created by self
        require(requests[_userName].bank == msg.sender,"request is not created by the bank");
        
        //remove KYC request
        delete requests[_userName];
    }
    
    /** 
     * Upvote Customers - This function allows a bank to cast an upvote for a customer.
     *          - validate customer is valid
     *          - validate bank is valid
     *          - todo - avoid duplicate downvote or upvote by a bank 
     */
    modifier bankIsAllowedToVote(address _bank){
        require(banks[_bank].isAllowedToVote = true,"Bank is not allowed to Vote");
        _;
    }
    
    function upVoteCustomer(string memory _userName) 
             public
             bankExists(msg.sender)
             bankIsAllowedToVote(msg.sender) {
        
        // check customer data hash against the data hash in the KYC request 
        require(keccak256(abi.encodePacked(customers[_userName].data)) == keccak256(abi.encodePacked(requests[_userName].data)),"Data is not same as KYC request");
        
        // upvote customer
        customers[_userName].upVotes += 1;
        
        //if one-third of the total number of banks downvote the customer, then the KYC status is set to false
                
        if((noOfBanks > 5) && (customers[_userName].downVotes >= (noOfBanks / 3))) {
            customers[_userName].kycStatus = false;
        } else {
        //For the KYC status to be true for any customer, the number of upvotes should be greater than the number of downvotes        
         
           if(customers[_userName].upVotes > customers[_userName].downVotes) {
               customers[_userName].kycStatus = true;
           }
        }        
        
    }
     
    /** 
     * Downvote Customers - This function allows a bank to cast a downvote for a customer. 
     *      - validate customer is valid
     *      - validate bank is valid
     *      - todo - avoid duplicate downvote or upvote by a bank 
     */
    
    function downVoteCustomer(string memory _userName) 
             public
             bankExists(msg.sender)
             bankIsAllowedToVote(msg.sender) {

        // check customer data hash against the data hash in the KYC request 
        require(keccak256(abi.encodePacked(customers[_userName].data)) == keccak256(abi.encodePacked(requests[_userName].data)),"Data is not same as KYC request");

        // downvote the customer        
        customers[_userName].downVotes += 1;
        
        //if one-third of the total number of banks downvote the customer, then the KYC status is set to false
                
       if((noOfBanks > 5) && (customers[_userName].downVotes >= (noOfBanks / 3))) {
            customers[_userName].kycStatus = false;
        } else {
        //For the KYC status to be true for any customer, the number of upvotes should be greater than the number of downvotes        
         
           if(customers[_userName].upVotes > customers[_userName].downVotes) {
               customers[_userName].kycStatus = true;
           }
        }
    }
    
    /** 
     * Get Bank Complaints - This function is used to fetch bank complaints from the smart contract. 
     *      - validate if bank address is valid
     */
     
    function getBankComplaints(address _ethAddress) 
             public view 
             bankExists(_ethAddress)
             returns (uint _complaints) {
        
        return(banks[_ethAddress].complaints);
    }


    /** 
     * View Bank Details - This function is used to fetch the bank details.
     *      - validate if bank exists
     */
    
    function viewBankDetails(address _ethAddress) 
             public view
             bankExists(_ethAddress) 
             returns(string memory _bankName,
                     address _ethAddress1,
                     uint _complaints,
                     uint _kycCount,
                     bool _isAllowedToVote,
                     string memory _regNumber){
        
        return(banks[_ethAddress].bankName,
               banks[_ethAddress].ethAddress,
               banks[_ethAddress].complaints,
               banks[_ethAddress].kycCount,
               banks[_ethAddress].isAllowedToVote,
               banks[_ethAddress].regNumber);
         
    }
    

    /** 
     * Report Bank - This function is used to report a complaint against any bank in the network.
     *      - validate if bank is validate
     *      - validate if the reporting bank is a valid bank
     *
     *todo: validate a bank is allowed to complaint only once. 
     */
     
     function reportBank(address _bank) 
              public 
              bankExists(_bank)
              bankExists(msg.sender) {
                  
        
        banks[_bank].complaints += 1;       // increment number of complaints by 1

        //modify the isAllowedToVote status of the bank -
        //  - if any bank gets reported more than one-third of the banks present in the network, it will not be allowed to do KYC anymore.
        
        if(( noOfBanks > 5) && (banks[_bank].complaints >= (noOfBanks / 3))) {
                banks[_bank].isAllowedToVote = false;
                noOfBanks -= 1;
        }
        
     }
    
     
}
