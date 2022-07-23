//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract USDCReceiver is Ownable{

    IERC20 USDC;

    uint public tokenID = 500;
    uint public MAX_SUPPLY = 500;
    uint public price = 125e6;
    bool public paused;

    mapping(uint=>address) public userBought;

    constructor(address _usdc) {
        USDC = IERC20(_usdc);
    }

    function receiveUSDC(uint _amount) external {
        require(!paused,"Execution paused");
        require(tokenID + _amount <= 500 + MAX_SUPPLY,"Max supply reached");
        require(USDC.transferFrom(msg.sender, address(this), _amount*price),"Underpaid");
        for(uint i=1;i<=_amount;i++){
            userBought[tokenID + i] = msg.sender;
        }
        tokenID += _amount;
    }

    function setPrice(uint _amount) external onlyOwner{
        price = _amount;
    }

    function setPaused(bool _pause) external onlyOwner{
        paused = _pause;
    }

    function setUSDC(address _usdc) external onlyOwner{
        USDC = IERC20(_usdc);
    }

    function setTokenID(uint _id) external onlyOwner{
        tokenID = _id;
    }

    function setMaxSupply(uint _supply) external onlyOwner{
        MAX_SUPPLY = _supply;
    }

    function withdraw() external onlyOwner{
        USDC.transfer(msg.sender,USDC.balanceOf(address(this)));
    }

}
