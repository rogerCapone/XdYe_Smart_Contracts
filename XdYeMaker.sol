pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./uniswapv2/interfaces/IUniswapV2ERC20.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";

contract XdYeMaker {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2Factory public factory;
    address public bar;
    address public xdye;
    address public weth;
    
    address public checker;
    address public protocol;

    constructor(IUniswapV2Factory _factory, address _bar, address _xdye, address _weth, address _checker, address _protocol) public {
        factory = _factory;
        xdye = _xdye;
        bar = _bar;
        weth = _weth;
        checker = _checker;
        protocol = _protocol;
    }

    function convert(address token0, address token1) public {
        // At least we try to make front-running harder to do.
        require(msg.sender == tx.origin, "do not convert from contract");
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        pair.transfer(address(pair), pair.balanceOf(address(this)));
        pair.burn(address(this));
        uint256 wethAmount = _toWETH(token0) + _toWETH(token1);
        _toXDYE(wethAmount);
    }

    function _toWETH(address token) internal returns (uint256) {
        if (token == xdye) {
            uint amount = IERC20(token).balanceOf(address(this));
            _safeTransfer(token, factory.getPair(weth, xdye), (amount*25)/100);
            _fromXDYE((amount*25)/100);
            _safeTransfer(token, protocol, (amount*25)/100);
            _safeTransfer(token, bar, (amount*50)/100);
            return 0;
        }
        if (token == weth) {
            uint amount = IERC20(token).balanceOf(address(this));
            _safeTransfer(token, checker, (amount*25)/100);
            _safeTransfer(token, protocol, (amount*25)/100);
            _safeTransfer(token, factory.getPair(weth, xdye), (amount*50)/100);
            return (amount*50)/100;
        }
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token, weth));
        if (address(pair) == address(0)) {
            return 0;
        }
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == token ? (reserve0, reserve1) : (reserve1, reserve0);
        uint amountIn = IERC20(token).balanceOf(address(this));
        uint amountInWithFee = amountIn.mul(995);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint amountOut = numerator / denominator;
        (uint amount0Out, uint amount1Out) = token0 == token ? (uint(0), amountOut) : (amountOut, uint(0));
        _safeTransfer(token, address(pair), amountIn);
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
        _safeTransfer(weth, checker, (amountOut*25)/100);
        _safeTransfer(weth, protocol, (amountOut*25)/100);
        _safeTransfer(weth, factory.getPair(weth, xdye), (amountOut*50)/100);
        return (amountOut*50)/100;
    }

    function _toXDYE(uint256 amountIn) internal {
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(weth, xdye));
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == weth ? (reserve0, reserve1) : (reserve1, reserve0);
        uint amountInWithFee = amountIn.mul(995);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint amountOut = numerator / denominator;
        (uint amount0Out, uint amount1Out) = token0 == weth ? (uint(0), amountOut) : (amountOut, uint(0));
        pair.swap(amount0Out, amount1Out, bar, new bytes(0));
    }

    function _fromXDYE(uint256 amountIn) internal {
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(weth, xdye));
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == xdye ? (reserve0, reserve1) : (reserve1, reserve0);
        uint amountInWithFee = amountIn.mul(995);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint amountOut = numerator / denominator;
        (uint amount0Out, uint amount1Out) = token0 == xdye ? (uint(0), amountOut) : (amountOut, uint(0));
        pair.swap(amount0Out, amount1Out, checker, new bytes(0));
    }

    function changeChecker(address _checker) public {
        require(msg.sender == checker);
        checker = _checker;
    }
    
    function changeProtocol(address _protocol) public {
        require(msg.sender == checker);
        protocol = _protocol;
    }

    function _safeTransfer(address token, address to, uint256 amount) internal {
        IERC20(token).safeTransfer(to, amount);
    }
}
