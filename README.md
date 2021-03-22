# Bi Cash

Bi Cash is a experiment implementation of the [Basis Protocol](basis.io) on Binance Smart Chain. 

## Contract Addresses
| Contract  | Address |
| ------------- | ------------- |
| Bi Cash (HIC) | [](https://etherscan.io/token/) |
| Bi Share (HIS) | [](https://etherscan.io/token/) |
| Treasury | [](https://etherscan.io/address/) |
| Cash MasterChef | [](https://etherscan.io/address/) |
| Share MasterChef | [](https://etherscan.io/address/) |
| Timelock 12h | [](https://etherscan.io/address/#code) |

## Features
1. Two Token
2. Stake Lp earn Share, init LP BUSD/BIC, BUSD/BIS, changed over time
3. Stake BIC/BIS lp earn the inflation Cash, locked 3 days
4. When under water, BIC/BIS will add the share farming pool, and the reward ratio go up 5% every epoch, max 80%, when up water, go down 10% until 0%
5. if BIC/BIS share farming poll reward ratio 80% and still under water, transfer fee will be set, go up 0.1% every epoch, when up water, transfer fee go down 0.5% until 0%
