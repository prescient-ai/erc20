pragma solidity ^0.4.20;

interface token 
{
    function transfer( address receiver, uint amount) external;
    function balanceOf(address OWNER) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract Crowdsale
{
    address public beneficiary;
    uint public minimumFundingGoal;
    uint public maximumFundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping( address => uint256) public balanceOf;
    uint public tokenLockdownEnd;
    uint public tokenLockdownAmount;
    bool unsoldTokensRetrieved = false;
    bool lockdownTokensRetrieved = false;
    mapping( address => uint256) public overPayRefundOf;

    event GoalReached( address recipient, uint totalAmountRaised);
    event FundTransfer( address backer, uint amount, bool isContribution);
    
    constructor
    (
        address ifSuccessfulSendTo,
        uint minimumFundingGoalInEthers,
        uint maximumFundingGoalInEthers,
        uint durationInMInutes,
        uint weiCostOfEachSmallestDivisibleToken,
        address addressOfTokenUsedAsReward,
        uint durationTokenLockdownInMinutes, 
        uint numberIntegerTokensToHold
    ) public
    {
        beneficiary = ifSuccessfulSendTo;
        minimumFundingGoal = minimumFundingGoalInEthers * 1 ether;
        maximumFundingGoal = maximumFundingGoalInEthers * 1 ether;
        deadline = now + durationInMInutes * 1 minutes;
        price = weiCostOfEachSmallestDivisibleToken;// * 1 ether;
        tokenReward = token( addressOfTokenUsedAsReward);
        tokenLockdownEnd = now + durationInMInutes * 1 minutes + durationTokenLockdownInMinutes * 1 minutes;
        tokenLockdownAmount = numberIntegerTokensToHold*10**uint256( tokenReward.decimals());
    }
    
    function () payable public
    {
        require( now < deadline);
        require( amountRaised < maximumFundingGoal);
        uint amount = msg.value; 
        require( balanceOf[ msg.sender] + amount >= balanceOf[ msg.sender]);
        if(  amount + amountRaised > maximumFundingGoal)
        {
            uint refund = amount + amountRaised - maximumFundingGoal;
            require( refund + maximumFundingGoal == amount + amountRaised);
            overPayRefundOf[ msg.sender] += refund;
            amount = maximumFundingGoal - amountRaised;
        }
        require( amount > 0);
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer( msg.sender, amount / price);
        emit FundTransfer( msg.sender, amount, true);
    }
    
    modifier afterDeadline() 
    {
        if( now >= deadline || amountRaised >= maximumFundingGoal) 
        {
            _;
        }
    }
    
    modifier afterLockdown()
    {
        if( now >= tokenLockdownEnd) 
        {
            _;
        }        
    }

    function checkGoalReached() public afterDeadline 
    {
        if( amountRaised >= minimumFundingGoal)
        {
            emit GoalReached( beneficiary, amountRaised);
        }
    }
    
    function withdrawOverPay() public
    {
            uint amount = overPayRefundOf[msg.sender];
            overPayRefundOf[msg.sender] = 0;
            if( amount > 0)
            {
                if( msg.sender.send( amount))
                {
                    emit FundTransfer( msg.sender, amount, false);
                }
                else
                {
                    overPayRefundOf[ msg.sender] = amount;
                }
            }     
    }
    
    function safeWithdrawal() public afterDeadline
    {
        if( amountRaised < minimumFundingGoal)
        {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if( amount > 0)
            {
                if( msg.sender.send( amount))
                {
                    emit FundTransfer( msg.sender, amount, false);
                }
                else
                {
                    balanceOf[ msg.sender] = amount;
                }
            }
        }
        else if( beneficiary == msg.sender)
        {
            if( beneficiary.send( amountRaised))
            {
                emit FundTransfer( beneficiary, amountRaised, false);
            }
        }
    }
    
    function retrieveLockdownTokens() public afterLockdown
    {
        if( beneficiary == msg.sender && lockdownTokensRetrieved == false)
        {
            uint256 available_tokens = tokenReward.balanceOf( address( this));
            require( available_tokens >= tokenLockdownAmount);
            if( available_tokens > tokenLockdownAmount)
            {
                available_tokens = tokenLockdownAmount;
            }
            tokenReward.transfer( beneficiary, available_tokens);
            lockdownTokensRetrieved = true;
        }
    }
    
    function retrieveUnsoldTokens() public afterDeadline
    {
        if( beneficiary == msg.sender && unsoldTokensRetrieved == false)
        {
            uint256 available_tokens = tokenReward.balanceOf( address( this));
            uint256 expected_available_tokens = maximumFundingGoal - amountRaised;
            require( available_tokens >= expected_available_tokens);
            if( available_tokens > expected_available_tokens)
            {
                available_tokens = expected_available_tokens;
            }
            tokenReward.transfer( beneficiary, available_tokens);
            unsoldTokensRetrieved = true;
        }
    }
}
