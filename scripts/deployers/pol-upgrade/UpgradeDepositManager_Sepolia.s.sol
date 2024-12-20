// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script, stdJson, console2 as console} from "forge-std/Script.sol";

// These imports get generated by npm run generate:interfaces
import {Registry} from "../../helpers/interfaces/Registry.generated.sol";
import {Governance} from "../../helpers/interfaces/Governance.generated.sol";
import {DepositManager} from "../../helpers/interfaces/DepositManager.generated.sol";
import {DepositManagerProxy} from "../../helpers/interfaces/DepositManagerProxy.generated.sol";
import {ERC20} from "../../helpers/interfaces/ERC20.generated.sol";

contract UpgradeDepositManager_Sepolia is Script {
    using stdJson for string;

    function run() public {
        uint256 deployerPrivateKey = vm.promptSecretUint("Enter deployer private key: ");

        string memory input = vm.readFile("scripts/deployers/pol-upgrade/input.json");
        string memory chainIdSlug = string(abi.encodePacked('["', vm.toString(block.chainid), '"]'));
        address governanceAddress = input.readAddress(string.concat(chainIdSlug, ".governance"));
        address matic = input.readAddress(string.concat(chainIdSlug, ".matic"));
        address polToken = input.readAddress(string.concat(chainIdSlug, ".polToken"));
        address migration = input.readAddress(string.concat(chainIdSlug, ".migration"));
        address registryAddress = input.readAddress(string.concat(chainIdSlug, ".registry"));
        address payable depositManagerProxyAddress = payable(input.readAddress(string.concat(chainIdSlug, ".depositManagerProxy")));
        address nativeGasTokenAddress = address(0x0000000000000000000000000000000000001010);

        Registry registry = Registry(registryAddress);
        Governance governance = Governance(governanceAddress);

        // STEP 1
        // Call updateContractMap on registry to add “matic”, “pol” and “polygonMigration”

        // pol
        bytes memory payloadContractMapPol = abi.encodeWithSelector(
            governance.update.selector, registryAddress, abi.encodeWithSelector(registry.updateContractMap.selector, keccak256("pol"), polToken)
        );

        console.log("Send payloadContractMapPol to: ", governanceAddress);
        console.logBytes(payloadContractMapPol);

        // matic
        bytes memory payloadContractMapMatic = abi.encodeWithSelector(
            governance.update.selector, registryAddress, abi.encodeWithSelector(registry.updateContractMap.selector, keccak256("matic"), matic)
        );

        console.log("\n Send payloadContractMapMatic to: ", governanceAddress);
        console.logBytes(payloadContractMapMatic);

        // polygonMigration
        bytes memory payloadContractMapMigration = abi.encodeWithSelector(
            governance.update.selector, registryAddress, abi.encodeWithSelector(registry.updateContractMap.selector, keccak256("polygonMigration"), migration)
        );

        console.log("\n Send payloadContractMapMigration to: ", governanceAddress);
        console.logBytes(payloadContractMapMigration);

        // STEP 2
        // call mapToken on the Registry to map POL to the PoS native gas token address (1010)

        bytes memory payloadMapToken = abi.encodeWithSelector(
            governance.update.selector, registryAddress, abi.encodeWithSelector(registry.mapToken.selector, polToken, nativeGasTokenAddress, false)
        );

        console.log("\n Send payloadMapToken to: ", governanceAddress);
        console.logBytes(payloadMapToken);

        // STEP 3
        // deploy new DepositManager version and update proxy

        // deploy impl
        vm.startBroadcast(deployerPrivateKey);

        DepositManager depositManagerImpl;
        depositManagerImpl = DepositManager(payable(deployCode("out/DepositManager.sol/DepositManager.json")));

        vm.stopBroadcast();

        DepositManager depositManager = DepositManager(depositManagerProxyAddress);
        DepositManagerProxy depositManagerProxy = DepositManagerProxy(depositManagerProxyAddress);

        // update proxy
        bytes memory payloadUpgradeDepositManager = abi.encodeWithSelector(depositManagerProxy.updateImplementation.selector, address(depositManagerImpl));

        console.log("\n Send payloadUpgradeDepositManager to: ", address(depositManagerProxy));
        console.logBytes(payloadUpgradeDepositManager);

        // STEP 4
        // call migrateMatic on the new DepositManager, migrating all MATIC
        bytes memory payloadMigrateMatic = abi.encodeWithSelector(
            governance.update.selector, address(depositManagerProxy), abi.encodeWithSelector(depositManager.migrateMatic.selector)
        );

        console.log("\n Send payloadMigrateMatic to: ", governanceAddress);
        console.logBytes(payloadMigrateMatic);
    }
}
