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
import {AggregatorV3Interface} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DSCEngine is ReentrancyGuard {
    //errors
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesDoNotMatch();
    error DSCEngine__TokenNotSupported();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOK();

    //modifiers
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    //state variables

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; //200% overcollataralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18; //1 is the minimum health factor
    uint256 private constant LIQUDATION_BONUS = 10; //10% BONUS since we are diving by 100 in the operation 

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_dscMinted;

    event CollaterialDeposited(address indexed user, address indexed token, uint256 indexed amountCollateral);
    event CollaterialRemoved(address indexed user, address indexed token, uint256 indexed amountCollateral);

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

    /**
     * @notice follows CEI: checks, effects, interactions
     * @param tokenCollateralAddress The address of the token to be deposited as collateral
     * @param amountCollateral The amount of the token to be deposited as collateral
     * @param amountDscToMint The amount of DSC to mint
     */
    function depositCollateralAndMintDSC(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

    /**
     * @notice follows CEI: checks, effects, interactions
     * @param tokenCollateralAddress The address fo the token to be deposited as collateral
     * @param amountCollateral The amount of the token to be deposited as collateral
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
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

    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn) external 
    {
        burnDsc(amountDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
    }

    // There health factor must be over 1 after the collateral pulled out
    //DRY: Don't repeat yourself
    //CEI: checks, effects, interactions 
    /**
     *
     * @param tokenCollateralAddress The address of the token to be redeemed
     * @param amountCollateral The amount of the token to be redeemed
     * This function burns dsc and redeems collateral 
     */
    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] -= amountCollateral;
        //updating state so emit an event
        emit CollaterialRemoved(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transfer(msg.sender, amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    // Checks if the collateral value > DSC amount. Price feeds, value
    /**
     *
     * @param amountDscMint The amount of DSC to mint
     *
     */
    function mintDsc(uint256 amountDscMint) public moreThanZero(amountDscMint) nonReentrant {
        s_dscMinted[msg.sender] += amountDscMint;
        //check: if they minted too much
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    // $100 

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueinUsd) {
        //loop through each collateral token, get the amount they have deposited, and map it to
        //the price, to get the USD value of the collateral
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueinUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueinUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        //going to do some pricefeed stuff
        //get the price feed for the token and times the amount by the price
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        //let's say 1 ETH = 1000 USD the returned value will be 1000 * 1e8
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collaterialValueInUsd)
    {
        //total collateral deposited
        //total DSC minted
        //total collateral value in USD
        totalDscMinted = s_dscMinted[user];
        collaterialValueInUsd = getAccountCollateralValue(user);
    }

    /**
     *
     * @param user The address of the user to check the health factor of
     * @return The health factor of the user
     * if the user goes below 1 then they can get liquidated
     */
    function _healthFactor(address user) private view returns (uint256) {
        //total DSC minted

        //total collateral deposited
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
        //return (collateralValueInUsd / totalDscMinted);
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        //Check collateral value factor
        //revert if they don't have a healthy value factor
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    function burnDsc(uint256 amountToBeBurned) public moreThanZero(amountToBeBurned){
        s_dscMinted[msg.sender] -= amountToBeBurned;
        bool success = i_dsc.transferFrom(msg.sender, address(this), amountToBeBurned);
        if(!success){
            revert DSCEngine__TransferFailed();
        }
        i_dsc.burn(amountToBeBurned);
        _revertIfHealthFactorIsBroken(msg.sender);  
    }

    //if someone is almost undercollateralized, they can be liquidated and you will be rewarded
    /**
     * 
     * @param collaterial collateral to be liquidated
     * @param userToLiquidate user that is being liquidated
     * @param debtCovered debt that's being covered by the 
     * @notice You can partially liquidate a user 
     * @notice You will get a liquidation bonus for taking the users funds
     * @notice This function working assumes the protocol is overcollateralized by 200%
     */
    function liquidate(address collaterial, address userToLiquidate, uint256 debtCovered) external 
    moreThanZero(debtCovered)
     nonReentrant{
        //need to check health factor of the user (checks)
        uint256 startingHealthFactor = _healthFactor(userToLiquidate);
        if(startingHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOK();
        }
        //Burn there DSC debts and take their collateral 
        //Bad User: $140, $100 DSC 
        //DebtToCover: $100
        // $100 DSC == ??? ETH
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(collaterial, debtCovered);
        //Give the liquidator a 10% bonus along with the collateral
        //We are giving the liquidator $110 of WETH for 100 DSC
        //We should implement a feature to liquidate in the event the protocol is insolvent 
        //And sweep extra amounts into a treasury 
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUDATION_BONUS) / LIQUIDATION_PRECISION;

    }

    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns(uint256){
        //price of eth or the token
        //USD amount in wei divided by price 
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return (usdAmountInWei * PRECISION) / (uint256(price)* ADDITIONAL_FEED_PRECISION);
    }
    function getHealthFactor() external {}
}
