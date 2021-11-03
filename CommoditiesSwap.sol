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

contract cCommoditiesSwap is Manager{
    using Address for address;
    using Sort for uint[];
	
    address _PriceOracle;
    address _PriceOracleEX;

    address _USDTAddr;
	address _GoldAddr;
	address _SilverAddr;
	address _CopperAddr;
	address _CrudeAddr;
	address _WheatAddr;
	address _NaturalGasAddr;
		
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

	function GoldAddr() public view returns(address){
        return _GoldAddr;
    }

	function SilverAddr() public view returns(address){
        return _SilverAddr;
    }

	function CopperAddr() public view returns(address){
        return _CopperAddr;
    }

	function CrudeAddr() public view returns(address){
        return _CrudeAddr;
    }

	function WheatAddr() public view returns(address){
        return _WheatAddr;
    }

	function NaturalGasAddr() public view returns(address){
        return _NaturalGasAddr;
    }
	
	//--Manager only--//
    function SetupMainAll(
	address _sUSDTAddr,
	address _sGoldAddr,
	address _sSilverAddr,
	address _sCopperAddr,
	address _sCrudeAddr,
	address _sWheatAddr,
	address _sNaturalGasAddr
	) public onlyManager{
        _USDTAddr = _sUSDTAddr;
        _GoldAddr = _sGoldAddr;
        _SilverAddr = _sSilverAddr;
        _CopperAddr = _sCopperAddr;
        _CrudeAddr = _sCrudeAddr;
        _WheatAddr = _sWheatAddr;
        _NaturalGasAddr = _sNaturalGasAddr;
    }
}

