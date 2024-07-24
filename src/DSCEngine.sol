//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title DSCEngine
 * @author Bowtiedgojo
 * @notice This is the system that maintains the stability of the stablecoin.
 * 
 * 
 */

contract DSCEngine {
    //errors
    error DSCEngine__NeedsMoreThanZero();

    //modifiers
    modifier moreThanZero(uint256 amount) {
        if(amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }
    function depositCollateralAndMintDSC() external{
    }

    /**
     * 
     * @param tokenCollateralAddress The address fo the token to be deposited as collateral
     * @param amountCollateral The amount of the token to be deposited as collateral
     */

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral) external {

    }

    function redeemCollateralForDsc() external{
    }

    function redeemCollateral() external{
    }

    function mintDsc() external{
    }   

    function burnDsc() external{
    }
    function liquidate() external{
    }
    function getHealthFactor() external{
    }

}