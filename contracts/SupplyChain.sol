pragma solidity ^0.5.0;

contract SupplyChain {

  // owner of contract
  address owner;

  // use sku count to set sku for item mapping
  uint skuCount;

  // mapping to a sku to an item
  mapping (uint => Item) public items;

  // there are 4 states for an item: for sale, sold, shipped, and received
  enum State {ForSale, Sold, Shipped, Received}

  // item contains a name, sku, price, state, seller and buyer
  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  // log an item is listed for sale
  event LogForSale (uint sku);

  // log an item is sold
  event LogSold (uint sku);

  // log an item is shipped
  event LogShipped (uint sku);

  // log an item is received
  event LogReceived (uint sku);

  // check if msg.sender is the address specified
  modifier verifyCaller (address _address) {
    require (
      msg.sender == _address,
      "Caller is not owner"
    );
    _;
  }

  // check if buyer has enough funds
  modifier hasEnoughFunds(uint _price) {
    require(
      msg.value >= _price,
      "Not enough paid"
    );
    _;
  }

  // refund excess payment paid by buyer after purchase
  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  // modifier to check an item listed is for sale
  modifier forSale (uint _sku) {
    require (
      items[_sku].state == State.ForSale &&
      items[_sku].seller != address(0),
      "Expected to be Forsale"
    );
    _;
  }

  // check an item is sold
  modifier sold (uint _sku) {
    require (
      items[_sku].state == State.Sold,
      "Expected to be Sold"
    );
    _;
  }

  // check an item is shipped
  modifier shipped (uint _sku) {
    require (
      items[_sku].state == State.Shipped,
      "Expected to be Shipped"
    );
    _;
  }

  // check an item is received
  modifier received (uint _sku) {
    require (
      items[_sku].state == State.Received,
      "Expected to be Received"
    );
    _;
  }

  // constructor to instantiate the contract
  constructor() public {
    owner = msg.sender; // owner is set to caller
    skuCount = 0;       // skuCount is set to 0
  }

  /// @notice addItem adds an item to a list of items
  ///         and set state to for sale and seller to caller of the function
  /// @param  _name is the name of the item
  /// @param  _price is the price of the item
  /// @return an item is added
  function addItem(string memory _name, uint _price) public returns(bool){
    emit LogForSale(skuCount);
    items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: address(0)});
    skuCount = skuCount + 1;
    return true;
  }

  /// @notice buy an item, caller transfer value to purchase an item
  ///         function checks if the item is listed for sale and if buyer paid enough
  ///         and refunds excess payment back to caller
  /// @param sku sku of an item
  /// @dev emits event LogSold
  function buyItem(uint sku)
    public
    payable
    forSale(sku)
    hasEnoughFunds(items[sku].price)
    checkValue(sku)
  {
    items[sku].buyer = msg.sender;
    items[sku].state = State.Sold;
    items[sku].seller.transfer(items[sku].price);
    emit LogSold(sku);
  }

  /// @notice ship an item, funciton checks state of the item is sold and caller is the seller
  /// @param sku sku of an item
  /// @dev emits event LogShipped
  function shipItem(uint sku)
    public
    sold(sku)
    verifyCaller(items[sku].seller)
  {
   items[sku].state = State.Shipped;
   emit LogShipped(sku);
  }

  /// @notice receive an item, function checks state of item is shipped and verify caller is buyer
  /// @param sku sku of an item
  /// @dev emits event LogReceived
  function receiveItem(uint sku)
    public
    shipped(sku)
    verifyCaller(items[sku].buyer)
  {
    items[sku].state = State.Received;
    emit LogReceived(sku);
  }

  /// @notice fetch parameters of an item
  /// @param sku sku of an item
  /// @return item name, sku, price, state, seller and buyer
  function fetchItem(uint _sku) public view returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }

}
