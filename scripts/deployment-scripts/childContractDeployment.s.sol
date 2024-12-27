// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import {Script, stdJson, console} from "forge-std/Script.sol";

import {ChildChain} from "../helpers/interfaces/ChildChain.generated.sol";
import {ChildERC20Proxified} from "../helpers/interfaces/ChildERC20Proxified.generated.sol";
import {ChildTokenProxy} from "../helpers/interfaces/ChildTokenProxy.generated.sol";
import {ChildERC721Proxified} from "../helpers/interfaces/ChildERC721Proxified.generated.sol";

contract ChildContractDeploymentScript is Script {
  ChildChain childChain; 
  ChildERC20Proxified childMaticWethPRoxified;
  ChildTokenProxy childMaticWethProxy;

  function run() public {
     uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    vm.startBroadcast(deployerPrivateKey);
    string memory path = "scripts/contractAddresses.json";
    string memory json = vm.readFile(path);
    
    address maticWethAddress = vm.parseJsonAddress(json, ".maticWETH");
    

    childChain = ChildChain(payable(deployCode("out/ChildChain.sol/ChildChain.json")));
    console.log("childChain address : ", address(childChain));

    // Deploy MaticWeth (ERC20) child contract and its proxy.
    // Initialize the contract, update the child chain and map the token with its root contract.

    childMaticWethPRoxified = ChildERC20Proxified(payable(deployCode("out/ChildERC20Proxified.sol/ChildERC20Proxified.json")));
    console.log("Child MaticWethProxified deployed at : ", address(childMaticWethPRoxified));

    childMaticWethProxy = ChildTokenProxy(payable(deployCode("out/ChildTokenProxy.sol/ChildTokenProxy.json", abi.encode(address(childMaticWethPRoxified)))));
    console.log("Child MaticWeth Proxy deployed! at : ", address(childMaticWethProxy));

    ChildERC20Proxified childMaticWeth = ChildERC20Proxified(address(childMaticWethProxy));
    console.log("Abstraction successful!");

    // first parameter should be MaticWeth Address. 
    childMaticWeth.initialize(maticWethAddress, 'Eth on Matic', 'ETH', 18);
    console.log('Child MaticWeth contract initialized');

    childMaticWeth.changeChildChain(address(childChain));
    console.log("Child MaticWeth child chain updated");

    // first address should be MaticWeth address : 
    childChain.mapToken(maticWethAddress, address(childMaticWeth), false);
    console.log("Root and child MaticWeth contracts mapped");

    // Same thing for TestToken(ERC20)
    ChildERC20Proxified childTestTokenProxified = ChildERC20Proxified(payable(deployCode("out/ChildERC20Proxified.sol/ChildERC20Proxified.json")));
    console.log('\nChild TestTokenProxified contract deployed');
    ChildTokenProxy childTestTokenProxy = ChildTokenProxy(payable(deployCode("out/ChildTokenProxy.sol/ChildTokenProxy.json", abi.encode(address(childTestTokenProxified)))));
    console.log('Child TestToken proxy contract deployed');
    ChildERC20Proxified childTestToken = ChildERC20Proxified(address(childTestTokenProxy));

    childTestToken.initialize(maticWethAddress, 'Test Token', 'TST', 18);
    console.log('Child TestToken contract initialized');
    childTestToken.changeChildChain(address(childChain));
    console.log('Child TestToken child chain updated');
    childChain.mapToken(maticWethAddress, address(childTestToken), false);
    console.log('Root and child TestToken contracts mapped');

    // Same thing for TestERC721.
    ChildERC721Proxified childTestERC721Proxified = ChildERC721Proxified(payable(deployCode("out/ChildERC721Proxified.sol/ChildERC721Proxified.json")));
    console.log('\nChild TestERC721Proxified contract deployed');
    ChildTokenProxy childTestERC721Proxy = ChildTokenProxy(payable(deployCode("out/ChildTokenProxy.sol/ChildTokenProxy.json", abi.encode(address(childTestERC721Proxified)))));
    console.log('Child TestERC721 proxy contract deployed');
    ChildERC721Proxified childTestERC721 = ChildERC721Proxified(payable(address(childTestTokenProxy)));

    childTestERC721.initialize(maticWethAddress, 'Test ERC721', 'TST721');
    console.log('Child TestERC721 contract initialized');
    childTestERC721.changeChildChain(address(childChain));
    console.log('Child TestERC721 child chain updated');
    childChain.mapToken(maticWethAddress, address(childTestERC721), true);
    console.log('Root and child testERC721 contracts mapped');




    vm.stopBroadcast();
  }
}