contract CommoditiesSwap is cCommoditiesSwap, math{
    using Address for address;
    function() external payable{}

    uint RateUSDT;
    uint RateGold;
    uint RateSilver;
    uint RateCopper;
    uint RateCrude;
    uint RateWheat;
    uint RateNaturalGas;

	event swapForUSDTOracle(uint _amountsIn, uint _amountsOut, uint8 _tokenNO);
	event swapForTokenOracle(uint _amountsIn, uint _amountsOut, uint8 _tokenNO);

	function GetForexAddr(uint8 _NO) public view returns(address){
        if(_NO == 0){
            return USDTAddr();
        }else if(_NO == 1){
            return GoldAddr();
		}else if(_NO == 2){
            return SilverAddr();
		}else if(_NO == 3){
            return CopperAddr();
		}else if(_NO == 4){
            return CrudeAddr();
		}else if(_NO == 5){
            return WheatAddr();
		}else if(_NO == 6){
            return NaturalGasAddr();
		}
    }

	function GetForexAddrEX(uint8 _NO) external view returns(address){
        if(_NO == 0){
            return USDTAddr();
        }else if(_NO == 1){
            return GoldAddr();
		}else if(_NO == 2){
            return SilverAddr();
		}else if(_NO == 3){
            return CopperAddr();
		}else if(_NO == 4){
            return CrudeAddr();
		}else if(_NO == 5){
            return WheatAddr();
		}else if(_NO == 6){
            return NaturalGasAddr();
		}
    }

	//--Oracle only--//--Get Price Oracle--//
    function QuotationFromOracle(
	uint _xRateUSDT,
	uint _xRateGold,
	uint _xRateSilver,
	uint _xRateCopper,
	uint _xRateCrude,
	uint _xRateWheat,
	uint _xRateNaturalGas
	) public onlyOracle{
		RateUSDT = _xRateUSDT;
		RateGold = _xRateGold;
		RateSilver = _xRateSilver;
		RateCopper = _xRateCopper;
		RateCrude = _xRateCrude;
		RateWheat = _xRateWheat;
		RateNaturalGas = _xRateNaturalGas;
    }

	function getOracle() public view returns (uint[] memory) {
		uint[] memory returOracle = new uint[](7);
		returOracle[0] = RateUSDT;
		returOracle[1] = RateGold;
		returOracle[2] = RateSilver;
		returOracle[3] = RateCopper;
		returOracle[4] = RateCrude;
		returOracle[5] = RateWheat;
		returOracle[6] = RateNaturalGas;
        return returOracle;
    }

	function getOracleEX() external view returns (uint[] memory) {
		uint[] memory returOracle = new uint[](7);
		returOracle[0] = RateUSDT;
		returOracle[1] = RateGold;
		returOracle[2] = RateSilver;
		returOracle[3] = RateCopper;
		returOracle[4] = RateCrude;
		returOracle[5] = RateWheat;
		returOracle[6] = RateNaturalGas;
        return returOracle;
    }

	//--Check input address assets of whitelist tokens--//
    function checkAddressAssets(address inputAddr) public view returns(uint[] memory){
		uint[] memory balanceToken = new uint[](7);
        for (uint8 i = 0; i < 7; i++){
			balanceToken[i] = IERC20(GetForexAddr(i)).balanceOf(inputAddr);
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

	//----------------Commodities Swap Trade----------------------------
	//--Swap Exact Integer token to USDT--//
    function swapExactIntegerTokenForUSDT(uint8 _tokenNO, uint _tradeInteger) external {
		uint playerTokenBalance = IERC20(GetForexAddr(_tokenNO)).balanceOf(msg.sender);
		uint _tradeAmount = _tradeInteger * 10 ** uint(18);
		require(playerTokenBalance >= _tradeAmount, "You don't have enough tokens.");
		require(IERC20(GetForexAddr(_tokenNO)).transferFrom(msg.sender, address(this), _tradeAmount), "User's value error.");
		
		uint[] memory TokenOracle = new uint[](7);
		TokenOracle = getOracle();
		uint TraderResult = _tradeAmount.mul(TokenOracle[_tokenNO]).div(10000);

		require(IERC20(USDTAddr()).transfer(msg.sender, TraderResult));
		emit swapForUSDTOracle(_tradeAmount, TraderResult, _tokenNO);
    }
	
	//--Swap USDT to Exact Integer token--//
    function swapUSDTForExactIntegerToken(uint8 _tokenNO, uint _tradeInteger) external {
		uint playerTokenBalance = IERC20(USDTAddr()).balanceOf(msg.sender);
		uint _tradeAmount = _tradeInteger * 10 ** uint(18);
		
		uint[] memory TokenOracle = new uint[](7);
		TokenOracle = getOracle();
		uint TraderUSDT = _tradeAmount.mul(TokenOracle[_tokenNO]).div(10000);

		require(playerTokenBalance >= TraderUSDT, "You don't have enough USDT.");
		require(IERC20(USDTAddr()).transferFrom(msg.sender, address(this), TraderUSDT), "User's value error.");

		require(IERC20(GetForexAddr(_tokenNO)).transfer(msg.sender, _tradeAmount));
		emit swapForTokenOracle(TraderUSDT, _tradeAmount, _tokenNO);
    }
	
	//--Check Swap Exact Integer token to USDT--//
    function checkExactIntegerTokenForUSDT(uint8 _tokenNO, uint _tradeInteger) public view returns(uint _USDTAmountsOut){
		uint _tradeAmount = _tradeInteger * 10 ** uint(18);
	
		uint[] memory TokenOracle = new uint[](7);
		TokenOracle = getOracle();
		uint _USDTAmountsOut = _tradeAmount.mul(TokenOracle[_tokenNO]).div(10000);
        return _USDTAmountsOut;
    }


	//--Check Swap USDT to Exact Integer token--//
    function checkUSDTForExactIntegerToken(uint8 _tokenNO, uint _tradeInteger) public view returns(uint _USDTAmountsIN){
		uint _tradeAmount = _tradeInteger * 10 ** uint(18);
		
		uint[] memory TokenOracle = new uint[](7);
		TokenOracle = getOracle();
		uint _USDTAmountsIN = _tradeAmount.mul(TokenOracle[_tokenNO]).div(10000);

        return _USDTAmountsIN;
    }
}