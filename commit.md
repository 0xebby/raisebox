# RaiseBox Dual Currency Implementation - Commit Summary

## 🎯 Overview
This commit implements comprehensive dual currency support (ETH + ERC20) for the RaiseBox crowdfunding platform, transforming it from ETH-only to a multi-token ecosystem while maintaining full backward compatibility.

## 🏗️ Core Architecture Changes

### 1. Payment Method Enumeration
**File:** `src/interfaces/IRaiseBoxCore.sol`
- **Added:** `PaymentMethod` enum with `ETH` and `ERC20` options
- **Added:** `paymentMethod` field to `ProjectInfo` struct
- **Impact:** Foundation for dual currency support across entire platform

### 2. Contribution Logic Refactor
**File:** `src/RaiseBoxContribution.sol`
- **Restructured:** Validation flow to handle ETH vs ERC20 separately
- **Updated:** Error messages to be currency-agnostic
- **Added:** Proper token balance and allowance validation for ERC20

### 3. Drip Handler Enhancement
**File:** `src/RaiseBoxDripHandler.sol`
- **Added:** IERC20 import and SafeERC20 usage
- **Implemented:** Conditional dripping logic based on payment method
- **ETH Path:** Uses `call{value:}` for ETH transfers
- **ERC20 Path:** Uses `token.transfer()` for ERC20 tokens
- **Added:** ERC20-specific balance checking with new error type

## 🛡️ Error Handling Improvements

### New Error Types Added
**File:** `src/RaiseBoxLib/RaiseBoxErrorsLib.sol`
```solidity
error RaiseBoxContribution_ETHERSentForERC20Raise();
error RaiseBoxContribution_InsufficientTokenBalance();
error RaiseBoxCreation_createRaise_ERC20TokenNotSet();
```

**File:** `src/interfaces/IRaiseBoxDripHandler.sol`
```solidity
error Drip_InsufficientBalanceECR20(uint256 dripBalance, uint256 required);
```
# Test
All test passing with erc20 contribution (raisebox/test/TokenTest.t.sol)
There was an Issue: the `getAcceptedToken()` was returning immutable iRBT (zero address) instead of iRBTInstance which is the address and 
since the logic depends on getting the address of token it would always return 0x00 even when set so this has been fixed to return the 
`address(iRBTInstance)` instead of `iRBT`.

todo: refactor the error messages that uses strings
