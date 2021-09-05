pragma solidity ^0.5.0;

contract Bank {
	address public owner;
	uint balance;


	// Make the Constructor "payable"
             //write your code here
    
    constructor() public payable {
        // require(msg.value == 1 wei);
        owner = msg.sender;
        // balance = 0;
    }
    
    function deposit() public payable returns(uint) {
        balance += msg.value;
        return balance;
    }
    
    
    function withdraw(uint _withdraw) public canWithdraw(_withdraw) payable returns(uint) {
        balance -= _withdraw;
        msg.sender.transfer(_withdraw);
        return balance;
    }
    
    modifier canWithdraw(uint _withdraw) {
        require(_withdraw <= balance, "canot withdraw more than account balance" );
        _;
    }
    
    function getBalance() public view returns(uint){
        return balance;
    } 
             
    
	}
