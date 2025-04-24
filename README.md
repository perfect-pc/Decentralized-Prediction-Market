# Decentralized Prediction Markets with Bitcoin Settlement

## Overview

The **Decentralized Prediction Markets with Bitcoin Settlement** project is a decentralized platform where users can create and participate in prediction markets, betting on the outcomes of verifiable future events. The platform uses **Bitcoin** as the settlement currency, ensuring global accessibility and leveraging the power of the **Stacks blockchain** for market creation, resolution, and decentralized governance.

---

## Key Features

- **Market Creation**: Anyone can create a new prediction market for any verifiable future event.
- **Betting on Outcomes**: Users can place bets on possible outcomes of prediction markets.
- **Market Resolution**: Once the event concludes, the market can be resolved, and winnings are distributed.
- **Bitcoin Settlement**: Users are settled in Bitcoin, ensuring global liquidity.
- **Public Data Access**: Transparent market data for all users, allowing for easy access to market outcomes and user bets.

---

## Contract Structure

The contract is built using **Clarity**, a smart contract language for the **Stacks blockchain**. Below is an overview of the key components:

### Data Structures

- **`user-bets`**: Stores the amount a user has bet on a specific outcome in a market.
- **`user-total-stakes`**: Tracks the total stake of a user across all outcomes for a specific market.
- **`market-outcome-stakes`**: Stores the total stake for each outcome in a market.
- **`market-totals`**: Holds the total amount staked in a market.
- **`markets`**: Stores market details, such as creator, end block, and possible outcomes.

### Functions

1. **Market Creation**
   - **`create-market`**: Creates a new prediction market, specifying an end block and number of possible outcomes.
   
2. **Bet Placement**
   - **`place-bet`**: Allows users to place a bet on a specific outcome in a market.
   
3. **Market Resolution**
   - **`resolve-market`**: Resolves the market by selecting the winning outcome and distributing winnings accordingly.
   
4. **Read-Only Functions**
   - **`get-market`**: Retrieves market details by market ID.
   - **`get-user-bet`**: Retrieves the user's bet details for a specific market and outcome.
   - **`get-user-total-stake`**: Retrieves the total stake a user has placed in a market.
   - **`get-market-outcome-stake`**: Retrieves the total stake for a specific outcome in a market.
   - **`get-market-total`**: Retrieves the total amount staked in a market.

---

## Setup and Installation

To interact with this contract, you'll need the **Stacks CLI** tools for deploying and interacting with Clarity contracts.

### Prerequisites

- **Stacks Wallet**: To interact with the contract and settle transactions in Bitcoin.
- **Clarity Development Tools**: Install the Stacks CLI tools to deploy and test the contract.
  - [Stacks CLI Installation](https://www.blockstack.org/)

### Deployment

1. **Deploy the Contract**: Deploy the contract to the Stacks blockchain using the Stacks CLI or your preferred deployment method.
2. **Interact with the Contract**: After deployment, users can interact with the contract through the Stacks Wallet or via any interface supporting Clarity smart contracts.

---

## Contract Functions

### 1. `create-market`

- **Parameters**:
  - `end-block`: The block height at which the market will close.
  - `outcomes`: The number of possible outcomes for the market.
- **Returns**: The market ID of the newly created market.

### 2. `place-bet`

- **Parameters**:
  - `market-id`: The ID of the market being bet on.
  - `outcome`: The outcome being bet on.
  - `amount`: The amount of Bitcoin being bet.
- **Returns**: A confirmation that the bet has been placed successfully.

### 3. `resolve-market`

- **Parameters**:
  - `market-id`: The ID of the market to resolve.
  - `winning-outcome`: The outcome that wins the market.
- **Returns**: A confirmation of market resolution and payout logic (to be implemented).

### 4. Read-Only Functions

- **`get-market`**: Retrieves the details of a market (e.g., creator, end block, outcomes).
- **`get-user-bet`**: Retrieves the amount a user has bet on a specific outcome in a market.
- **`get-user-total-stake`**: Retrieves the total stake of a user in a market.
- **`get-market-outcome-stake`**: Retrieves the total stake for a specific outcome in a market.
- **`get-market-total`**: Retrieves the total amount staked in a market.

---

## Security Considerations

- **Market Integrity**: The contract ensures that markets are only resolvable after their end block is reached, preventing premature payouts.
- **Bet Validation**: Bets are validated against the outcome choices to ensure only valid bets are placed.
- **Settlement in Bitcoin**: Bitcoin is used for settlements, providing a trusted, secure, and globally recognized settlement currency.

---

## Conclusion

The **Decentralized Prediction Markets with Bitcoin Settlement** platform provides a decentralized, transparent, and accessible way for users to engage in prediction markets. With Bitcoin as the settlement currency and Stacks handling market creation and resolution, this platform offers a secure and scalable solution for decentralized betting on future events.

For contributions or issues, feel free to open a pull request or raise an issue in the repository.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
