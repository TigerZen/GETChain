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

interface ISwap{
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
		
	function takerWithdraw() external;
	
	function getPair(address tokenA, address tokenB) external view returns (address pair);
	
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external view returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external view returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external view returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
	
	function factory() external view returns (address);
}

contract cGETOracle is Manager{
    using Address for address;
    address _PriceOracle;

    address _DEXAddr;
    address _ETHAddr;
	address _GETAddr;
    address _USDTAddr;
	address _GBPAddr;
	address _EURddr;
	address _HKDddr;
	address _JPYddr;
	address _RMBddr;
	address _TWDddr;
	
	function() external payable{}

	function PriceOracle() public view returns(address){
        return _PriceOracle;
    }
	
	function setPriceOracle(address addr) public onlyManager{
        _PriceOracle = addr;
    }
	
    modifier onlyOracle{
        require(msg.sender == manager || msg.sender == PriceOracle(), "You are not Oracle.");
        _;
    }
	
	function DEXAddr() public view returns(address){
        return _DEXAddr;
    }
	
	function ETHAddr() public view returns(address){
        return _ETHAddr;
    }
	
	function GETAddr() public view returns(address){
        return _GETAddr;
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
	address _sDEXAddr,
	address _sETHaddr,
	address _sGETAddr,
	address _sUSDTAddr,
	address _sGBPAddr,
	address _sEURddr,
	address _sHKDddr,
	address _sJPYddr,
	address _sRMBddr,
	address _sTWDddr
	) public onlyManager{
        _DEXAddr = _sDEXAddr;
        _ETHAddr = _sETHaddr;
        _GETAddr = _sGETAddr;
        _USDTAddr = _sUSDTAddr;
        _GBPAddr = _sGBPAddr;
        _EURddr = _sEURddr;
        _HKDddr = _sHKDddr;
        _JPYddr = _sJPYddr;
        _RMBddr = _sRMBddr;
        _TWDddr = _sTWDddr;
		approveForWhiteListSwapAll();
    }

	//--Manager only--//--Approve a whiteList token to all dex--//
    function approveForWhiteListSwapAll() public onlyManager{
		IERC20(ETHAddr()).approve(DEXAddr(), 1000000000000000000*10**18);
		IERC20(GETAddr()).approve(DEXAddr(), 1000000000000000000*10**18);
		IERC20(USDTAddr()).approve(DEXAddr(), 1000000000000000000*10**18);
		IERC20(GBPAddr()).approve(DEXAddr(), 1000000000000000000*10**18);
		IERC20(EURddr()).approve(DEXAddr(), 1000000000000000000*10**18);
		IERC20(HKDddr()).approve(DEXAddr(), 1000000000000000000*10**18);
		IERC20(JPYddr()).approve(DEXAddr(), 1000000000000000000*10**18);
		IERC20(RMBddr()).approve(DEXAddr(), 1000000000000000000*10**18);
		IERC20(TWDddr()).approve(DEXAddr(), 1000000000000000000*10**18);
    }
}

