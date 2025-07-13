// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Sample Raffle Contract
 * @author MariooY2
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2+
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /*Errors*/
    error Raffle_NotEnoughETHtoEnter();
    error Raffle_NotOpen();
    error Raffle_TransferFailed();
    error Raffle_UpKeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 raffleState
    );

    /*Type Declarations*/
    enum RaffleState {
        OPEN, //0
        CALCULATING //1
    }

    /*Constants*/
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 constant CALLBACK_GAS_LIMIT = 100000;
    uint32 constant NUM_WORDS = 1;

    /*State Variables*/
    uint256 private immutable i_entranceFee; //Slot 1
    uint256 private immutable i_interval; //Slot 2
    bytes32 private immutable i_keyHash; //Slot 4
    uint256 private immutable i_subscriptionId; //Slot 5
    uint256 private s_lastTimeStamp; //Slot 6
    address private s_recentWinner; //Slot 7
    address payable[] private s_players; //Slot 8
    RaffleState private s_raffleState;

    /*Events*/
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed Winner);
    event ReturnedRandomness(uint256 randomWord);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        s_raffleState = RaffleState.OPEN; //same as RaffleState(0)
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) revert Raffle_NotEnoughETHtoEnter();
        if (s_raffleState != RaffleState.OPEN) revert Raffle_NotOpen();

        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function performUpkeep(bytes calldata /*PerformData*/) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded)
            revert Raffle_UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );

        s_raffleState = RaffleState.CALCULATING;
        // Will revert if subscription is not set and funded.
        s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        (bool success, ) = recentWinner.call{value: address(this).balance}("");

        if (!success) revert Raffle_TransferFailed();

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);

        emit ReturnedRandomness(randomWords[0]);
        emit WinnerPicked(recentWinner);
    }

    /**
     * @dev This is the function that chainlink nodes will call to see
     * if the lottery is ready to have a winner picked.
     * The following should return true in order for upkeepNeeded to be true
     * 1. The time interval has passed between raffle runs
     * 2. The lottery is open
     * 3. The contract has ETH
     * 4. Implicitly, yout subscription has LINK
     * @param -ignored
     * @return upkeepNeeded
     */
    function checkUpkeep(
        bytes memory /*CheckData*/
    ) public view returns (bool upkeepNeeded, bytes memory /*Perform Data*/) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp > i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }

    /**
     * Getter Functions
     */

    function getEntranceeFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }
}
