//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {StableCoin} from "../../src/StableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    StableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    address wethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (wethUsdPriceFeed,btcUsdPriceFeed, weth,,) = config.activeNetworkConfig();
    }

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

        //Constructor tests
    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public{
            //arrange
            tokenAddresses.push(weth);
            priceFeedAddresses.push(wethUsdPriceFeed); 
            priceFeedAddresses.push(btcUsdPriceFeed);
            // assert
            vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesDoNotMatch.selector);
            // act
            new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
        }

    //deposit collateral tests

    function testGetTokenAmountFromUsd() public {
        //arrange
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = dsce.getTokenAmountFromUsd(weth, usdAmount);
        //act and assert
        assertEq(expectedWeth, actualWeth);
    }

    function testRevertsWithUnapprovedCollateral() public {
        //arrange 
        ERC20Mock ranToken = new ERC20Mock();
        vm.prank(USER);
        //assert (setup)
        vm.expectRevert(DSCEngine.DSCEngine__TokenNotSupported.selector);
        dsce.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        //arrange 
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(USER);
        
        uint256 expectedTotalDscMinted = 0;

        uint256 expectedDepositAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);
        //act and assert 
        assertEq(totalDscMinted, expectedTotalDscMinted); 
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }

    // Price tests
    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);
        assertEq(actualUsd, expectedUsd);
    }


    // Deposit collateral tests
    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();
    }
}
