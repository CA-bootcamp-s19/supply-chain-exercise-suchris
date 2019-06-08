pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";
import "./Tester.sol";

contract TestSupplyChain {
    uint public initialBalance = 1 ether;  // start with initial balance

    SupplyChain public supplyChain;        // creat SupplyChain contract to test
    Tester public buyer;                   // create actor buyer to interactive with supplyChain
    Tester public seller;                  // create actor seller to interactive with supplyChain

    uint public price;             // delcare variable item price
    uint public excessAmount;      // declare variable excessAmount above item price
    string public name;            // declare variable name of an item
    uint public sku;               // declare variable sku of an item

    // state of an item, this matches SupplyChain contract's State
    enum State {ForSale, Sold, Shipped, Received}

    /// allow contract to receive payment
    function() external payable {}

    /// @notice truffle runs beforeEach function before each test function
    function beforeEach()
        public
    {
        supplyChain = new SupplyChain();        // instantiate supplyChain
        buyer = new Tester(supplyChain);        // instantiate buyer
        seller = new Tester(supplyChain);       // instantiate seller

        price = 10;             // initialize price to 10
        excessAmount = 2000;    // initialize excessAmount to 2000
        name = "book";          // initialize name to "book"
        sku = 0;                // initialize sku to 0

        seller.addItem(name, price);            // add an item for sale
        address(buyer).transfer(excessAmount);  // tansfer some funds to buyer
    }

    // Test for failing conditions in this contracts
    // test that every modifier is working

    // addItem

    /// @notice test adding an item for sale
    function testAddItem()
        public
    {
        address expectedBuyer = address(0);         // buyer is not assigned when item is added
        address expectedSeller = address(seller);   // seller is assigned when item is added

        string memory _name;
        uint _sku;
        uint _price;
        uint _state;
        address _seller;
        address _buyer;

        ( _name, _sku, _price, _state, _seller, _buyer) = supplyChain.fetchItem(sku);

        // Verify item is listed `ForSale`
        Assert.equal(_sku, sku, "Item sku is correct");
        Assert.equal(_name, name, "Item name is correct");
        Assert.equal(_price, price, "Item price is correct");
        Assert.equal(_state, (uint)(State.ForSale), "Item State is `For sale`");
        Assert.equal(_buyer, expectedBuyer, "Item buyer is 0x0");
        Assert.equal(_seller, expectedSeller, "Item seller is the seller`");
    }

    // buyItem

    /// @notice test for failure if user does not send enough funds
    function testBuyItemWithLessFund()
        public
    {
        address expectedBuyer = address(buyer);
        address expectedSeller = address(seller);

        string memory _name;
        uint _sku;
        uint _price;
        uint _state;
        address _seller;
        address _buyer;

        bool result = buyer.buyItem(sku, price - 1);
        Assert.isFalse(result, "Not able to buy");

        ( _name, _sku, _price, _state, _seller, _buyer) = supplyChain.fetchItem(sku);
        Assert.equal(_state, (uint)(State.ForSale), "Item State doesn't match `For sale`");
        Assert.equal(_buyer, address(0), "Item buyer is not 0x");
    }

    /// @notice test purchasing an item that is not for sale
    function testBuyItemNotForSale() public {
        address expectedBuyer = address(buyer);
        address expectedSeller = address(seller);

        string memory _name;
        uint _sku;
        uint _price;
        uint _state;
        address _seller;
        address _buyer;

        bool result = buyer.buyItem(sku, price + 10);
        Assert.isTrue(result, "buyer.buyItem failed");

        result = seller.buyItem(sku, price);
        Assert.isFalse(result, "Item is not for sale");

        ( _name, _sku, _price, _state, _seller, _buyer) = supplyChain.fetchItem(sku);

        Assert.equal(_state, (uint)(State.Sold), "Item State doesn't match `Sold`");
        Assert.equal(_buyer, expectedBuyer, "Buyer is not the expected buyer");
        Assert.equal(_seller, expectedSeller, "Seller is not the expected seller`");
    }

    // shipItem

    /// @notice test shipping an item that is made by the seller
    function testShipItemByNonSeller() public {
        buyer.buyItem(sku, excessAmount);
        bool result = buyer.shipItem(sku);
        Assert.isFalse(result, "Non seller can't ship an item");
    }

    /// @notice test shipping an item that is not marked sold
    function testShipItemNotSold() public {
        bool result = seller.shipItem(sku);
        Assert.isFalse(result, "Can't ship an item that is not sold");
    }

    // receiveItem

    /// @notice test receiving an item from an address that is not buyer
    function testReceiveItemNonBuyer() public {
        buyer.buyItem(sku, excessAmount);
        seller.shipItem(sku);
        bool result = seller.receiveItem(sku);
        Assert.isFalse(result, "Non buyer can't receive the item");
    }
    /// @notice test receivng an item that is not marked shipped
    function testReceiveItemNotShipped() public {
        buyer.buyItem(sku, excessAmount);
        bool result = buyer.receiveItem(sku);
        Assert.isFalse(result, "Can't receive an item that is not shipped");
    }

}
