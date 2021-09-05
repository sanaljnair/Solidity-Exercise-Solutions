pragma solidity ^0.5.0;

contract C {
	function summation(uint n) public pure returns(uint) {
   	uint sum = 0;
   	
   	//write your code here
   	for (uint i = 1; i<= n; i++) {
   	    sum = sum + i;
   	}
  	return sum;
	}
	modifier bigSums(uint n){
    	//define the modifier here
    	require(n > 10);
    	_;
	}
}
