pragma solidity ^0.5.9;

/** 
 * @title kyc phase 2
 * @dev Implements kyc contract
 */
contract KYCContract{
    
    using SafeMath for uint256;

    // define addmin user
    address admin;
    uint256 public noOfBanks;
    
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
    
    //define bankVotes
    struct BankVote{
        string  userName;
        address bank;
        bool    vote;                   // true = upvote and false = downvote  
    }
    
    // mapping (list) of customers
    mapping(string => Customer) customers;

    //mapping (list) of banks
    mapping(address => Bank) banks;
    
    //mapping of KYC requests 
    mapping(string => Request) requests;
    
    
    //record if the bank has upvoted ot downvoted a customer already
    mapping(string => mapping (address => BankVote))  bankVotes;

    /** 
     * constructor function
     *      - Define Admin user 
     *      - reset number of banks
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
        
        noOfBanks = noOfBanks.add(1);
    }
     
     
    /** 
     * Modify Bank isAllowedToVote - This function can only be used by the admin to change the status of isAllowedToVote of any of the banks at any point in time.
     * 
     */
    modifier isAllowedToVoteHasChaged (address _ethAddress,bool _isAllowedToVote) {
        require(banks[_ethAddress].isAllowedToVote != _isAllowedToVote,"isAllowedToVote value has not changed");
        _;    
    }
    
    function modifyisAllowedToVote(address _ethAddress,bool _isAllowedToVote)
             public 
             isAdmin(msg.sender) 
             bankExists(_ethAddress) 
             isAllowedToVoteHasChaged(_ethAddress,_isAllowedToVote){       
        
       
        banks[_ethAddress].isAllowedToVote = _isAllowedToVote;             //check     
        
        
        if (banks[_ethAddress].isAllowedToVote == false ) {
            if (noOfBanks > 0) {
                noOfBanks = noOfBanks.sub(1);
            }
        } else {
            noOfBanks = noOfBanks.add(1);
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
        
        if (noOfBanks > 0) {
            noOfBanks = noOfBanks.sub(1);    
        }
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
             bankExists(msg.sender) 
             bankIsAllowedToVote(msg.sender) {                              // based on clarification on the discussion forum 

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
             bankIsAllowedToVote(msg.sender)                                 // based on clarification on the discussion forum 
             customerExists(_userName) {
        
        //vlidate if data has changed 
        require(keccak256(abi.encodePacked(customers[_userName].data)) != keccak256(abi.encodePacked(_newcustomerData)),"Customer Data has not changed");
        
        //Update Customer Data
        customers[_userName].data = _newcustomerData;
        
        //set KYC status = false when customer data is updated and reset upvotes and downVotes
        customers[_userName].kycStatus = false;         
        customers[_userName].upVotes = 0;                
        customers[_userName].downVotes = 0;     
        
        // delete exiting votes
        // delete bankVotes[_userName].;
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
             bankIsAllowedToVote(msg.sender)
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
        require(banks[_bank].isAllowedToVote == true,"Bank is not allowed to add or modify customers or Vote ");
        _;
    }

    
    modifier hasBankupVoted(string memory _userName, address _bank) {
        require((bankVotes[_userName][_bank].vote=false || 
                 bankVotes[_userName][_bank].bank == address(0)),"Bank Has alread upvoted");
        _;
    }
    
    modifier hasBankdownVoted(string memory _userName, address _bank) {
        require((bankVotes[_userName][_bank].vote=true || 
                 bankVotes[_userName][_bank].bank == address(0)),"Bank Has alread upvoted");
        _;
    }
    
    function upVoteCustomer(string memory _userName) 
             public
             bankExists(msg.sender)
             bankIsAllowedToVote(msg.sender) 
             hasBankupVoted(_userName, msg.sender) {
        
        // check customer data hash against the data hash in the KYC request 
        require(keccak256(abi.encodePacked(customers[_userName].data)) == keccak256(abi.encodePacked(requests[_userName].data)),"Data is not same as KYC request");
        
        // upvote customer
        bankVotes[_userName][msg.sender].userName = _userName;
        bankVotes[_userName][msg.sender].bank = msg.sender;
        bankVotes[_userName][msg.sender].vote = true;

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
             bankIsAllowedToVote(msg.sender) 
             hasBankdownVoted(_userName, msg.sender) {

        // check customer data hash against the data hash in the KYC request 
        require(keccak256(abi.encodePacked(customers[_userName].data)) == keccak256(abi.encodePacked(requests[_userName].data)),"Data is not same as KYC request");

        // downvote the customer     
        bankVotes[_userName][msg.sender].userName = _userName;
        bankVotes[_userName][msg.sender].bank = msg.sender;
        bankVotes[_userName][msg.sender].vote = false;
        
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
             
             if (noOfBanks > 0) {   
                noOfBanks = noOfBanks.sub(1);
             }
        }
        
     }
    
     
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
