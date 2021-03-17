# Autonomous Proposal (AP)

Aave Autonomous Proposals are smart contracts that are able to receive 
delegation of proposition power from AAVE/stkAAVE tokens and submit a 
pre-configured proposal to the Aave governance.

# Contracts

_**APFactory**_

The factory contract allows anyone to create and deploy an autonomous proposal (AP). It is able to predetermine the address for an AP that people may delegate their proposition power to **before** it is deployed. Therefore, the creator only calls the create function if he/she knows it has enough proposition power to succeed, which saves gas.

_**AP**_

This contract calls the create function of Aave Governance V2. It emits the address, proposal id, and creator of the AP. It is called by the Factory contract when the AP attains enough delegated proposition power. 

## Instructions
Prerequisites: [Hardhat](https://hardhat.org/)

To compile the contracts, `npx hardhat compile`

To run the tests, `npx hardhat test`