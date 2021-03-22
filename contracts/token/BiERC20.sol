pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';


contract BiERC20 is ERC20, Ownable {

    mapping (address => bool) public minters;
    mapping (address => bool) public feeSetters;
    mapping (address => bool) public feeFreeSenders;
    mapping (address => bool) public feeFreeReceivers;
    uint256 public fee;
    uint256 public constant FEE_ONE = 10 ** 6;
    uint256 public mintersCount;
    uint256 public feeSettersCount;
    uint256 public feeFreeSendersCount;
    uint256 public feeFreeReceiversCount;

    constructor(
        string memory name, 
        string memory symbol,
        uint256 mintAmount
    ) public ERC20(name, symbol) {
        _mint(msg.sender, mintAmount);
    }

    // =============== MODIFIER ======================
    modifier onlyMinter {
        require(minters[msg.sender], "no minter");

        _;
    }

    modifier onlyFeeSetter {
        require(feeSetters[msg.sender], "no fee setter");

        _;
    }

    // BEP20
    function getOwner() external view returns (address) {
        return owner();
    }

    // ================ OVERRIDE =====================
    function _transfer(
        address sender, 
        address recipient, 
        uint256 amount
    ) 
        internal 
        override
        virtual 
    {
        if (fee > 0 && !feeFreeSenders[sender] && !feeFreeReceivers[recipient]) {
            uint256 feeAmount = amount.mul(fee).div(FEE_ONE);
            _burn(sender, feeAmount);
            super._transfer(sender, recipient, amount.sub(feeAmount));
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    // ================ GOVERNANCE ====================
    function mint(address recipient_, uint256 amount_)
        public
        virtual
        onlyMinter
    {
        _mint(recipient_, amount_);
    }

    function burn(address account, uint256 amount)
        public
        onlyMinter
    {
        _burn(account, amount);
    }

    function setFee(uint256 _fee) public onlyFeeSetter {
        require(_fee < FEE_ONE, "invalid");
        fee = _fee;
    }

    function setMinter(address _minter, bool _set) public onlyOwner {
        if (!minters[_minter] && _set) {
            mintersCount = mintersCount.add(1);
        }
        if (minters[_minter] && !_set) {
            mintersCount = mintersCount.sub(1);
        }
        minters[_minter] = _set;
    }

    function setFeeSetter(address _feeSetter, bool _set) public onlyOwner {
        if (!feeSetters[_feeSetter] && _set) {
            feeSettersCount = feeSettersCount.add(1);
        }
        if (feeSetters[_feeSetter] && !_set) {
            feeSettersCount = feeSettersCount.sub(1);
        }
        feeSetters[_feeSetter] = _set;
    }

    function setFeeFreeSender(address _feeFreeSender, bool _set) public onlyOwner {
        if (!feeFreeSenders[_feeFreeSender] && _set) {
            feeFreeSendersCount = feeFreeSendersCount.add(1);
        }
        if (feeFreeSenders[_feeFreeSender] && !_set) {
            feeFreeSendersCount = feeFreeSendersCount.sub(1);
        }
        feeFreeSenders[_feeFreeSender] = _set;
    }

    function setFeeFreeReceiver(address _feeFreeReceiver, bool _set) public onlyOwner {
        if (!feeFreeReceivers[_feeFreeReceiver] && _set) {
            feeFreeReceiversCount = feeFreeReceiversCount.add(1);
        }
        if (feeFreeReceivers[_feeFreeReceiver] && !_set) {
            feeFreeReceiversCount = feeFreeReceiversCount.sub(1);
        }
        feeFreeReceivers[_feeFreeReceiver] = _set;
    }

}



