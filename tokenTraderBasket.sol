pragma solidity ^0.4.11;

contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}


//name this contract whatever you'd like

contract TokenTraderBasket is Token {
    
    address owner;
    
    function TokenTraderBasket () {
        owner = msg.sender;
    } 
    
    struct orderBasket {
        bytes32 orderuuid;
        address buyer;
        address seller;
        address[] sellerTokens;
        uint256[] sellerTokenQty;
        uint256 bidPrice;
        bool orderInitialized;
        bool orderCompleted;
        bool orderClose;
    }
    
    mapping (bytes32 => orderBasket) orderBaskets;
    bytes32[] public orderBasketsAccts;
    
    function makeOrder(bytes32 _orderuuid, address[] _sellerTokens, uint256[] _sellerTokenQty, uint256 _bidPrice) public returns (bool) {
        
        var createOrderBasket = orderBaskets[_orderuuid];
        
        if(createOrderBasket.orderInitialized == true){
            revert();
        }
        
        if(createOrderBasket.orderCompleted == true){
            revert();
        }
        
        if(createOrderBasket.orderClose == true){
            revert();
        }
        
        createOrderBasket.orderuuid = _orderuuid;
        createOrderBasket.seller = msg.sender;
        createOrderBasket.sellerTokens = _sellerTokens;
        createOrderBasket.sellerTokenQty = _sellerTokenQty;
        createOrderBasket.bidPrice = _bidPrice;
        createOrderBasket.orderInitialized = true;
        
        orderBasketsAccts.push(_orderuuid) -1;
        
        return true;
    }
    
    function allowAndPull(bytes32 _orderuuid) public returns (bool) {
        
        var oAllowTransfer = orderBaskets[_orderuuid];
        
        if(oAllowTransfer.orderInitialized == false){
            revert();
        }
        
        //function only to be executed by orderCreator
        if(oAllowTransfer.seller != msg.sender){
            revert();
        }
        
        if(oAllowTransfer.orderCompleted == true){
            revert();
        }
        
        if(oAllowTransfer.orderClose == true){
            revert();
        }
        
        uint transferCounter = 0;
        
        while(transferCounter < oAllowTransfer.sellerTokens.length){
            if(Token(oAllowTransfer.sellerTokens[transferCounter]).allowance(oAllowTransfer.seller, address(this)) >= oAllowTransfer.sellerTokenQty[transferCounter]){
                transferCounter += 1;
            }
            else{
                //condition is not fulfilled
                revert();
            }
        }
        
        transferCounter = 0;
        
        if(oAllowTransfer.sellerTokens.length == transferCounter){
            while(transferCounter < oAllowTransfer.sellerTokens.length){
                if(transferSellerToken(oAllowTransfer.sellerTokens[transferCounter], oAllowTransfer.seller, address(this), oAllowTransfer.sellerTokenQty[transferCounter])){
                    //add token transfer event here
                    transferCounter += 1;
                }else{
                    //add error while transfering token, maybe enough gas not set
                    revert();
                }
            }
        }
    }
    
    //rename this function
    function transferSellerToken(address token, address from, address to, uint value) private returns (bool) {
        assert(Token(token).transferFrom(from, to, value));
        return true;
    }
    
    function transferTokenBuyer(bytes32 _orderuuid) public payable returns (bool) {
        
        var oTransferBuyer = orderBaskets[_orderuuid];
        
        if(oTransferBuyer.orderInitialized == false){
            revert();
        }
        
        if(oTransferBuyer.orderClose == true){
            revert();
        }
        
        if(oTransferBuyer.bidPrice > msg.value){
            revert();
        }
        
        if(oTransferBuyer.bidPrice <= msg.value){
            //transfer all tokens to buyer
            uint buyerTransferCounter = 0;
            while(buyerTransferCounter < oTransferBuyer.sellerTokens.length){
                Token(oTransferBuyer.sellerTokens[buyerTransferCounter]).transfer(msg.sender,oTransferBuyer.sellerTokenQty[buyerTransferCounter]);
                buyerTransferCounter += 1;
            }
            
            oTransferBuyer.seller.transfer(msg.value);
            oTransferBuyer.orderClose = true;
            
            return true;
            
        }
    }
    
    function swapTokensOwner(address[] tokenAddress, uint256[] value) public returns(uint256 number) {
        uint256 i = 0;
        while(i<tokenAddress.length){
            Token(tokenAddress[i]).transfer(msg.sender, value[i]);
            i += 1;
        }
        return i;
    }
}