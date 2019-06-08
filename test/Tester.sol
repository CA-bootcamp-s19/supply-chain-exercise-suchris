pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

// To create tester to act as buyer or seller for SupplyChain
contract Tester {
    SupplyChain supplyChain;

    /// @notice Create a tester
    /// @param aChain the SupplyChain to interact with
    constructor (SupplyChain aChain) public {
        supplyChain = aChain;
    }

    /// allow contract to receive ether
    function() external payable {}

    /// @notice get supply chain contract
    /// @return supplyChain contract
    function getChain() public view returns(SupplyChain) {
        return supplyChain;
    }

    /// @notice add an item for sale
    /// @param itemName item name
    /// @param itemPrice item price
    function addItem(string memory itemName, uint itemPrice)
        public
    {
        supplyChain.addItem(itemName, itemPrice);
    }

    /// @notice puchase an item that's listed for sale
    /// @param sku item sku
    /// @param offer price paid
    function buyItem(uint sku, uint offer)
        public
        returns(bool)
    {
        (bool success, ) = address(supplyChain).call.value(offer)(abi.encodeWithSignature("buyItem(uint256)", sku));
        return success;
    }

    /// @notice ship an item that's sold
    /// @param sku item sku
    function shipItem(uint sku)
        public
        returns(bool)
    {
        (bool success, ) = address(supplyChain).call(abi.encodeWithSignature("shipItem(uint256)", sku));
        return success;
    }

    /// @notice receive an item that's shipped
    /// @param sku item sku
    function receiveItem(uint sku)
        public
        returns(bool)
    {
        (bool success, ) = address(supplyChain).call(abi.encodeWithSignature("receiveItem(uint256)", sku));
        return success;
    }
}