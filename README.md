# Family Savings Smart Contract

## Table of Contents

- [Features](#features)
- [Example](#example)
- [Usage](#usage)

## Features

## Example

Let's say the following family members created this family savings contract: Bob (Father), Alice (Mother) and Joe (Son).

If the father wants to deposit 1000 and the mother 500 tokens, they can call ***deposit*** function.

They can either let that tokens just sit in a contract, or they can configure annual lending rate and collateral rates to make the token available for borrowing. Any other address (even the family members) will be able to borrow the mentioned token.

To set specific annual lending (***setAnnualLendingRate***) and collateral rates (***setCollateralRate***) for a token, members of the contract should go through a voting mechanism. In this example the family has 3 members so 2 "In Favor" votes will be needed for the proposal to pass and be executed.

If some John (outside of family) wants to borrow some asset by providing an underlying collateral asset, they can do so by calling ***borrow*** function. Minimum borrow perio should be 7 days and the collateral must be supported by the contract (collateral rate should be existent). Let's say the annual lending rate of the token is 10% and the collateral rate for some other token is 120%. This means that if John wants to borrow 100 tokens for a year (365), John will have to return 100 + (100 * 10%) = 110 tokens by the end of the year and the collateral token provided should be 110 * 120% = 132.

John is able to repay back 110 tokens by calling ***repay*** function in any time within this 365 days, but if he fails to do so and the year passes, family members will be able to liquidate John by calling ***liquidate*** function and taking his collateral in the contract's balance.

Family members can also vote for adding someone as a member that will also participate in voting by ***addMember*** or they can revoke a member by calling ***revokeMember***

## Usage
