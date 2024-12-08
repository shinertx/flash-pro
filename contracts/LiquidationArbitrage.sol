// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * This contract will:
 * 1. Take a flash loan from Aave.
 * 2. Perform liquidation on an undercollateralized position.
 * 3. Repay the flash loan and keep profit.
 *
 * NOTE: Addresses of Aave Pool and lending markets must be configured for mainnet.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Aave v2 LendingPool for mainnet: 0x7d2768de32b0b80b7a3454c06bdac94a69ddc7a9
interface ILendingPool {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

// Example Interface for liquidation on Aave
interface ILendingPoolLiquidation {
    function liquidationCall(
        address collateral,
        address debt,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;
}

contract LiquidationArbitrage {
    address public owner;
    ILendingPool public lendingPool;

    constructor(address _lendingPool) {
        owner = msg.sender;
        lendingPool = ILendingPool(_lendingPool);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /**
     * @dev This is called after we receive the flash loaned amounts
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address, /*initiator*/
        bytes calldata params
    ) external returns (bool) {
        require(msg.sender == address(lendingPool), "Caller must be lending pool");

        // Decode params: collateral, debt, user, debtToCover
        (address collateral, address debtAsset, address user, uint256 debtToCover, address liquidationAddr) = 
            abi.decode(params, (address, address, address, uint256, address));

        // Approve debtAsset for liquidation
        IERC20(debtAsset).approve(liquidationAddr, debtToCover);

        // Perform liquidation
        ILendingPoolLiquidation(liquidationAddr).liquidationCall(collateral, debtAsset, user, debtToCover, false);

        // After liquidation, we should have received collateral tokens at a discount.
        // Sell collateral for the debtAsset or a stable token here if needed.
        // For simplicity, assume collateral is already the asset we can use to repay.

        // Repay flash loan + premium
        for (uint i = 0; i < assets.length; i++) {
            uint256 amountOwing = amounts[i] + premiums[i];
            IERC20(assets[i]).approve(address(lendingPool), amountOwing);
        }
        return true;
    }

    function executeFlashLoan(
        address asset,
        uint256 amount,
        bytes calldata params
    ) external onlyOwner {
        address[] memory assets = new address[](1);
        assets[0] = asset;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0; // no debt

        lendingPool.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            params,
            0
        );
    }
}
