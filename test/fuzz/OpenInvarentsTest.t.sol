
//SPDX-License-Identifier: MIT

//Will have out invarients: properties of the system that should always hold
//Handler is going to narrow the way we can call functions
//What are our invarents?
//1. The total supply of DSC should be less than the total value of collateral 
//2. Getter view functions should never revoke <- evergreen invariant 

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {StableCoin} from "../../src/StableCoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InvarentsTest is StdInvariant,Test {
    DeployDSC deployer;
    DSCEngine dsce;
    StableCoin dsc;
    HelperConfig config;
    address weth;
    address wbtc;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
       (,,(weth), (wbtc),) = config.activeNetworkConfig();
        //tells foundry go ahead and make this the contrat to run fuzz tests on
        targetContract(address(dsce));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public {
        //arrange   
            //get value of all the collateral in the protocol 
            //compare it to all the debt (dsc)
        uint256 totalSupply = dsc.totalSupply();
        //total amount of weth sent to the contract
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
        //total amount of weth deposited to contract
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dsce));

        uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dsce.getUsdValue(wbtc, totalWbtcDeposited);

        //assert 
        assert(wethValue + wbtcValue >= totalSupply);

        console.log("weth value: ", wethValue);
        console.log("wbtc value: ", wbtcValue);
    }       

    function statefulFuzz_depositCollateral(uint256 amount) public {
        // Example of a function that Foundry can fuzz
        vm.assume(amount > 0 && amount <= IERC20(weth).balanceOf(msg.sender));
        IERC20(weth).approve(address(dsce), amount);
        dsce.depositCollateral(weth, amount);
    }
}