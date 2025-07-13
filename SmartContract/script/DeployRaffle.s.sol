// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import {Raffle} from "src/Raffle.sol";
import {Script,console} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployRaffle is Script{
    function run()public{}

    function deployContract()public returns (Raffle,HelperConfig){
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getConfig();

        console.log(networkConfig.vrfCoordinator);
        console.log(networkConfig.entranceFee);
        console.log(networkConfig.interval);
        console.log(networkConfig.subscriptionId);
        console.log("Deploying Raffle Contract with the following config:");

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            networkConfig.entranceFee,
            networkConfig.interval,
            networkConfig.vrfCoordinator,
            networkConfig.gasLane,
            networkConfig.subscriptionId
        );
        console.log("Raffle Contract Deployed at: ", address(raffle));
        vm.stopBroadcast();

        return (raffle,config);

    }
}