
//SPDX-License-Identifier: MIT

//Will have out invarients: properties of the system that should always hold
//Handler is going to narrow the way we can call functions
//What are our invarents?
//1. The total supply of DSC should be less than the total value of collateral 
//2. Getter view functions should never revoke <- evergreen invariant 

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

contract InvarentsTest is StdInvariant,Test {
    
}