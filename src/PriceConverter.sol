//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";

library PriceConverter {
    function getDecimals(AggregatorV2V3Interface priceFeed) internal view returns (uint8) {
        //Get the no. of decimals in the returned value
        return priceFeed.decimals();
    }

    function getPrice(AggregatorV2V3Interface priceFeed) internal view returns (uint256) {
        //Price of ETH in USD.
        (, int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV2V3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function getVersion(AggregatorV2V3Interface priceFeed) internal view returns (uint256) {
        return priceFeed.version();
    }
}
