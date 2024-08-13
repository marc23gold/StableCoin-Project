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

    constructor(DSCEngine _dscEngine, StableCoin _dsc) {
        dsce = _dscEngine;
        dsc = _dsc;

        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

    }

    function depositCollateral(uint256 collateralSeed, address collateral, uint256 amountCollateral) public {
        dsce.depositCollateral(collateral, amountCollateral);
    }

    //helper functions 
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns(ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        }
    }
}