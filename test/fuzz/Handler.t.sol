//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {StableCoin} from "../../src/StableCoin.sol";

contract Handler is Test {
    DSCEngine dsce;
    StableCoin dsc;

    constructor(DSCEngine _dscEngine, StableCoin _dsc) {
        dsce = _dscEngine;
        dsc = _dsc;
    }

    function depositCollateral(address collateral, uint256 amountCollateral) public {
        dsce.depositCollateral(collateral, amountCollateral);
    }
}