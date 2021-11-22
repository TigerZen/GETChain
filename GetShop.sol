pragma solidity >=0.5.0 <0.6.0;

import "./ERC721.sol";

contract Manager{
    address public superManager = 0xE34BdA906dDfa623a388bCa0BD343B764187f325;
    address public manager;

    constructor() public{
        manager = msg.sender;
    }

    modifier onlyManager{
        require(msg.sender == manager || msg.sender == superManager, "It's not manager");
        _;
    }

    function changeManager(address _new_manager) public {
        require(msg.sender == superManager, "It's not superManager");
        manager = _new_manager;
    }

    function withdraw() external onlyManager{
        (msg.sender).transfer(address(this).balance);
    }

    function withdrawfrom(uint amount) external onlyManager{
	    require(address(this).balance >= amount, "Insufficient balance");
        (msg.sender).transfer(amount);
    }

    function takeTokensToManager(address tokenAddr) external onlyManager{
        uint _thisTokenBalance = IERC20(tokenAddr).balanceOf(address(this));
        require(IERC20(tokenAddr).transfer(msg.sender, _thisTokenBalance));
    }

	function destroy() external onlyManager{ 
        selfdestruct(msg.sender); 
	}
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ISwap{
    function getOracle() external view returns (uint[] memory);
}

library GetShop {

    struct ShopOrder{
        OrderData orderData;
    }
	
    struct OrderData{
        uint itemID;
        uint oderID;
        uint oderTime;
        uint oderStatus;
		uint oderPrice;
    }

    function set_orderData(ShopOrder storage s, OrderData memory orderData) internal{
        s.orderData = orderData;
    }
}

/*====================================================================================
                           GetShop Order Contract
====================================================================================*/

contract GetShopOrder is Manager, ERC721{
    using GetShop for GetShop.ShopOrder;
    using GetShop for GetShop.OrderData;

    mapping (uint => GetShop.ShopOrder) orders;
    using Address for address;
    uint totalodersId;
    string _name;
    string _symbol;
    uint256 public _totalSupply;

    address _PriceOracle = 0xcbC886a48686A6b0A8Af922Be3CE5E2b8E1B856f;
    address _UsdtAddr = 0x800F4262Fbda878989c74e95381ee63Ce0DE7aD3;
	address _secretary = 0x7A32670e8e26E77f1e7ab9A009691165C850fc6e;
    
    constructor() public {
        totalodersId = 1;
		_totalSupply = 0;
        _ownedTokensCount[address(this)].setBalance(_totalSupply);
        _name = "GetShop Order NFT";
        _symbol = "GSNFT";
    }
	
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    modifier onlyOderOwner(uint orderId){
        require(ownerOf(orderId) == msg.sender, "You are not owner of Order.");
        _;
    }

	function PriceOracle() public view returns(address){
        return _PriceOracle;
    }
	
	function setPriceOracle(address addr) public onlyManager{
        _PriceOracle = addr;
    }

	function UsdtAddr() public view returns(address){
        return _UsdtAddr;
    }
	
	function setUsdtAddr(address addr) public onlyManager{
        _UsdtAddr = addr;
    }

	function Secretary() public view returns(address){
        return _secretary;
    }
	
	function setSecretary(address addr) public onlyManager{
        _secretary = addr;
    }

    modifier onlySecretary{
        require(msg.sender == manager || msg.sender == Secretary(), "You are not Secretary or manager.");
        _;
    }

    event createOrderResult(uint _ItemId, uint _OderID, uint _OderTime, uint _OderStatus, uint _OderPrice);

////////////////////////////////inquire//////////////////////////////////
    function orderData(uint orderId) private view returns(GetShop.OrderData memory){
        return orders[orderId].orderData;
    }

    function inqOrderData(uint orderId) external view returns
    (uint itemID, uint oderID, uint oderTime, uint oderStatus, uint oderPrice){
        GetShop.OrderData memory od = orderData(orderId);
        return (od.itemID, od.oderID, od.oderTime, od.oderStatus, od.oderPrice);
    }

    function exist(uint orderId) public view returns(bool){
        return ownerOf(orderId) != address(0);
    }
	
	//--Calculate GETToken buy price in Oracle by GET value--//
    function inqGETTokenBuyPrice() public view returns(
        uint _tokenPrice){

		uint amountsOut = 1*10**18;
		uint[] memory _amountsINToken = new uint[](7);
		_amountsINToken = ISwap(PriceOracle()).getOracle();
		uint _xtokenPrice = amountsOut.div(_amountsINToken[0]).mul(10000);
		
        return _xtokenPrice;
    }
	
// ///////////////////////////other function///////////////////////////////

	//--Create Order By GET--//
    function createOrder(uint _itemID) public payable{
		uint GETPrice = inqGETTokenBuyPrice();
		uint amountsOut = 1*10**18;
		uint itemPrice = msg.value.div(amountsOut).mul(GETPrice);

        GetShop.OrderData memory od = GetShop.OrderData(
            _itemID,
            totalodersId,
            now,
            0,
			itemPrice
            );
		_generateOrder(od, msg.sender);
    }

	//--Create Order By Exact USDT--//
    function createOrderUSDT(uint _itemID, uint _tradeAmount) external {
		uint playerTokenBalance = IERC20(UsdtAddr()).balanceOf(msg.sender);
		require(playerTokenBalance >= _tradeAmount, "You don't have enough USDT.");
		require(IERC20(UsdtAddr()).transferFrom(msg.sender, address(this), _tradeAmount), "User's value error.");
		
        GetShop.OrderData memory od = GetShop.OrderData(
            _itemID,
            totalodersId,
            now,
            0,
			_tradeAmount
            );
		_generateOrder(od, msg.sender);
    }
	
	//--Create Order By Manager--//
    function createOrderManager(uint _itemID, uint _tradeAmount) external onlySecretary{
        GetShop.OrderData memory od = GetShop.OrderData(
            _itemID,
            totalodersId,
            now,
            0,
			_tradeAmount
            );
		_generateOrder(od, msg.sender);
    }
	
    function _generateOrder(GetShop.OrderData memory orderData, address _nftOwner) private{
        _mint(_nftOwner, totalodersId);
        orders[totalodersId].orderData = orderData;
		emit createOrderResult(orderData.itemID, orderData.oderID, orderData.oderTime, orderData.oderStatus, orderData.oderPrice);
        totalodersId = totalodersId.add(1);
		_totalSupply = _totalSupply.add(1);
    }

    function OrderSetS(uint orderId, uint8 AType, uint Amount) external onlySecretary{
        GetShop.OrderData memory od = orderData(orderId);

        if(AType == 1) {
			od.itemID = Amount;
        }else if(AType == 2){
		    require(Amount > 0, "oderID error!");
		    od.oderID = Amount;
        }else if(AType == 3){
		    require(Amount >= 0, "oderTime error!");
		    od.oderTime = Amount;
        }else if(AType == 4){
		    od.oderStatus = Amount;
        }else if(AType == 5){
		    require(Amount > 0, "oderPrice error!");
		    od.oderPrice = Amount;
        }else{
		    revert("rand error");
        }
		orders[orderId].set_orderData(od);
    }
}