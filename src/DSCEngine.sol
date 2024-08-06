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
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DSCEngine is ReentrancyGuard {
    //errors
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesDoNotMatch();
    error DSCEngine__TokenNotSupported();
    error DSCEngine__TransferFailed();

    //modifiers
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    //state variables
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_dscMinted;

    event CollaterialDeposited(address indexed user, address indexed token, uint256 indexed amountCollateral);

    StableCoin private immutable i_dsc;

    address[] private s_collateralTokens;

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__TokenNotSupported();
        }
        _;
    }

    //functions
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        //USD Price Feeds
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesDoNotMatch();
        }
        //loop through the price feeds and add them to the mapping
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }

        i_dsc = StableCoin(dscAddress);
    }

    function depositCollateralAndMintDSC() external {}

    /**
     * @notice follows CEI: checks, effects, interactions
     * @param tokenCollateralAddress The address fo the token to be deposited as collateral
     * @param amountCollateral The amount of the token to be deposited as collateral
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollaterialDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    // Checks if the collateral value > DSC amount. Price feeds, value
    /**
     * 
     * @param amountDscMint The amount of DSC to mint
     * 
     */
    function mintDsc(uint256 amountDscMint) 
        external
        moreThanZero(amountDscMint)
        nonReentrant
        {
            s_dscMinted[msg.sender] += amountDscMint;
            //check: if they minted too much
            _revertIfHealthFactorIsBroken(msg.sender);
    }

    function getAccountCollateralValue(address user) public view returns (uint256) {
        //loop through each collateral token, get the amount they have deposited, and map it to
        //the price, to get the USD value of the collateral 
    }

    function _getAccountInformation(address user) private view returns(uint256 totalDscMinted, uint256 collaterialValueInUsd) {
        //total collateral deposited
        //total DSC minted
        //total collateral value in USD
        totalDscMinted = s_dscMinted[user];
        collateralvalueInUsd = getAccountCollateralValue(user);
    }

    /**
     * 
     * @param user The address of the user to check the health factor of
     * @return The health factor of the user
     * if the user goes below 1 then they can get liquidated    
     */

    function _healthFactor(address user) private view returns(uint256) {
      //total DSC minted

      //total collateral deposited 
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
    }

    function _revertIfHealthFactorIsBroken(address user) internal view{
        //Check collateral value factor
        //revert if they don't have a healthy value factor
    }

    function burnDsc() external {}
    function liquidate() external {}
    function getHealthFactor() external {}
}
