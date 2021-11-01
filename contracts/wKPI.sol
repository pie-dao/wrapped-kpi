// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ILSPair} from "../interfaces/ILSPair.sol";
import {ISharesTimeLock} from "../interfaces/ISharesTimeLock.sol";

contract wKPI is ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint8 MIN_MONTHS = 6;
    uint8 MAX_MONTHS = 36;

    ILSPair public immutable lsPair;
    ISharesTimeLock public immutable sharesTimeLock;

    IERC20 public immutable longToken;
    IERC20 public immutable collateral;

    constructor(address _lsPair, address _timelock)
        ERC20("Wrapped KPI", "wKPI")
    {
        require(_lsPair != address(0), "ZERO_ADDR");
        require(_timelock != address(0), "ZERO_ADDR");

        (address _long, address _collateral) = (
            ILSPair(_lsPair).longToken(),
            ILSPair(_lsPair).collateralToken()
        );

        IERC20(_long).safeApprove(_lsPair, type(uint256).max);

        longToken = IERC20(_long);
        collateral = IERC20(_collateral);

        lsPair = ILSPair(_lsPair);
        sharesTimeLock = ISharesTimeLock(_timelock);
    }

    function mint(uint256 amount) external onlyOwner {
        longToken.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    function settleAndStake(uint256 amount, uint8 months) external {
        require(months >= MIN_MONTHS && months <= MAX_MONTHS);

        _burn(msg.sender, amount);

        uint256 collateralCollected = lsPair.settle(amount, 0);
        sharesTimeLock.depositByMonths(collateralCollected, months, msg.sender);
    }
}
