//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {AggregatorV3Interface} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleLib
 * @author Bowtiedgojo
 * @notice A library for checking chainlink oracles for stale data.
 * If a price is stale function will revert and render to DSCEngine unusable.
 * We want to DSCEngine to freeze if prices become stale.
 */
library OracleLib {
    function stalePriceCheck(AggregatorV3Interface priceFeed)
        public
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {}
}
