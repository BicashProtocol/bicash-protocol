pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import './interfaces/IOracle.sol';
import './utils/Epoch.sol';

/**
 * @title Basis Cash Treasury contract
 * @notice Monetary policy logic to adjust supplies of basis cash assets
 * @author Summer Smith & Rick Sanchez
 */
contract Treasury is Epoch {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    address public cash;
    address public oracle;
    address public shareMasterChef;
    address public boardroom;

    uint256 public cashShareLpPoolPid;

    uint256 public constant cashPriceOne = 10 ** 18;
    uint256 public cashPriceDelta;

    uint256 public maxInflationRate = 20; // div by 100
    
    uint256 public constant pointAddRate = 5;
    uint256 public constant pointSubRate = 10;      
      
    uint256 public constant feeAddRate = 1;
    uint256 public constant feeSubRate = 5;

    // update oracle and get updated price
    // if above $1, tune parameter and allocate cash inflation reward to boardroom
    // if below $1, tune parameter

    constructor(
        address _cash,
        address _oracle,
        address _shareMasterChef,
        address _boardroom,
        uint256 _cashShareLpPoolPid,
        uint256 _starttime,
        uint256 _peroid
    ) public Epoch(_peroid, _starttime, 0){
        cash = _cash;
        oracle = _oracle;
        shareMasterChef = _shareMasterChef;
        boardroom = _boardroom;
        cashShareLpPoolPid = _cashShareLpPoolPid;

        cashPriceDelta = 10 ** 16;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // oracle
    function getOraclePrice() public view returns (uint256) {
        return _getCashPrice(oracle);
    }

    function _getCashPrice(address _oracle) internal view returns (uint256) {
        try IOracle(_oracle).consult(cash, 1e18) returns (uint256 price) {
            return price;
        } catch {
            revert('Treasury: failed to consult cash price from the oracle');
        }
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updateCashPrice() internal {
        try IOracle(oracle).update()  {} catch {}
    }

    function allocateReward()
        external
        checkStartTime
        checkEpoch
    {
        _updateCashPrice();
        uint256 cashPrice = _getCashPrice(oracle);
        // circulating supply
        uint256 cashSupply = IERC20(cash).totalSupply();
        uint256 totalPoints = IMasterChef(shareMasterChef).totalAllocPoint();
        uint256 lpPoints = IMasterChef(shareMasterChef).poolPoint(cashShareLpPoolPid);
        uint256 cashFee = ICash(cash).fee();
        uint256 FEE_ONE = 10 ** 6;

        if (cashPrice >= cashPriceOne.add(cashPriceDelta)) {
            if (cashFee > 0) {
                uint256 subFee = FEE_ONE.mul(feeSubRate).div(100);
                cashFee = cashFee > subFee ? cashFee.sub(subFee) : 0;
                ICash(cash).setFee(cashFee);
            }
            if (lpPoints > 0) {
                uint256 subPoints = totalPoints.mul(pointSubRate).div(100);
                lpPoints = lpPoints > subPoints ? lpPoints.sub(subPoints) : 0;
                IMasterChef(shareMasterChef).set(cashShareLpPoolPid, lpPoints, true);
            }
            uint256 inflation = cashSupply.mul(
                                    cashPrice.sub(cashPriceOne)
                                ).div(10 ** 18).div(10);
            if (inflation > cashSupply.mul(maxInflationRate).div(100)) {
                inflation = cashSupply.mul(maxInflationRate).div(100);
            }
            IBoardroom(boardroom).allocateReward(inflation);
        }

        if (cashPrice <= cashPriceOne.sub(cashPriceDelta)) {
            if (lpPoints >= totalPoints.div(2)) {
                // add cash transfer fee
                cashFee = cashFee.add(FEE_ONE.mul(feeAddRate).div(100));
                if (cashFee > FEE_ONE.div(2)) {
                    cashFee = FEE_ONE.div(2);
                }
                ICash(cash).setFee(cashFee);
            } else {
                lpPoints = lpPoints.add(totalPoints.mul(pointAddRate).div(100));
                IMasterChef(shareMasterChef).set(cashShareLpPoolPid, lpPoints, true);
            }

        }


    }


    /* ========= GOV ============= */

    function setCashPriceDelta(uint256 delta) public onlyOwner {
        cashPriceDelta = delta;
    }

    function setCashShareLpPoolPid(uint256 _pid) public onlyOwner {
        cashShareLpPoolPid = _pid;
    }

    function setMaxInflationRatio(uint256 _rate) public onlyOwner {
        maxInflationRate = _rate;
    }
    
}

interface ICash {
    function setFee(uint256 _fee) external;
    function fee() external view returns(uint256);
}

interface IMasterChef {
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;
    function totalAllocPoint() external view returns(uint256);
    function poolPoint(uint256 _pid) external view returns (uint256); 
}

interface IBoardroom {
    function allocateReward(uint256 amount) external;
}


