# TokenTraderBasket

## Overview
TokenTraderBasket is a Solidity-based smart contract that enables decentralized token trading by allowing users to create and execute bundled token trades. The contract facilitates the exchange of multiple tokens in a single transaction, ensuring a secure and transparent trading mechanism.

## Features
- **Order Basket System**: Allows sellers to bundle multiple tokens into a single tradeable order.
- **Automated Token Transfers**: Ensures that token transfers only occur after proper approvals.
- **ETH Payment Mechanism**: Allows buyers to purchase token baskets by sending ETH.
- **Secure Transaction Handling**: Orders are only executed if all conditions (approvals and payments) are met.

## Smart Contract Components

### **Struct Definition (`orderBasket`)**
- `orderuuid`: Unique identifier for an order.
- `buyer`: Address of the buyer.
- `seller`: Address of the seller.
- `sellerTokens`: Array of token contract addresses being offered.
- `sellerTokenQty`: Corresponding array of token amounts.
- `bidPrice`: Price in ETH that the seller is asking for the tokens.
- `orderInitialized`: Whether the order has been created.
- `orderCompleted`: Whether the order has been fulfilled.
- `orderClose`: Whether the order is closed.

### **Functions**
- `makeOrder(bytes32 _orderuuid, address[] _sellerTokens, uint256[] _sellerTokenQty, uint256 _bidPrice)`: Allows sellers to create an order.
- `allowAndPull(bytes32 _orderuuid)`: Verifies seller token approvals and transfers tokens to the contract.
- `transferSellerToken(address token, address from, address to, uint value)`: Transfers tokens from the seller to the contract.
- `transferTokenBuyer(bytes32 _orderuuid)`: Allows buyers to purchase the token basket by sending ETH, completing the transaction.
- `swapTokensOwner(address[] tokenAddress, uint256[] value)`: Enables the contract owner to swap multiple tokens.

## Usage

### 1. Deploy the Contract
Compile and deploy the `TokenTraderBasket` contract on an Ethereum-compatible network.

### 2. Create an Order
A seller can create an order by calling `makeOrder`, specifying the tokens, quantities, and asking price.

### 3. Approve Tokens
The seller must approve the contract to transfer their tokens on their behalf.

### 4. Execute Order
A buyer can complete the purchase by calling `transferTokenBuyer` and sending the required ETH.

## Requirements
- Solidity `0.4.11`
- Ethereum-compatible blockchain
- ERC-20 token contracts

## Security Considerations
- Ensure that the seller has approved the contract to transfer tokens before executing an order.
- Consider upgrading Solidity to a newer version for better security and efficiency.
- Implement proper error handling with `require()` instead of `revert()`.

## License
This project is licensed under the MIT License.

