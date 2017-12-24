pragma solidity ^0.4.4;

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
    
    event MakeOrder(bytes32 indexed _orderuuid, address _seller, address[] _sellerTokens, uint256[] _sellerTOkenQty, uint256 _bidPrice);
    
    event GeneralErrorEvent(uint256 _statusCode, string _statusText);
    
    event tokenTransfer(address indexed _seller, address indexed _tokenAddress, uint256 _tokenQty);
    
    event EtherTransfer(address _buyer, address _seller, uint256 _etherQty);
    
    address owner;
    address previousContractAddr;
    
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
    
    function makeOrder(bytes32 _orderuuid, address[] _sellerTokens, uint256[] _sellerTokenQty, uint256 _bidPrice) public returns (bytes32) {
        
        var createOrderBasket = orderBaskets[_orderuuid];
        
        if(createOrderBasket.orderInitialized == true){
            GeneralErrorEvent(1, "order with same id already exist, reverting!");
            revert();
        }
        
        createOrderBasket.orderuuid = _orderuuid;
        createOrderBasket.seller = msg.sender;
        createOrderBasket.sellerTokens = _sellerTokens;
        createOrderBasket.sellerTokenQty = _sellerTokenQty;
        createOrderBasket.bidPrice = _bidPrice;
        createOrderBasket.orderInitialized = true;
        
        orderBasketsAccts.push(_orderuuid) -1;
        
        MakeOrder(_orderuuid, msg.sender, _sellerTokens, _sellerTokenQty, _bidPrice);
        
        return _orderuuid;
    }
    
    function allowAndPull(bytes32 _orderuuid) public returns (bool) {
        
        var oAllowTransfer = orderBaskets[_orderuuid];
        
        //function only to be executed by orderCreator
        if(oAllowTransfer.seller != msg.sender){
            GeneralErrorEvent(2, "order id does not match with order creator address, reverting!");
            revert();
        }
        
        if(oAllowTransfer.orderCompleted == true){
            GeneralErrorEvent(3, "order is already completed, reverting!");
            revert();
        }
        
        uint transferCounter = 0;
        
        while(transferCounter < oAllowTransfer.sellerTokens.length){
            if(Token(oAllowTransfer.sellerTokens[transferCounter]).allowance(oAllowTransfer.seller, address(this)) >= oAllowTransfer.sellerTokenQty[transferCounter]){
                transferCounter += 1;
            }
            else{
                //condition is not fulfilled
                GeneralErrorEvent(4, "allowance on token not set, create order again, reverting!");
                revert();
                //reverseOrder(_orderuuid, transferCounter);
                break;
            }
        }
        
        if(oAllowTransfer.sellerTokens.length == transferCounter){
            while(transferCounter < oAllowTransfer.sellerTokens.length){
                if(transferSellerToken(oAllowTransfer.sellerTokens[transferCounter], oAllowTransfer.seller, address(this), oAllowTransfer.sellerTokenQty[transferCounter])){
                    //add token transfer event here
                    tokenTransfer(msg.sender, oAllowTransfer.sellerTokens[transferCounter], oAllowTransfer.sellerTokenQty[transferCounter]);
                }else{
                    //add error while transfering token, maybe enough gas not set
                    revert();
                    GeneralErrorEvent(5, "error while transfering token");
                }
            }
        }
    }
    
    //rename this function
    function transferSellerToken(address token, address from, address to, uint value) private returns (bool) {
        assert(Token(token).transferFrom(from, to, value));
        return true;
    }
    
    //to be run only by admin and remove private type
    function reverseOrder(bytes32 _orderuuid, uint _reverseCount) private {
        
        var oReverseOrder = orderBaskets[_orderuuid];
        
        uint reverseOrderCounter = 0;
        
        while(reverseOrderCounter < _reverseCount){
            Token(oReverseOrder.sellerTokens[reverseOrderCounter]).transfer(oReverseOrder.seller, oReverseOrder.sellerTokenQty[reverseOrderCounter]);
            reverseOrderCounter += 1;
        }
        
        oReverseOrder.orderCompleted = false;

    }
    
    function transferTokenBuyer(bytes32 _orderuuid) public payable {
        
        var oTransferBuyer = orderBaskets[_orderuuid];
        
        if(oTransferBuyer.orderInitialized == false){
            GeneralErrorEvent(6, "order does not exist, reverting!");
            revert();
        }
        
        if(oTransferBuyer.orderClose == true){
            GeneralErrorEvent(7, "trade already done, reverting!");
            revert();
        }
        
        if(oTransferBuyer.bidPrice > msg.value){
            GeneralErrorEvent(8, "selling price greater then ether sent, reverting!");
            revert();
        }
        
        if(oTransferBuyer.bidPrice <= msg.value){
            //transfer all tokens to buyer
            uint buyerTransferCounter = 0;
            while(buyerTransferCounter < oTransferBuyer.sellerTokens.length){
                Token(oTransferBuyer.sellerTokens[buyerTransferCounter]).transfer(msg.sender,oTransferBuyer.sellerTokenQty[buyerTransferCounter]);
                tokenTransfer(msg.sender, oTransferBuyer.sellerTokens[buyerTransferCounter], oTransferBuyer.sellerTokenQty[buyerTransferCounter]);
                buyerTransferCounter += 1;
            }
            
            oTransferBuyer.seller.transfer(msg.value);
            oTransferBuyer.orderClose = true;
            
            EtherTransfer(msg.sender, oTransferBuyer.seller, msg.value);
            
        }
    }
    
    function showAllOrderuuids() public constant returns (bytes32[]) {
        return orderBasketsAccts;
    }
    
    //function to transfer all open orders in case new contract gets deployed
    function transferOpenOrders(address newContractAddr) public returns (bool) {
        uint orderTransferCounter=0;
        while(orderTransferCounter < orderBasketsAccts.length){
            var orderForTransfer = orderBaskets[orderBasketsAccts[orderTransferCounter]];
            if(orderForTransfer.orderClose == false){
                if(TokenTraderBasket(newContractAddr).getOpenOrders(orderForTransfer.orderuuid, orderForTransfer.seller, orderForTransfer.sellerTokens, orderForTransfer.sellerTokenQty, orderForTransfer.bidPrice, orderForTransfer.orderCompleted)){
                    orderTransferCounter += 1;
                }
            }
        }
    }
    
    //function to receive all open orders
    function getOpenOrders(bytes32 _orderuuid, address _seller, address[] _sellerTokens, uint256[] _sellerTokenQty, uint256 _bidPrice, bool _orderCompleted) public returns (bool) {
        
        if(previousContractAddr != msg.sender){
            revert();
        }
        
        var storeOpenOrder = orderBaskets[_orderuuid];
        
        storeOpenOrder.orderuuid = _orderuuid;
        storeOpenOrder.seller = _seller;
        storeOpenOrder.sellerTokens = _sellerTokens;
        storeOpenOrder.sellerTokenQty = _sellerTokenQty;
        storeOpenOrder.bidPrice = _bidPrice;
        storeOpenOrder.orderInitialized = true;
        storeOpenOrder.orderCompleted = _orderCompleted;
        
        orderBasketsAccts.push(_orderuuid) -1;
        
        return true;

    }
    
    //function to store previous contract address
    function previousContractAddrAdd(address _contractAddr) public returns (bool) {
        if(owner != msg.sender){
            GeneralErrorEvent(9, "you are not owner, reverting!");
            revert();
        }
        previousContractAddr = _contractAddr;
        return true;
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