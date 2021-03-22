pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';


contract MockERC20 is ERC20, Ownable {

    constructor(
        string memory name, 
        string memory symbol,
        uint256 mintAmount
    ) public ERC20(name, symbol) {
        _mint(msg.sender, mintAmount);
    }

    
    // ================ GOVERNANCE ====================
    function mint(address recipient_, uint256 amount_)
        public
        onlyOwner
    {
        _mint(recipient_, amount_);
    }

    function burn(address account, uint256 amount)
        public
        onlyOwner
    {
        _burn(account, amount);
    }

}