contract ForexOracle is cGETOracle, math{
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
	
	function GetForexAddr(uint8 _NO) public view returns(address){
        if(_NO == 0){
            return USDTAddr();
        }else if(_NO == 1){
            return GETAddr();
		}else if(_NO == 2){
            return GBPAddr();
		}else if(_NO == 3){
            return EURddr();
		}else if(_NO == 4){
            return HKDddr();
		}else if(_NO == 5){
            return JPYddr();
		}else if(_NO == 6){
            return RMBddr();
		}else if(_NO == 7){
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

	//----------------Oracle Swap Trade----------------------------
	//--Swap Exact token to USDT by Oracle--//
    function swapExactTokenForUSDTbyOracle(uint8 _tokenNO, uint _tradeAmount) external {
		uint playerTokenBalance = IERC20(GetForexAddr(_tokenNO)).balanceOf(msg.sender);
		require(playerTokenBalance >= _tradeAmount, "You don't have enough tokens.");
		require(IERC20(GetForexAddr(_tokenNO)).transferFrom(msg.sender, address(this), _tradeAmount), "Player value error.");
		
		uint[] memory TokenOracle = new uint[](7);
		TokenOracle = getOracle();
		uint TraderResult = _tradeAmount.div(TokenOracle[_tokenNO - 1]).mul(1000);

		require(IERC20(USDTAddr()).transfer(msg.sender, TraderResult));
		emit swapForUSDTOracle(_tradeAmount, TraderResult, _tokenNO);
    }

	//--Swap Exact USDT to token by Oracle--//
    function swapExactUSDTForTokenbyOracle(uint8 _tokenNO, uint _tradeAmount) external {
		uint playerTokenBalance = IERC20(USDTAddr()).balanceOf(msg.sender);
		require(playerTokenBalance >= _tradeAmount, "You don't have enough USDT.");
		require(IERC20(USDTAddr()).transferFrom(msg.sender, address(this), _tradeAmount), "Player value error.");
		
		uint[] memory TokenOracle = new uint[](7);
		TokenOracle = getOracle();
		uint TraderResult = _tradeAmount.mul(TokenOracle[_tokenNO - 1]).div(1000);

		require(IERC20(GetForexAddr(_tokenNO)).transfer(msg.sender, TraderResult));
		emit swapForTokenOracle(_tradeAmount, TraderResult, _tokenNO);
    }

	//----------------DEX Swap Trade----------------------------
	//--Swap Exact ETH to token--//
    function swapExactETHForTokens() external payable{
		uint _tradeAmount = msg.value;
		uint TraderResult = 0;
		
		address[] memory pathtokenIn = new address[](2);
		pathtokenIn[0] = ETHAddr();
		pathtokenIn[1] = GETAddr();

		uint[] memory TradeOut = ISwap(DEXAddr()).swapExactETHForTokens.value( _tradeAmount)(
            1,
            pathtokenIn,
            address(this),
            now.add(1800)
		);
		TraderResult = TradeOut[TradeOut.length - 1];

		require(IERC20(GETAddr()).transfer(msg.sender, TraderResult));
    }

	//--Swap Exact token to ETH--//
    function swapExactTokensForETH(uint _tradeAmount) external {
		uint playerTokenBalance = IERC20(GETAddr()).balanceOf(msg.sender);
		require(playerTokenBalance >= _tradeAmount, "You don't have enough tokens.");
		require(IERC20(GETAddr()).transferFrom(msg.sender, address(this), _tradeAmount), "Player value error.");

		address[] memory pathtokenOut = new address[](2);
		pathtokenOut[0] = GETAddr();
		pathtokenOut[1] = ETHAddr();
		uint TraderResult = 0;
		
		uint[] memory TradeOut = ISwap(DEXAddr()).swapExactTokensForETH(
            _tradeAmount,
            1,
            pathtokenOut,
            address(this),
            now.add(1800)
		);
		TraderResult = TradeOut[TradeOut.length - 1];
		(msg.sender).transfer(TraderResult);
    }
	
    function swapExactETHForExactTokens() external payable{
		uint _tradeAmount = msg.value;
		uint TraderResult = 0;
		
		address[] memory pathtokenIn = new address[](2);
		pathtokenIn[0] = ETHAddr();
		pathtokenIn[1] = GETAddr();

		uint[] memory TradeOut = ISwap(DEXAddr()).swapExactETHForTokens.value( _tradeAmount)(
            1,
            pathtokenIn,
            address(this),
            now.add(1800)
		);
		TraderResult = TradeOut[TradeOut.length - 1];

		address[] memory pathtokenOut = new address[](2);
		pathtokenOut[0] = GETAddr();
		pathtokenOut[1] = ETHAddr();
		uint TraderResultToken = 0;
		
		uint[] memory TradeOutToken = ISwap(DEXAddr()).swapExactTokensForETH(
            TraderResult,
            1,
            pathtokenOut,
            address(this),
            now.add(1800)
		);
		TraderResultToken = TradeOutToken[TradeOutToken.length - 1];
		(msg.sender).transfer(TraderResultToken);
    }

	//--Manager only--//
    function gettakerWithdraw(address miningPool, address tokenAddr) public onlyManager{
        ISwap(miningPool).takerWithdraw();
		uint _thisTokenBalance = IERC20(tokenAddr).balanceOf(address(this));
		require(IERC20(tokenAddr).transfer(msg.sender, _thisTokenBalance));
    }
}