// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./FamilySavings.t.sol";

contract SettingRatesTest is FamilySavingsTest {
    address[] public addressArray1;
    address[] public addressArray2;
    uint256[] public uint256Array;

    function testSetCollateralRate() public {
        uint rate = 10;

        targets = [address(familySavings)];
        values = [0];
        calldatas = [
            abi.encodeWithSignature(
                "setCollateralRate(address,address,uint256)",
                address(token0),
                address(token1),
                rate
            )
        ];
        description = "Set Collateral Rate";

        assertEq(
            familySavings.collateralRates(address(token0), address(token1)),
            0
        );

        _proposeAndExecute();

        assertEq(
            familySavings.collateralRates(address(token0), address(token1)),
            rate
        );
    }

    function testSetCollateralRateBatched() public {
        addressArray1 = [address(token0), address(token1)];
        addressArray2 = [address(token1), address(token0)];
        uint256Array = [10, 20];

        targets = [address(familySavings)];
        values = [0];
        calldatas = [
            abi.encodeWithSignature(
                "setCollateralRateBatched(address[],address[],uint256[])",
                addressArray1,
                addressArray2,
                uint256Array
            )
        ];
        description = "Set Collateral Rates";

        assertEq(
            familySavings.collateralRates(addressArray1[0], addressArray2[0]),
            0
        );
        assertEq(
            familySavings.collateralRates(addressArray1[1], addressArray2[1]),
            0
        );

        _proposeAndExecute();

        assertEq(
            familySavings.collateralRates(addressArray1[0], addressArray2[0]),
            uint256Array[0]
        );
        assertEq(
            familySavings.collateralRates(addressArray1[1], addressArray2[1]),
            uint256Array[1]
        );
    }

    function testSetAnnualLendingRate() public {
        uint rate = 10;

        targets = [address(familySavings)];
        values = [0];
        calldatas = [
            abi.encodeWithSignature(
                "setAnnualLendingRate(address,uint256)",
                address(token0),
                rate
            )
        ];
        description = "Set Annual Lending Rate";

        assertEq(familySavings.annualLendingRates(address(token0)), 0);

        _proposeAndExecute();

        assertEq(familySavings.annualLendingRates(address(token0)), rate);
    }

    function testSetAnnualLendingRatesBatched() public {
        addressArray1 = [address(token0), address(token1)];
        uint256Array = [10, 20];

        targets = [address(familySavings)];
        values = [0];
        calldatas = [
            abi.encodeWithSignature(
                "setAnnualLendingRateBatched(address[],uint256[])",
                addressArray1,
                uint256Array
            )
        ];
        description = "Set Annual Lending Rates";

        assertEq(familySavings.annualLendingRates(addressArray1[0]), 0);
        assertEq(familySavings.annualLendingRates(addressArray1[1]), 0);

        _proposeAndExecute();

        assertEq(
            familySavings.annualLendingRates(addressArray1[0]),
            uint256Array[0]
        );
        assertEq(
            familySavings.annualLendingRates(addressArray1[1]),
            uint256Array[1]
        );
    }
}
