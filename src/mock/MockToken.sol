// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RaiseBoxEventsLib} from "src/RaiseBoxLib/RaiseBoxEventsLib.sol";

contract MockToken is ERC20 {

    uint256 public constant CLAIM_AMOUNT = 10_000 * 10**18;

    uint256 public constant COOLDOWN_PERIOD = 24 hours;
    
    mapping(address => uint256) public lastClaimTime;

    constructor(uint256 initialSupply) ERC20("Solstruct", "SLT") {
        _mint(msg.sender, initialSupply);
    }

    // External functions
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }test/TestsHelpers.sol

}
