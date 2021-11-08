// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ILSPair} from "../interfaces/ILSPairUpgradeable.sol";
import {ISharesTimeLock} from "../interfaces/ISharesTimeLockUpgradeable.sol";

contract wLSPair is ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint8 MIN_MONTHS = 6;
    uint8 MAX_MONTHS = 36;

    ILSPair public lsPair; // 0x79b6BD0FC723746bC9eAEFeF34613cF4596E6dEF
    ISharesTimeLock public sharesTimeLock; // 0x6Bd0D8c8aD8D3F1f97810d5Cc57E9296db73DC45

    address public longToken; //0x1e09bD2DeEE39fB3E0d98EB9F6355CBC75e63522
    address public collateral; // 0xad32A8e6220741182940c5aBF610bDE99E737b2D

    event SettleAndStake(
        address indexed account,
        uint256 indexed amountStaked,
        uint8 indexed months
    );

    // Prevents implementation initialization
    constructor() {
        _lsPair = address(1);
    }

    function initialize(address _lsPair, address _timeLock)
        external
        initializer
    {
        if (_lsPair == address(1)) return;

        __Ownable_init();
        __ERC20_init("Wrapped PieDAO staked DOUGH KPI Option", "wDOUGH-KPI");

        lsPair = ILSPair(_lsPair);
        sharesTimeLock = ISharesTimeLock(_timeLock);

        longToken = lsPair.longToken();
        collateral = lsPair.collateralToken();

        IERC20(longToken).safeApprove(_lsPair, type(uint256).max);
        IERC20(collateral).safeApprove(_timeLock, type(uint256).max);
    }

    function mint(uint256 amount) external onlyOwner {
        longToken.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    function settleAndStake(uint256 amount, uint8 months) external {
        require(
            months >= MIN_MONTHS && months <= MAX_MONTHS,
            "Invalid months to stake"
        );

        _burn(msg.sender, amount);

        uint256 collateralCollected = lsPair.settle(amount, 0);
        sharesTimeLock.depositByMonths(collateralCollected, months, msg.sender);

        emit SettleAndStake(msg.sender, collateralCollected, months);
    }
}
