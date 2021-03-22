pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';


contract MockERC20LP is ERC20, Ownable {

    address public token0;
    address public token1;
    uint256 public reserve0;
    uint256 public reserve1;


    constructor(
        string memory name, 
        string memory symbol,
        uint256 mintAmount
    ) public ERC20(name, symbol) {
        _mint(msg.sender, mintAmount);
    }

    function set(address _token0, address _token1, uint256 _r0, uint256 _r1) public {
        token0 = _token0;
        token1 = _token1;
        reserve0 = _r0;
        reserve1 = _r1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = uint112(reserve0);
        _reserve1 = uint112(reserve1);
        _blockTimestampLast = uint32(block.timestamp);
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



