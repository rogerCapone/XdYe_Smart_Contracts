pragma solidity 0.6.12;

contract FarmUnlockerBEth {

    struct UserUnlock {
            bool unlocked;
        }

    mapping(address => UserUnlock) public unlockList;
    address payable public governance;
    constructor(address payable _governance) public {
            governance = _governance;
        }

    receive() external payable {
        governance.transfer(msg.value);
    }

    function unlock() public payable returns (bool) {
        require(unlockList[msg.sender].unlocked != true, "Already paied");
        governance.transfer(1000000000000000000);
        unlockList[msg.sender].unlocked = true;
        return true;
    }
}
