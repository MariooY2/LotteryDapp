// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title A Sample Raffle Contract
 * @author MariooY2
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */

contract Raffle {
    /* Errors */
    error Raffle_NotEnoughETHtoEnter();
    /* State Variables*/
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;

    /*Events*/
    event RaffleEntered(address indexed player);

    //test
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) revert Raffle_NotEnoughETHtoEnter();

        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function pickWinner() public {

        
    }

    /**
     * Getter Functions
     */
    function getEntranceeFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
