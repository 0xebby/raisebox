// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./noom.sol";

contract moon is noom {
    function n(int256 ts) public pure override returns (bytes memory o) {
        o = new bytes(s);
        int256 a = 2551443;
        int256 x = -b;
        int256 y = 2 - b;
        int256 z = (((int256(ts) - 592531) % a) << 9) / a;
        uint256 i;
        while (y <= b) {
            (a, x, y, o[i++]) = ++x >= a
                ? (a, -b, y + 4, l)
                : (
                    x < 0
                        ? (x * x + y * y < b * b) ? (1 - x, -1, y, d) : (a, x + 1, y, d)
                        : (a, x, y, p[(x < a * (~z & 255) >> 8 ? 1 : 0) ^ uint256(z >> 8)])
                );
        }
        // ca on sep: 0xACf01B1Bef9ab418b1B1CB36DdBB1571Cd1Fd998
    }
}
