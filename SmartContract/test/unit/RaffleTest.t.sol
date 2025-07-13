// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;

    /*Events*/
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed Winner);
    event ReturnedRandomness(uint256 randomWord);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    /*Raffle Initialization Tests*/
    function testRaffleInitialization() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assertEq(raffle.getEntranceeFee(), entranceFee);
    }

    /*Raffle Reverts if there is not enough eth sent */
    function testRaffleRevertsIfNotEnoughEth() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle_NotEnoughETHtoEnter.selector);
        raffle.enterRaffle{value: entranceFee - 1}();
        vm.stopPrank();
    }

    /*Test Player Joining Raffle */
    function testRaffleRecordsWhenPlayerEnters() public {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();

        assertEq(raffle.getNumberOfPlayers(), 1);
        assertEq(raffle.getPlayer(0), PLAYER);
    }

    /* This tests if the RaffleEntered event is emitted with the
     PLAYER's address from the raffle contract */
    function testEnteringRaffleEmitsEvent() public {
        vm.startPrank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));

        emit RaffleEntered(PLAYER); //Expected Event That should be emitted
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
    }
}
