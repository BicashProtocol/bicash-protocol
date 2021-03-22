pragma solidity ^0.6.0;

import './token/BiERC20.sol';

contract Share is BiERC20 {

    uint256 public constant MAX_SUPPLY = 50000 * 10 ** 18;

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
        _mint(recipient_, amount_);
        require(totalSupply() <= MAX_SUPPLY, "max supply");
    }

}
