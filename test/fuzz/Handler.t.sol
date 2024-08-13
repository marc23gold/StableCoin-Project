//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {StableCoin} from "../../src/StableCoin.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract Handler is Test {
    DSCEngine dsce;
    StableCoin dsc;
    ERC20Mock weth;
    ERC20Mock wbtc;
    uint256 constant MAX_DEPOSIT = type(uint96).max;

    constructor(DSCEngine _dscEngine, StableCoin _dsc) {
        dsce = _dscEngine;
        dsc = _dsc;

        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

    }

    function mintDsc(uint256 amount) public {
        amount = bound(amount, 1, MAX_DEPOSIT);
        vm.startPrank(msg.sender);
        dsce.mintDsc(amount);
        vm.stopPrank();
    }

    function depositCollateral(uint256 collateralSeed, address collateral, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);

        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT);
        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dsce), amountCollateral);

        dsce.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
    }

    function redeemCollateral(uint256 collateralSeed, address collateral, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralToRedeem = dsce.getCollateralBalanceOfUser(address(collateral), msg.sender);
        amountCollateral = bound(amountCollateral, 1, maxCollateralToRedeem);
        if (amountCollateral == 0) {
            return;
        }
        dsce.redeemCollateral(address(collateral), amountCollateral);
    }   

    //helper functions 
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns(ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        }
    }
}