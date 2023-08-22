// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}


// ISwap router 0xE592427A0AEce92De3Edee1F18E0157C05861564
// DAI 0xF14f9596430931E177469715c591513308244e8F
// WETH 0xD087ff96281dcf722AEa82aCA57E8545EA9e6C96
// 30 days =2592000
// 1 days = 86400

// Contract Address 0x3EFF061B4983Ccbd2bec4C29Bf51959FB2CDFa93

// Intial WETH Balance 9516539834939667212
// Intial DAI Balance 7999559682150560958838

contract Counter is KeeperCompatibleInterface,Ownable {


    uint public interval;
    uint public lastTimeStamp;
    IERC20 public asset_from;    
    ISwapRouter public immutable swapRouter;
    IERC20 public asset_to;
    uint256 public amount;


    constructor(address _asset_from,address _asset_to,ISwapRouter _swapRouter,uint256 updateInterval,uint256 _amount) {
      interval = updateInterval;
      lastTimeStamp = block.timestamp;
      asset_from=IERC20(_asset_from);
      asset_to=IERC20(_asset_to);
      swapRouter = _swapRouter;
      amount=_amount;
    }

    function changeInterval(uint256 _time) external onlyOwner{
        interval=_time;
    }

    function changeAmount(uint256 _change_amount) external onlyOwner{
        amount=_change_amount;
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        bool condition1=asset_from.balanceOf(address(this)) >0;
        bool condition2=(block.timestamp - lastTimeStamp) > interval;
        if(condition1 && condition2){
            upkeepNeeded==true;
        }
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;
        _convertDaiToEth(amount,asset_from,asset_to);
        performData;
    }

    function widthdraw(uint256 _amount,IERC20 _asset) external onlyOwner{
        _asset.transfer(msg.sender,_amount);
    }

    function _convertDaiToEth(uint256 amountIn,IERC20 _asset_from,IERC20 _asset_to) public returns (uint256) {
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(_asset_from),
                tokenOut: address(_asset_to),
                fee: 3000,
                recipient: owner(),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 amountOut = swapRouter.exactInputSingle(params);
        return amountOut;
    }
    
    function balance(IERC20 _asset,address entity) public view returns(uint256){
        return _asset.balanceOf(entity);
    }
}
