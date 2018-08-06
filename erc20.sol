pragma solidity ^0.4.24;

contract ERC20
{
    address public m_Minter;
    string public name            ;
    string public symbol          ;
    uint8  public decimals    = 18;
    uint256 public totalSupply     ;
    mapping( address => uint256) public balanceOf;
    mapping( address => mapping ( address => uint256)) public allowance;
    
    event Transfer( address indexed FROM, address indexed TO, uint256 VALUE);

    event Approval(address indexed OWNER, address indexed SPENDER, uint256 VALUE);

    event Burn( address indexed FROM, uint256 VALUE);
    
    constructor
    (
        uint256 INITIAL_SUPPLY,
        string  NAME,
        string SYMBOL
    ) public
    {
        m_Minter = msg.sender;
        totalSupply = INITIAL_SUPPLY* 10**uint256( decimals);
        balanceOf[msg.sender] = totalSupply;
        name = NAME;
        symbol = SYMBOL;
    }
    
    function subtract( uint256 _a, uint256 _b) internal pure returns(uint256)
    {
        assert( _b <= _a);
        return _a - _b;
    }
    
    function add( uint256 _a, uint256 _b) internal pure returns(uint256 c)
    {
        c = _a + _b;
        assert( c >= _a);
        return c;
    }
    

    function balanceOf(address OWNER) public view returns (uint256 balance)
    {
        return balanceOf[ OWNER];
    }
    
    function _transfer( address FROM, address TO, uint256 VALUE) private
    {
        require( TO != 0x0);
        require( balanceOf[ FROM] >= VALUE);
        uint256 previous_balances = add( balanceOf[ FROM], balanceOf[ TO]);
        balanceOf[ FROM] = subtract( balanceOf[ FROM], VALUE);
        balanceOf[ TO] = add( balanceOf[ TO], VALUE);
        emit Transfer( FROM, TO, VALUE);
        assert( add( balanceOf[ FROM], balanceOf[ TO]) == previous_balances);
    }
    
    function transfer(address TO, uint256 VALUE) public returns (bool success)
    {
        _transfer( msg.sender, TO, VALUE);
        return true;
    }
    
    
    function transferIntegerAmount(address TO, uint256 VALUE) public returns (bool success)
    {
        _transfer( msg.sender, TO, VALUE*10**uint256( decimals));
        return true;
    }

    function transferFrom(address FROM, address TO, uint256 VALUE) public returns (bool success)
    {
        require( VALUE <= allowance[ FROM][ msg.sender]);
        _transfer( FROM, TO, VALUE);
        allowance[ FROM][ msg.sender] = subtract( allowance[ FROM][ msg.sender], VALUE);
        return true;
    }

    function approve(address SPENDER, uint256 VALUE) public returns (bool success)
    {
        allowance[ msg.sender][ SPENDER] = VALUE;
        return true;
    }

    function allowance(address OWNER, address SPENDER) public view returns (uint256 remaining)
    {
        return allowance[ OWNER][ SPENDER];
    }
    
    function burn( uint256 VALUE) public returns ( bool success)
    {
        require( balanceOf[ msg.sender] >= VALUE);
        balanceOf[ msg.sender] = subtract( balanceOf[ msg.sender], VALUE);
        totalSupply = subtract( totalSupply , VALUE);
        emit Burn( msg.sender, VALUE);
        return true;
    }
    
    function burnFrom( address FROM, uint256 VALUE) public returns ( bool success)
    {
        require( balanceOf[ FROM] >= VALUE);
        require( allowance[ FROM][ msg.sender] >= VALUE);
        balanceOf[ FROM] = subtract( balanceOf[ FROM], VALUE);
        totalSupply = subtract( totalSupply, VALUE);
        allowance[ FROM][ msg.sender] = subtract( allowance[ FROM][ msg.sender], VALUE);
        emit Burn( FROM, VALUE);
        return true;
    }
}
