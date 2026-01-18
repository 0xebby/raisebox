// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Counter {
    uint256 private count;

    event Incremented(uint256 newCount);
    event Reset();

    constructor() {
        count = 0;
    }

    function increment() public {
        count++;
        emit Incremented(count);
    }

    function getCount() public view returns (uint256) {
        return count;
    }

    function reset() public {
        count = 0;
        emit Reset();
    }
}