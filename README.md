# Family Savings Smart Contract

## Table of Contents

- [Features](#features)
- [Example](#example)
- [Usage](#usage)

## Features

Keep in mind that there are terms used like "family", "members", and "family members". This all technically means the owner of the contract because the contract is the voting based and the mentioned parties are the voters.

- ***deposit*** - Users can deposit assets into the account by calling the deposit function. The deposited assets are stored in the contract's balance and can be withdrawn later or lent. The user must approve a smart contract on a specific asset and amount before calling this function, otherwise, the transaction will revert. Please note that a smart contract is written that way that anyone can deposit assets into any saving account but only members can call withdraw function by voting. This means that the non-owner address has no reason to deposit assets into the account. However, this transaction will not revert because there is no security risk for the family's funds - only benefits.

- ***withdraw*** - Members can call this function to withdraw any amount of any token to any address, the proposal must go through the voting process for it to be executed. Then The specified amount of assets will be transferred back to the specified address. The function does not perform any balance checks. If the family wants to withdraw more assets than they have into a saving account or want to withdraw assets that are not liquidated, the transaction will revert because of insufficient funds or overflow.

- ***setCollateralRate / setCollateralRateBatched*** - The family can set the collateral rate for specific borrowing and lending assets through a voting-based system

- ***setAnnualLendingRate / setAnnualLendingRateBatched*** - The family can set the daily lending rate for specific assets through a voting-based system

- ***borrow*** - Users can borrow assets by providing collateral. The borrow function allows users to specify the borrowing asset, borrowing amount, collateral asset, and borrowing period. The minimum borrowing period is 7 days and can be the subject of discussion. The function calculates the return amount based on the borrowing amount and lending rates, and the required collateral amount based on the collateral rate. The collateral asset is transferred to the contract, and the borrowing asset is transferred to the borrower.

- ***repay*** - Borrowers can repay their borrowings by calling the repay function and specifying the index of borrowing position that he wants to repay. The borrowed assets are transferred back to the contract, and the collateral assets are transferred back to the borrower.

- ***liquidate*** - If a borrower fails to repay their borrowings within the specified borrowing period, the collateral can be liquidated by calling the liquidate function. The collateral assets stay in the contract but now the user can withdraw them. Also, contract storage is updated that way that if a borrower wants to repay an already liquidated borrowing position transaction will pass but the user will not receive any funds and the contract will not take any funds away from him. This can be the subject of discussion. The contract can be changed to revert in that case so the user does not spend his ETH on full transaction fees. Also, anyone can liquidate but will not be incentivized for that.

- ***addMember*** - Family can add a member through a voting-based system that will also be participating in the voting

- ***revokeMember*** -  Family can revoke a member through the voting-based system 


## Example

Let's say the following family members created this family savings contract: Bob (Father), Alice (Mother) and Joe (Son).

If the father wants to deposit 1000 and the mother 500 tokens, they can call ***deposit*** function.

They can either let that tokens just sit in a contract, or they can configure annual lending rate and collateral rates to make the token available for borrowing. Any other address (even the family members) will be able to borrow the mentioned token.

To set specific annual lending (***setAnnualLendingRate***) and collateral rates (***setCollateralRate***) for a token, members of the contract should go through a voting mechanism. In this example the family has 3 members so 2 "In Favor" votes will be needed for the proposal to pass and be executed.

If some John (outside of family) wants to borrow some asset by providing an underlying collateral asset, they can do so by calling ***borrow*** function. Minimum borrow perio should be 7 days and the collateral must be supported by the contract (collateral rate should be existent). Let's say the annual lending rate of the token is 10% and the collateral rate for some other token is 120%. This means that if John wants to borrow 100 tokens for a year (365), John will have to return 100 + (100 * 10%) = 110 tokens by the end of the year and the collateral token provided should be 110 * 120% = 132.

John is able to repay back 110 tokens by calling ***repay*** function in any time within this 365 days, but if he fails to do so and the year passes, family members will be able to liquidate John by calling ***liquidate*** function and taking his collateral in the contract's balance.

Family members can withdraw any amount of any token to any address by calling ***withdraw***, which is also a voting based.

Finally, family members can also vote for adding someone as a member that will also participate in voting by ***addMember*** or they can revoke a member by calling ***revokeMember***

## Usage

1. Clone this repository to your local machine.
2. Install the project dependencies by running `forge install` in the root directory.
3. Compile the files with `forge build`.
4. Create a new branch for your changes: `git checkout -b my-new-feature`.
5. Make the necessary modifications and additions.
6. Test Smart Contract with `forge test` in the root directory.
7. Commit and push your changes: `git commit -m 'Add some feature' && git push origin my-new-feature`.
8. Submit a pull request detailing your changes and their benefits.

If you would like to deploy a smart contract on your local machine do the following:

1. `anvil` to run a local node.
2. Update the variables in files of the `script/` folder to our needs.
3. Deploy the smart contract with `forge script script/{filename}.s.sol --fork-url http://localhost:8545 --broadcast`

   Read More About the Deployment from the [Foundry Book](https://book.getfoundry.sh/forge/deploying)
