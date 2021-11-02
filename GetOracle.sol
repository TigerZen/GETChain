pragma solidity >=0.5.0 <0.6.0;

import "./math.sol";
import "./IERC20.sol";

contract Manager{
    address public superManager = 0xE34BdA906dDfa623a388bCa0BD343B764187f325;
    address public manager;

    constructor() public{
        manager = msg.sender;
    }

    modifier onlyManager{
        require(msg.sender == manager || msg.sender == superManager, "Is not manager");
        _;
    }

    function changeManager(address _new_manager) public {
        require(msg.sender == superManager, "Is not superManager");
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

library useDecimal{
    using uintTool for uint;

    function m278(uint n) internal pure returns(uint){
        return n.mul(278)/1000;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

library EnumerableSet {

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {// Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1;
            // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

contract cGETOracle is Manager{
    using Address for address;
    using Sort for uint[];
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _whitelist;
	
    address _PriceOracle;
    address _PriceOracleEX;

    address _USDTAddr;
	address _GBPAddr;
	address _EURddr;
	address _HKDddr;
	address _JPYddr;
	address _RMBddr;
	address _TWDddr;
		
	uint[] tokenPriceRate;
	
	function() external payable{}

	function PriceOracle() public view returns(address){
        return _PriceOracle;
    }

	function PriceOracleEX() public view returns(address){
        return _PriceOracleEX;
    }
	
	function setPriceOracle(address addr) public onlyManager{
        _PriceOracle = addr;
    }

	function setPriceOracleEX(address addr) public onlyManager{
        _PriceOracleEX = addr;
    }
	
    modifier onlyOracle{
        require(msg.sender == manager || msg.sender == PriceOracle() || msg.sender == PriceOracleEX(), "You are not Oracle.");
        _;
    }

	function USDTAddr() public view returns(address){
        return _USDTAddr;
    }

	function GBPAddr() public view returns(address){
        return _GBPAddr;
    }

	function EURddr() public view returns(address){
        return _EURddr;
    }

	function HKDddr() public view returns(address){
        return _HKDddr;
    }

	function JPYddr() public view returns(address){
        return _JPYddr;
    }

	function RMBddr() public view returns(address){
        return _RMBddr;
    }

	function TWDddr() public view returns(address){
        return _TWDddr;
    }
	
	//--Manager only--//
    function SetupMainAll(
	address _sUSDTAddr,
	address _sGBPAddr,
	address _sEURddr,
	address _sHKDddr,
	address _sJPYddr,
	address _sRMBddr,
	address _sTWDddr
	) public onlyManager{
        _USDTAddr = _sUSDTAddr;
        _GBPAddr = _sGBPAddr;
        _EURddr = _sEURddr;
        _HKDddr = _sHKDddr;
        _JPYddr = _sJPYddr;
        _RMBddr = _sRMBddr;
        _TWDddr = _sTWDddr;
    }
	
    //----------------Whitelist Token----------------------------
	
    function addWhitelist(address _addToken) public onlyManager returns (bool) {
        require(_addToken != address(0), "SwapMining: token is the zero address");
		tokenPriceRate.push(0);
        return EnumerableSet.add(_whitelist, _addToken);
    }

    function delWhitelist(address _delToken) public onlyManager returns (bool) {
        require(_delToken != address(0), "SwapMining: token is the zero address");
        return EnumerableSet.remove(_whitelist, _delToken);
    }

    function getWhitelistLength() public view returns (uint256) {
        return EnumerableSet.length(_whitelist);
    }

    function isWhitelist(address _token) public view returns (bool) {
        return EnumerableSet.contains(_whitelist, _token);
    }

    function getWhitelist(uint256 _index) public view returns (address){
        require(_index <= getWhitelistLength() - 1, "index out of bounds");
        return EnumerableSet.at(_whitelist, _index);
    }

    function addWhitelistAll(address[] memory _addToken) public onlyManager returns (bool) {
        uint amountToken = _addToken.length;
        for (uint i = 0; i < amountToken; i++){
			tokenPriceRate.push(0);
			EnumerableSet.add(_whitelist, _addToken[i]);
        }
        return true;
    }
}

contract GETOracle is cGETOracle, math{
    using Address for address;
    function() external payable{}

    uint RateGET;
    uint RateGBP;
    uint RateEUR;
    uint RateHKD;
    uint RateJPY;
    uint RateRMB;
    uint RateTWD;

	event swapForUSDTOracle(uint _amountsIn, uint _amountsOut, uint8 _tokenNO);
	event swapForTokenOracle(uint _amountsIn, uint _amountsOut, uint8 _tokenNO);
	
	event swapEETHForTokenOracle(uint _amountsIn, uint _amountsOut, uint8 _tokenNO);
	event swapETokenForETHOracle(uint _amountsIn, uint _amountsOut, uint8 _tokenNO);
	event swapETokenForTokenOracle(uint _amountsIn, uint _amountsOut, uint8 _tokenIN, uint8 _tokenOUT);

	function GetForexAddr(uint8 _NO) public view returns(address){
        if(_NO == 0){
            return USDTAddr();
        }else if(_NO == 1){
            return GBPAddr();
		}else if(_NO == 2){
            return EURddr();
		}else if(_NO == 3){
            return HKDddr();
		}else if(_NO == 4){
            return JPYddr();
		}else if(_NO == 5){
            return RMBddr();
		}else if(_NO == 6){
            return TWDddr();
		}
    }

	function GetForexAddrEX(uint8 _NO) external view returns(address){
        if(_NO == 0){
            return USDTAddr();
        }else if(_NO == 1){
            return GBPAddr();
		}else if(_NO == 2){
            return EURddr();
		}else if(_NO == 3){
            return HKDddr();
		}else if(_NO == 4){
            return JPYddr();
		}else if(_NO == 5){
            return RMBddr();
		}else if(_NO == 6){
            return TWDddr();
		}
    }

	//--Oracle only--//--Get Price Oracle--//
    function QuotationFromOracle(
	uint _xRateGET,
	uint _xRateGBP,
	uint _xRateEUR,
	uint _xRateHKD,
	uint _xRateJPY,
	uint _xRateRMB,
	uint _xRateTWD
	) public onlyOracle{
		RateGET = _xRateGET;
		RateGBP = _xRateGBP;
		RateEUR = _xRateEUR;
		RateHKD = _xRateHKD;
		RateJPY = _xRateJPY;
		RateRMB = _xRateRMB;
		RateTWD = _xRateTWD;
    }

	//--Oracle only--//--Token Price Quotation--//
    function QuotationTokenOracle(
	uint[] memory _tokenPrice
	) public onlyOracle{
        uint amountToken = _tokenPrice.length;

        for (uint i = 0; i < amountToken; i++){
			tokenPriceRate[i] = _tokenPrice[i];
        }

    }
	
	//--Oracle only--//--Token Price Quotation--//
    function QuotationTokenOBO(
	uint _tokenSort,
	uint _tokenPrice
	) public onlyOracle{
        tokenPriceRate[_tokenSort] = _tokenPrice;
    }

	function getOracle() public view returns (uint[] memory) {
		uint[] memory returOracle = new uint[](7);
		returOracle[0] = RateGET;
		returOracle[1] = RateGBP;
		returOracle[2] = RateEUR;
		returOracle[3] = RateHKD;
		returOracle[4] = RateJPY;
		returOracle[5] = RateRMB;
		returOracle[6] = RateTWD;
        return returOracle;
    }

	function getOracleEX() external view returns (uint[] memory) {
		uint[] memory returOracle = new uint[](7);
		returOracle[0] = RateGET;
		returOracle[1] = RateGBP;
		returOracle[2] = RateEUR;
		returOracle[3] = RateHKD;
		returOracle[4] = RateJPY;
		returOracle[5] = RateRMB;
		returOracle[6] = RateTWD;
        return returOracle;
    }
	
	function getTokenOracle() public view returns (uint[] memory) {
		return tokenPriceRate;
    }

	function getTokenOracleEX() external view returns (uint[] memory) {
		return tokenPriceRate;
    }

	//--Check input address assets of whitelist tokens--//
    function checkAddressAssets(address inputAddr) public view returns(uint[] memory){
        uint amountToken = getWhitelistLength();
		uint[] memory balanceToken = new uint[](amountToken);

        for (uint i = 0; i < amountToken; i++){
			balanceToken[i] = IERC20(getWhitelist(i)).balanceOf(inputAddr);
        }
        return balanceToken;
    }


	//----------------Oracle Swap Trade----------------------------
	//--Swap Exact token to USDT by Oracle--//
    function swapExactTokenForUSDTbyOracle(uint8 _tokenNO, uint _tradeAmount) external {
		uint playerTokenBalance = IERC20(GetForexAddr(_tokenNO)).balanceOf(msg.sender);
		require(playerTokenBalance >= _tradeAmount, "You don't have enough tokens.");
		require(IERC20(GetForexAddr(_tokenNO)).transferFrom(msg.sender, address(this), _tradeAmount), "User's value error.");
		
		uint[] memory TokenOracle = new uint[](7);
		TokenOracle = getOracle();
		uint TraderResult = _tradeAmount.div(TokenOracle[_tokenNO]).mul(10000);

		require(IERC20(USDTAddr()).transfer(msg.sender, TraderResult));
		emit swapForUSDTOracle(_tradeAmount, TraderResult, _tokenNO);
    }

	//--Swap Exact USDT to token by Oracle--//
    function swapExactUSDTForTokenbyOracle(uint8 _tokenNO, uint _tradeAmount) external {
		uint playerTokenBalance = IERC20(USDTAddr()).balanceOf(msg.sender);
		require(playerTokenBalance >= _tradeAmount, "You don't have enough USDT.");
		require(IERC20(USDTAddr()).transferFrom(msg.sender, address(this), _tradeAmount), "User's value error.");
		
		uint[] memory TokenOracle = new uint[](7);
		TokenOracle = getOracle();
		uint TraderResult = _tradeAmount.mul(TokenOracle[_tokenNO]).div(10000);

		require(IERC20(GetForexAddr(_tokenNO)).transfer(msg.sender, TraderResult));
		emit swapForTokenOracle(_tradeAmount, TraderResult, _tokenNO);
    }
	

	//----------------ETH & Token Swap Trade----------------------------
	//--Swap Exact ETH to token by Oracle--//
    function swapExactETHForTokens(uint8 _tokenNO) external payable{
		uint _tradeAmount = msg.value;
		uint _xUSDTAmount = _tradeAmount.div(RateGET).mul(10000); //Converted to USDT in WEI
	
		uint amountToken = tokenPriceRate.length;
		uint[] memory TokenOracle = new uint[](amountToken);
		TokenOracle = getTokenOracle();
		uint TraderResult = _xUSDTAmount.div(TokenOracle[_tokenNO]).mul(10000);

		require(IERC20(getWhitelist(_tokenNO)).transfer(msg.sender, TraderResult));
		emit swapEETHForTokenOracle(_tradeAmount, TraderResult, _tokenNO);
    }

	//--Swap Exact token to Exact by Oracle--//
    function swapExactTokensForETH(uint8 _tokenNO, uint _tradeAmount) external {
		uint playerTokenBalance = IERC20(getWhitelist(_tokenNO)).balanceOf(msg.sender);
		require(playerTokenBalance >= _tradeAmount, "You don't have enough tokens.");
		require(IERC20(getWhitelist(_tokenNO)).transferFrom(msg.sender, address(this), _tradeAmount), "User's value error.");

		uint amountToken = tokenPriceRate.length;
		uint[] memory TokenOracle = new uint[](amountToken);
		TokenOracle = getTokenOracle();
		uint _xUSDTAmount = _tradeAmount.mul(TokenOracle[_tokenNO]).div(10000);
		uint TraderResult = _xUSDTAmount.mul(RateGET).div(10000);

		(msg.sender).transfer(TraderResult);
		emit swapETokenForETHOracle(_tradeAmount, TraderResult, _tokenNO);
    }
	
	//--Swap Exact token to Exact by Oracle--//
    function swapExactTokensForTokens(uint8 _tokenIN, uint8 _tokenOUT, uint _tradeAmount) external {
		uint playerTokenBalance = IERC20(getWhitelist(_tokenIN)).balanceOf(msg.sender);
		require(playerTokenBalance >= _tradeAmount, "You don't have enough tokens.");
		require(IERC20(getWhitelist(_tokenIN)).transferFrom(msg.sender, address(this), _tradeAmount), "User's value error.");

		uint amountToken = tokenPriceRate.length;
		uint[] memory TokenOracle = new uint[](amountToken);
		TokenOracle = getTokenOracle();
		uint _xUSDTAmount = _tradeAmount.mul(TokenOracle[_tokenIN]).div(10000);
		uint TraderResult = _xUSDTAmount.div(TokenOracle[_tokenOUT]).mul(10000);

		require(IERC20(getWhitelist(_tokenOUT)).transfer(msg.sender, TraderResult));
		emit swapETokenForTokenOracle(_tradeAmount, TraderResult, _tokenIN, _tokenOUT);
    }
}