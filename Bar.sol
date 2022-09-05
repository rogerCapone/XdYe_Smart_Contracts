pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract XdYeBar is ERC20("xXdYe Token Share", "xXdYe"){
    using SafeMath for uint256;
    IERC20 public xdye;

    constructor(IERC20 _xdye) public {
        xdye = _xdye;
    }

    // Enter the XDYE bar. Pay some XDYEs. Earn some shares.
    function enter(uint256 _amount) public {
        uint256 totalXdYe = xdye.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalXdYe == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount.mul(totalShares).div(totalXdYe);
            _mint(msg.sender, what);
        }
        xdye.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the XDYE bar. Claim back your XDYEs.
    function leave(uint256 _share) public {
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(xdye.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        xdye.transfer(msg.sender, what);
    }
}
