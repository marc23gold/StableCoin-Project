//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title DSCEngine
 * @author Bowtiedgojo
 * @notice This is the system that maintains the stability of the stablecoin.
 * 
 * 
 */

import {StableCoin} from "./StableCoin.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract DSCEngine is ReentrancyGuard{
    //errors
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesDoNotMatch();
    error DSCEngine__TokenNotSupported();

    //modifiers
    modifier moreThanZero(uint256 amount) {
        if(amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    //state variables
    mapping (address token => address priceFeed) private s_priceFeeds;
    mapping (address user => mapping(address => uint256 amount)) private s_collateralDeposited;

    StableCoin immutable private i_dsc; 

    

    modifier isAllowedToken(address token) {
        if(s_priceFeeds[token] == address(0)) {
            revert DSCEngine__TokenNotSupported();  
        }
        _;
    } 

    //functions
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses,
    address dscAddress) {
        //USD Price Feeds
        if(tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesDoNotMatch();
        }
        //loop through the price feeds and add them to the mapping
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }

        i_dsc = StableCoin(dscAddress);
    }

    function depositCollateralAndMintDSC() external{
        
    }

    /**
     * 
     * @param tokenCollateralAddress The address fo the token to be deposited as collateral
     * @param amountCollateral The amount of the token to be deposited as collateral
     */

    function depositCollateral(
        address tokenCollateralAddress, 
        uint256 amountCollateral) 
        moreThanZero(amountCollateral) 
        isAllowedToken( tokenCollateralAddress)
        nonReentrant
        external {
        
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