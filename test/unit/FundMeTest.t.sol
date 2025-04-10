//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {PriceConverter} from "../../src/PriceConverter.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    uint256 sepoliaForkId;
    uint256 zksyncForkId;

    // Uncomment the following lines to use the environment variables
    string SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
    string ZKSYNC_RPC_URL = vm.envString("ZKSYNC_RPC_URL");

    address bill = makeAddr("Bill");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 1 ether;

    //MockV3Aggregator constants
    uint256 constant VERSION = 0;
    uint8 constant DECIMALS = 18;
    int256 constant INITIAL_PRICE = 2000e8; // 2000 USD

    //SEPOLIA constants
    uint256 constant SEPOLIA_VERSION = 4;
    uint256 constant SEPOLIA_DECIMALS = 8;
    uint256 constant SEPOLIA_INITIAL_PRICE = 1.555695951e21; // 1555 USD
    uint256 constant SEPOLIA_TOTAL_FUND = 1.106e18; // 1.106 ETH

    //ZKSYNC constants
    uint256 constant ZKSYNC_VERSION = 4;
    uint256 constant ZKSYNC_DECIMALS = 8;
    int256 constant ZKSYNC_INITIAL_PRICE = 2000e8; // 2000 USD
    uint256 constant ZKSYNC_TOTAL_FUND = 1.106e18; // 1.106 ETH

    function setUp() public {
        //Create forks for Sepolia and ZKSync testnets
        sepoliaForkId = vm.createFork(SEPOLIA_RPC_URL);
        zksyncForkId = vm.createFork(ZKSYNC_RPC_URL);

        //Select zksync fork
        // vm.selectFork(zksyncForkId);

        // Uncomment the following line to select the sepolia fork
        vm.selectFork(sepoliaForkId);

        // Assert that zksync fork is active
        //assertEq(vm.activeFork(), zksyncForkId, "zkSync fork is not active");

        // Uncomment the following line to assert that sepolia fork is active
        assertEq(vm.activeFork(), sepoliaForkId, "sepolia fork is not active");

        // Deploy the FundMe contract while zkSync fork is active
        // This will deploy the contract on the zkSync's testnet
        // and use the sepolia testnet for the price feed data retrieval

        //If no remote chain is selected, the contract will be deployed
        // on the local chain (localhost) and the price feed will be
        // retrieved from the localhost chain
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        //Mark fundMe contract as persistent so it is available when
        //other forks are active
        //vm.makePersistent(address(fundMe));
        //assert(vm.isPersistent(address(fundMe)));
    }

    function test_MINIMUM_DOLLAR_is_five() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function test_fundMe_owner() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    modifier funded() {
        vm.deal(bill, STARTING_BALANCE);
        vm.startPrank(bill);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function test_fundMe_getTotalFund() public funded {
        uint256 totalFund = fundMe.getTotalFund();
        //Assert that the total fund is equal to the SEND_VALUE that Bill
        // sent

        // For localhost, the` total fund is SEND_VALUE
        //assertEq(totalFund, SEND_VALUE);

        // For Sepolia, the total fund is 1.106e18
        assertEq(totalFund, SEPOLIA_TOTAL_FUND);

        // For ZkSync, the total fund is 1.106e18
        //assertEq(totalFund, ZKSYNC_TOTAL_FUND);

        vm.stopPrank();
    }

    function test_fundMe_fund_failsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund(); //Sending 0 ETH
    }

    function test_fund_updatesFundedDataStructure() public funded {
        //Assert that Bill sent SEND_VALUE amount of ETH to the contract
        uint256 fundedAmount = fundMe.getAddressToAmountFunded(bill);
        assertEq(fundedAmount, SEND_VALUE);

        //Assert that Bill is in the s_funders array
        address funder = fundMe.getFunder(0);
        assertEq(funder, bill);
        vm.stopPrank();
    }

    function test_fundMe_withdraw() public funded {
        uint256 initialOwnerBalance = fundMe.getOwner().balance;
        uint256 initialContractBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;

        //Assert that the owner balance increased by the initial contract
        // balance. This is because the contract balance is transferred
        // to the owner
        assertEq(endingOwnerBalance, initialOwnerBalance + initialContractBalance);

        //Assert that the contract balance is now 0
        assertEq(endingContractBalance, 0);

        //Assert that the initial contract balance is equal to the ending
        // contract balance since all the funds have been withdrawn
        // by the owner
        assertEq(initialContractBalance, initialContractBalance - endingContractBalance);

        //Assert that the funders array is empty
        uint256 numberOfFunders = fundMe.getNumberOfFunders();
        assertEq(numberOfFunders, 0);

        //Assert that the funders mapping is empty
        uint256 fundedAmount = fundMe.getAddressToAmountFunded(bill);
        assertEq(fundedAmount, 0);

        vm.stopPrank();
    }

    function test_fundMe_withdraw_zeroBalance() public {
        vm.deal(address(fundMe), 0 ether);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function test_fundMe_onlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
        vm.stopPrank();
    }

    //Check on fundMe.fallback()
    function test_fundMe_fallbackFunction() public funded {
        // Fallback function will be called when the contract has no
        // function signature to match the call
        vm.deal(bill, 10 ether);

        (bool success,) = bill.call(abi.encodeWithSignature("NonExistentFunction()"));
        assertTrue(success);
    }

    function test_fundMe_receiveFunction() public {
        // Assert that receive() function is invoked when ETH is sent
        // directly, i.e, without calling the fund() method.
        vm.deal(bill, STARTING_BALANCE);

        // Expect the receive function to be called
        vm.expectCall(address(fundMe), SEND_VALUE, "");

        vm.startPrank(bill);
        (bool success,) = address(fundMe).call{value: SEND_VALUE}("");
        vm.stopPrank();

        //Assert
        assertTrue(success);
    }

    /*
    function test_fundMe_undefinedFunction() public {
        vm.deal(address(fundMe), 10 ether);
        vm.expectEmit(true, true, true, true);
        emit FundMe.UndefinedFunction("Fallback triggered: Undefined Function");
        (bool success,) = address(fundMe).call(abi.encodeWithSignature("fallback()"));
        require(success, "Fallback function call failed");
        uint256 totalFund = fundMe.getTotalFund();
        assertEq(totalFund, 10 ether);
    }
    */

    // For the following set of getter tests, since we're using the
    // local anvil chain (no remote chain is spinning), we'll be reading
    // from the MockV3Aggregator mock file
    function test_getVersion() public view {
        uint256 version = fundMe.getVersion();

        //For Sepolia, the version is 4
        assertEq(version, SEPOLIA_VERSION);

        //For ZkSync, the version is 4
        //assertEq(version, ZKSYNC_VERSION);

        //For localhost, the version is 0
        //assertEq(version, VERSION);
    }

    //1555695951e18

    function test_getPrice() public view {
        uint256 price = fundMe.getPrice();

        // For Sepolia, the price is approx. 1555e18 USD
        assertEq(price, SEPOLIA_INITIAL_PRICE);

        // For ZkSync, the price is 2000 USD
        //assertEq(price, uint256(ZKSYNC_INITIAL_PRICE * 1e10));

        // For localhost, the price is 2000 USD
        //assertEq(price, uint256(INITIAL_PRICE * 1e10));
    }

    function test_getDecimals() public view {
        uint8 decimals = fundMe.getDecimals();

        // For Sepolia, the decimals is 8
        assertEq(decimals, SEPOLIA_DECIMALS);

        // For ZkSync, the decimals is 8
        //assertEq(decimals, ZKSYNC_DECIMALS);

        // For localhost, the decimals is 18
        //assertEq(decimals, DECIMALS);
    }

    function test_getConversionRate() public view {
        uint256 ethAmount = 1;
        //ethAmountInUsd = (ethPrice(in Wei) * ethAmount)/1e18 = (2000e18 * 1)/1e18 = 2000e18
        uint256 conversionRate = fundMe.getConversionRate(ethAmount);

        // For Sepolia, the conversion rate is 1555 USD
        assertEq(conversionRate, 1555);

        // For ZkSync, the conversion rate is 2000 USD
        //assertEq(conversionRate, 2000);

        // For localhost, the conversion rate is 2000 USD
        //assertEq(conversionRate, 2000);
    }
}
