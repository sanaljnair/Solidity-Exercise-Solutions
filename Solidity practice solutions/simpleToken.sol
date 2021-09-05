pragma 0.4.24;

contract SimpleToken{
    //declare the variables asked
    address tokenOwner;
    string tokenName;
    string tokenSymbol;
    uint256 totalNumberOfTokens;

    // create a mapping of the address to the balance
    mapping(address => uint256) public tokenBalance; 
    //constructor to initialise the token variables
    constructor(string memory _name, string memory _symbol, uint256 _balance) public{
        tokenOwner = msg.sender;
        tokenName = _name;
        tokenSymbol = _symbol;
        totalNumberOfTokens = _balance;

        //give the token owner the entire initial supply of tokens
        tokenBalance[tokenOwner] = totalNumberOfTokens; 
    }
    //returns the total supply of the token
    function totalSupply () public view returns(uint256){
        return totalNumberOfTokens; 
    }
    //returns the supply of a particular owner
    function balanceOf(address _owner) public view returns (uint256){
        return tokenBalance[_owner];
    }
    //transfer the tokens to the given address
    function transfer(address _to, uint256 _value) public returns(bool){
        //check if sender has enough balance
        require(tokenBalance[msg.sender] > _value);

        //update balances
        address _from = msg.sender;
        tokenOwner = _to;
        tokenBalance[_from] = tokenBalance[_from] - _value;
        tokenBalance[_to] = tokenBalance[_to] + _value; 
        return true; 
    }
}