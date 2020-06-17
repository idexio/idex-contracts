// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  SafeMath as SafeMath256
} from '@openzeppelin/contracts/math/SafeMath.sol';


/**
 * @dev This library provides helper utilities for transfering assets in and out of contracts.
 * It further validates ERC-20 compliant balance updates in the case of token assets
 */
library AssetTransfers {
  using SafeMath256 for uint256;

  /**
   * @dev Transfers tokens from a wallet into a contract during deposits. `wallet` must already
   * have called `approve` on the token contract for at least `tokenQuantity`. Note this only
   * applies to tokens since ETH is sent in the deposit transaction via `msg.value`
   */
  function transferFrom(
    address wallet,
    address tokenAddress,
    uint256 quantityInAssetUnits
  ) internal {
    uint256 balanceBefore = IERC20(tokenAddress).balanceOf(address(this));

    try
      IERC20(tokenAddress).transferFrom(
        wallet,
        address(this),
        quantityInAssetUnits
      )
    returns (bool success) {
      require(success, 'Token transfer failed');
    } catch Error(
      string memory /*reason*/
    ) {
      revert('Token transfer failed');
    }

    uint256 balanceAfter = IERC20(tokenAddress).balanceOf(address(this));
    require(
      balanceAfter.sub(balanceBefore) == quantityInAssetUnits,
      'Token contract returned transferFrom success without expected balance change'
    );
  }

  /**
   * @dev Transfers ETH or token assets from a contract to 1) another contract, when `Exchange`
   * forwards funds to `Custodian` during deposit or 2) a wallet, when withdrawing
   */
  function transferTo(
    address payable walletOrContract,
    address asset,
    uint256 quantityInAssetUnits
  ) internal {
    if (asset == address(0x0)) {
      require(
        walletOrContract.send(quantityInAssetUnits),
        'ETH transfer failed'
      );
    } else {
      uint256 balanceBefore = IERC20(asset).balanceOf(walletOrContract);

      try
        IERC20(asset).transfer(walletOrContract, quantityInAssetUnits)
      returns (bool success) {
        require(success, 'Token transfer failed');
      } catch Error(
        string memory /*reason*/
      ) {
        revert('Token transfer failed');
      }

      uint256 balanceAfter = IERC20(asset).balanceOf(walletOrContract);
      require(
        balanceAfter.sub(balanceBefore) == quantityInAssetUnits,
        'Token contract returned transfer success without expected balance change'
      );
    }
  }
}
