//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";

// Using custom error types saves gas as compared to using require statement with the
// optional string argument set
error FundMe__NotOwner();
error FundMe__ZeroBalance();

contract FundMe {
    //Attach PriceConverter library to all uint256 variables
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    address private immutable i_owner;
    AggregatorV2V3Interface private immutable s_priceFeed;

    event UndefinedFunction(string description);

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        //Set the price feed address
        s_priceFeed = AggregatorV2V3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external {
        emit UndefinedFunction("Fallback triggered: Undefined Function");
        fund();
    }

    // Views/getter functions to return values from storage variables
    //These functions are free to call and do not cost any gas
    //They are not modifying the state of the contract
    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getNumberOfFunders() external view returns (uint256) {
        return s_funders.length;
    }

    function getAddressToAmountFunded(address funder) external view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    //Allow users to send $ to this contract
    function fund() public payable {
        //Allow users to send $
        //Set the minimum amount a user can send to $5
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough amount of ETH for fund(minimum amount is $5)"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    modifier checkZeroBalance() {
        // require (address(this).balance > 0, "Contract doesn't have
        // any funds yet");
        if (address(this).balance <= 0) {
            revert FundMe__ZeroBalance();
        }
        _;
    }

    //Owner of this contract or account should be able to withdraw the $
    function withdraw() public onlyOwner {
        //Reset the funders address to show that you've withdrawn the funds
        uint256 fundersLength = s_funders.length;
        for (uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        //Reset the funders array to show you withdrew all funds
        s_funders = new address[](0);

        //Send $ amount to owner of this contract
        (bool sendSuccessful,) = payable(msg.sender).call{value: address(this).balance}("");
        require(sendSuccessful, "Failed to withdraw money");
    }

    function getTotalFund() public view checkZeroBalance returns (uint256) {
        //Get the total funds available in this contract
        return (address(this).balance);
    }

    function getDecimals() public view returns (uint8) {
        return PriceConverter.getDecimals(s_priceFeed);
    }

    function getPrice() public view returns (uint256) {
        return PriceConverter.getPrice(s_priceFeed);
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        return PriceConverter.getConversionRate(ethAmount, s_priceFeed);
    }

    function getVersion() public view returns (uint256) {
        return PriceConverter.getVersion(s_priceFeed);
    }
}
