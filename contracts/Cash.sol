pragma solidity ^0.6.0;

import './token/BiERC20.sol';

contract Cash is BiERC20 {

    uint256 public mintBalance;

    constructor(
        string memory name, 
        string memory symbol,
        uint256 mintAmount
    ) public BiERC20(name, symbol, mintAmount) {
        
    }

    function mint(address recipient_, uint256 amount_)
        public
        override
        virtual
        onlyMinter
    {
        require(amount_ < mintBalance, "mint balance");
        _mint(recipient_, amount_);
        mintBalance = mintBalance.sub(amount_);
    }

    function setMintBalance(uint256 bal_) public onlyOwner {
        mintBalance = bal_;
    }

    function addMintBalance(uint256 bal_) public onlyOwner {
        mintBalance = mintBalance.add(bal_);
    }

}
