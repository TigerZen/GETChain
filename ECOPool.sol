pragma solidity >= 0.5.17;

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

interface ISwap{
    function getOracle() external view returns (uint[] memory);
}

contract cECOPool is Manager{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _whitelist;

	uint distRate = 9500; // = 95% income to distribution.
	uint distLine = 10 * 10 ** uint(18); // Interest will only be distribution for deposits greater than 10 GET.

    address _dexAddr = 0xcbC886a48686A6b0A8Af922Be3CE5E2b8E1B856f;     //Oracle Addr
    address _treasury = 0xD25cc2716A387f2bf184370eCDF69C1b4597537E;
	address _secretary = 0x024F703fbF3e1e367f5b1F685f397aFce4Aa87b1;
	
	
	function() external payable{}

	function Treasury() public view returns(address){
        require(_treasury != address(0), "It's a null address");
        return _treasury;
    }
	
	function setTreasury(address addr) public onlyManager{
        _treasury = addr;
    }

	function DexAddr() public view returns(address){
        require(_dexAddr != address(0), "It's a null address");
        return _dexAddr;
    }
	
	function setDexAddr(address addr) public onlyManager{
        _dexAddr = addr;
    }

	function Secretary() public view returns(address){
        require(_secretary != address(0), "It's a null address");
        return _secretary;
    }
	
	function setSecretary(address addr) public onlyManager{
        _secretary = addr;
    }

    function setdistRate(uint amountRate) public onlyManager{
        distRate = amountRate;
    }

    function setdistLine(uint amountGET) public onlyManager{
        distLine = amountGET * 10 ** uint(18);
    }

    modifier onlySecretary{
        require(msg.sender == manager || msg.sender == Secretary(), "You are not Secretary.");
        _;
    }

    //----------------Whitelist Token----------------------------
	
    function addWhitelist(address _addToken) internal returns(bool) {
        require(_addToken != address(0), "SwapMining: token is the zero address");
        return EnumerableSet.add(_whitelist, _addToken);
    }

    function delWhitelist(address _delToken) internal returns(bool) {
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
}

contract ECOPool is cECOPool, math{
    using Address for address;
    function() external payable{}
	
	uint GETTokenTDV;    //Current Total Value
	uint TotalGETOut;  //Total ETH pay out
	uint incomeBeforeUpdate;
	uint incomeLastUpdate;
	uint timeThisUpdate;
	uint timeLastUpdate;
	uint incomeUpdateTimes;
	
	uint dayAPR = 0;
	uint[] incomedaily;
	uint[] timeUpdatedaily;
	
    struct DepositInfo {
        uint timestamp;
        uint GETDepositValue;
        uint GETearnValue;
    }

    mapping(address => DepositInfo) public depositInfos;

    event depositQT(uint _TotalDepositAmount, bool result);
    event withdrawGET(uint _withdrawGETAmount,uint _withdrawETHAmount, bool result);
    event withdrawHarvest(uint _withdrawETHAmount, bool result);
	
	//----------------ECO POOL Function----------------------------
	
	//--Deposit GET to ECO POOL contract--//
    function depositGETToken() external payable{
		uint _DepositAmount = msg.value;

		address Useradder = msg.sender;
		if(!isWhitelist(Useradder)){
		
            depositInfos[Useradder].timestamp = now;
            depositInfos[Useradder].GETDepositValue = _DepositAmount;
            depositInfos[Useradder].GETearnValue = 0;
			GETTokenTDV = GETTokenTDV.add(_DepositAmount);

			addWhitelist(Useradder);
			emit depositQT(_DepositAmount, true);
		}else{
            uint _newDepositAmount = depositInfos[Useradder].GETDepositValue.add(_DepositAmount);

            depositInfos[Useradder].timestamp = now;
            depositInfos[Useradder].GETDepositValue = _newDepositAmount;
            depositInfos[Useradder].GETearnValue = depositInfos[Useradder].GETearnValue;
			GETTokenTDV = GETTokenTDV.add(_DepositAmount);
			
			emit depositQT(_newDepositAmount, true);
		}
    }

	//--Withdraw GET from ECO POOL contract--//
    function withdrawPOOLGET(uint _withdrawAmount) external{
		require(isWhitelist(msg.sender), "ECO POOL : This address is not in user list");
		require(_withdrawAmount <= depositInfos[msg.sender].GETDepositValue, "ECO POOL : Withdraw value error");
	
		if(_withdrawAmount == 0){
            uint _withdrawGETAmount = depositInfos[msg.sender].GETDepositValue;
	        uint _withdrawETHAmount = depositInfos[msg.sender].GETearnValue;	
			uint _withdrawALLAmount = _withdrawGETAmount.add(_withdrawETHAmount);
			(msg.sender).transfer(_withdrawALLAmount);
		
            depositInfos[msg.sender].timestamp = now;
            depositInfos[msg.sender].GETDepositValue = 0;
            depositInfos[msg.sender].GETearnValue = 0;
			GETTokenTDV = GETTokenTDV.sub(_withdrawGETAmount);
			TotalGETOut = TotalGETOut.add(_withdrawETHAmount);
			
			emit withdrawGET(_withdrawGETAmount, _withdrawETHAmount, true);
		}else{
            uint _newGETDepositValue = depositInfos[msg.sender].GETDepositValue.sub(_withdrawAmount);
	        uint _withdrawETHAmount = depositInfos[msg.sender].GETearnValue;	
			uint _withdrawALLAmount = _withdrawAmount.add(_withdrawETHAmount);			
			(msg.sender).transfer(_withdrawALLAmount);

            depositInfos[msg.sender].timestamp = now;
            depositInfos[msg.sender].GETDepositValue = _newGETDepositValue;
            depositInfos[msg.sender].GETearnValue = 0;
			GETTokenTDV = GETTokenTDV.sub(_withdrawAmount);
			TotalGETOut = TotalGETOut.add(_withdrawETHAmount);
			
			emit withdrawGET(_withdrawAmount, _withdrawETHAmount, true);
		}
		
		if(depositInfos[msg.sender].GETDepositValue == 0){
			delWhitelist(msg.sender);	
		}
    }

	//--Harvest Earnings from ECO POOL contract--//
    function harvestEarnings() external{
		require(isWhitelist(msg.sender), "ECO POOL : This address is not in user list");
		require(depositInfos[msg.sender].GETearnValue >= 0, "ECO POOL : You have not yet earned.");
		uint _withdrawETHAmount = depositInfos[msg.sender].GETearnValue;		

		(msg.sender).transfer(_withdrawETHAmount);
		
		depositInfos[msg.sender].timestamp = now;
		depositInfos[msg.sender].GETDepositValue = depositInfos[msg.sender].GETDepositValue;
		depositInfos[msg.sender].GETearnValue = 0;
		TotalGETOut = TotalGETOut.add(_withdrawETHAmount);
			
		emit withdrawHarvest(_withdrawETHAmount, true);
    }
	
	//--GET income to ECO POOL contract--//
    function incomeECOPool() public payable{
		uint _incomeAmount = msg.value;
		require(_incomeAmount != 0, "ECO POOL : Did not send GET in!");
		incomeBeforeUpdate = incomeBeforeUpdate.add(_incomeAmount);
    }
	
	//--GET income to ECO POOL contract--//
    function incomeECOPoolEX() external payable{
		uint _incomeAmount = msg.value;
		require(_incomeAmount != 0, "ECO POOL : Did not send GET in!");
		incomeBeforeUpdate = incomeBeforeUpdate.add(_incomeAmount);
    }

	//--Update income to users--//
    function UpdateECOPool() external onlySecretary{
		uint amountUsers = getWhitelistLength();
		uint distributionIncome = incomeBeforeUpdate.mul(distRate).div(10000);
		uint TreasuryRate = uint(10000).sub(distRate);
		uint TreasuryDistribution = incomeBeforeUpdate.mul(TreasuryRate).div(10000);
	
        for (uint i = 0; i < amountUsers; i++) {
            UpdateUserIncome(distributionIncome, getWhitelist(i));
        }
		incomeLastUpdate = incomeBeforeUpdate;
		incomeBeforeUpdate = 0;
		timeLastUpdate = timeThisUpdate;
		timeThisUpdate = now;
		incomeUpdateTimes = incomeUpdateTimes.add(1);

		Treasury().toPayable().transfer(TreasuryDistribution);
    }
	
	//--Update income to users--//
    function UpdateECOPoolRecord() external onlySecretary{
		uint amountUsers = getWhitelistLength();
		uint distributionIncome = incomeBeforeUpdate.mul(distRate).div(10000);
		uint TreasuryRate = uint(10000).sub(distRate);
		uint TreasuryDistribution = incomeBeforeUpdate.mul(TreasuryRate).div(10000);
		
		if(incomedaily.length == 0){
            incomedaily.push(0);
            timeUpdatedaily.push(0);
		}
		
		uint _timeUpdate = 0;
		if(timeThisUpdate != 0){
            _timeUpdate = now.sub(timeThisUpdate);
		}
		incomedaily[dayAPR] = incomedaily[dayAPR].add(incomeBeforeUpdate);
		timeUpdatedaily[dayAPR] = timeUpdatedaily[dayAPR].add(_timeUpdate);
		if(timeUpdatedaily[dayAPR] >= 86400){
            timeUpdatedaily[dayAPR] = 86400;
			dayAPR = dayAPR.add(1);
            incomedaily.push(0);
            timeUpdatedaily.push(0);
		}

        for (uint i = 0; i < amountUsers; i++) {
            UpdateUserIncome(distributionIncome, getWhitelist(i));
        }
		incomeLastUpdate = incomeBeforeUpdate;
		incomeBeforeUpdate = 0;
		timeLastUpdate = timeThisUpdate;
		timeThisUpdate = now;
		incomeUpdateTimes = incomeUpdateTimes.add(1);
		Treasury().toPayable().transfer(TreasuryDistribution);
    }
	
	//--Update income to a user--//
    function UpdateUserIncome(uint _distributionIncome, address userAddr) private {
		if(depositInfos[userAddr].GETDepositValue >= distLine){
			uint _addIncome = _distributionIncome.mul(depositInfos[userAddr].GETDepositValue).div(GETTokenTDV);
			depositInfos[userAddr].timestamp = now;
			depositInfos[userAddr].GETearnValue = depositInfos[userAddr].GETearnValue.add(_addIncome);
		}
    }

	//--Manager only--//
    function takeTokensToManager(address tokenAddr) external onlyManager{
        uint _thisTokenBalance = IERC20(tokenAddr).balanceOf(address(this));
        require(IERC20(tokenAddr).transfer(msg.sender, _thisTokenBalance));
    }

	//--Manager only--//
	function destroy() external onlyManager{ 
        selfdestruct(msg.sender); 
	}

	//--Manager only--//
    function SetupAll(address _sDEXAddr, address _sTreasury, address _sSecretaryAddr) public onlyManager{
        setDexAddr(_sDEXAddr);
		setTreasury(_sTreasury);
		setSecretary(_sSecretaryAddr);
    }
	
	
	//----------------inquiry----------------------------
	//--Check state of the pool--//
    function inqECOPool() public view returns(uint[] memory){
	
		uint[] memory returnint = new uint[](7);
		returnint[0] = GETTokenTDV;
		returnint[1] = TotalGETOut;
		returnint[2] = incomeBeforeUpdate;
		returnint[3] = incomeLastUpdate;
		returnint[4] = timeThisUpdate;
		returnint[5] = timeLastUpdate;
		returnint[6] = incomeUpdateTimes;
		
        return returnint;
    }

	//--Check input address Info--//
    function checkAddressInfo(address inputAddr) public view returns(uint[] memory){
		require(isWhitelist(inputAddr), "ECO Pool : This this address is not in user list");
		uint[] memory returnint = new uint[](3);
		returnint[0] = depositInfos[inputAddr].timestamp;
		returnint[1] = depositInfos[inputAddr].GETDepositValue;
		returnint[2] = depositInfos[inputAddr].GETearnValue;
		
        return returnint;
    }

	//--Check income & APR daily--//
    function inqECOPooldailyAPR(uint _day) public view returns(uint[] memory){
		require(_day <= dayAPR, "ECO Pool : Day of APR error");
		
		uint[] memory ECOPooldailyAPR = new uint[](3);
		ECOPooldailyAPR[0] = _day;
		ECOPooldailyAPR[1] = incomedaily[_day];
		ECOPooldailyAPR[2] = timeUpdatedaily[_day];
		
        return ECOPooldailyAPR;
    }

	//--Check APR--//
    function checkAPRdaily() public view returns(
		uint _APR){
		uint GETTokenPrice = inqGETTokenBuyPrice();
		uint AmountInGET = uint(1 * 10 ** uint(22)).div(GETTokenPrice);
		uint ECOPoolGETValue = GETTokenTDV.div(AmountInGET).mul(10000);
		
		uint dailyIncome1 = 0;
		uint dailyIncome2 = 0;
		if(dayAPR > 0){
			dailyIncome1 = incomedaily[dayAPR - 1];
			if(incomedaily[dayAPR] == 0){
				dailyIncome2 = incomedaily[dayAPR - 1];
			}else{
				dailyIncome2 = incomedaily[dayAPR].div(timeUpdatedaily[dayAPR]).mul(86400);		
			}

		}else{
			dailyIncome1 = incomedaily[dayAPR].div(timeUpdatedaily[dayAPR]).mul(86400);
			dailyIncome2 = incomedaily[dayAPR].div(timeUpdatedaily[dayAPR]).mul(86400);
		}

		uint dailyIncomeAverage = (dailyIncome1.add(dailyIncome2)).div(2);
		uint yearIncome = dailyIncomeAverage.mul(365);
		uint APR = yearIncome.mul(10000).div(ECOPoolGETValue);

        return APR;
    }

	//--Check APR--//
    function checkAPR() public view returns(
		uint _APR){
		uint GETTokenPrice = inqGETTokenBuyPrice();
		uint AmountInGET = uint(1 * 10 ** uint(22)).div(GETTokenPrice);
		uint ECOPoolGETValue = GETTokenTDV.div(AmountInGET).mul(10000);
		uint timeRange = timeThisUpdate.sub(timeLastUpdate);
		
		uint dailyIncome = incomeLastUpdate.div(timeRange).mul(86400);
		uint yearIncome = dailyIncome.mul(365);
		uint APR = yearIncome.mul(10000).div(ECOPoolGETValue);

        return APR;
    }
	
	//--Calculate Total Deposited Value--//
    function inqTotalDepositedValue() public view returns(
        uint _TDV){

		uint GETTokenPrice = inqGETTokenBuyPrice();
		uint AmountInGET = uint(1 * 10 ** uint(22)).div(GETTokenPrice);
		uint ECOPoolGETValue = GETTokenTDV.div(AmountInGET).mul(10000);
        return ECOPoolGETValue;
    }

	//--Calculate GETToken buy price in Oracle by GET value--//
    function inqGETTokenBuyPrice() public view returns(
        uint _tokenPrice){

		uint amountsOut = 1*10**18;
		uint[] memory _amountsINToken = new uint[](7);
		_amountsINToken = ISwap(_dexAddr).getOracle();
		uint _xtokenPrice = amountsOut.div(_amountsINToken[0]).mul(10000);
		
        return _xtokenPrice;
    }

	//----------------inquiry for App----------------------------

	//--Check state of ECO pool--//
    function inqECOPoolForApp() public view returns(uint[] memory){
	
		uint[] memory returnint = new uint[](7);
		returnint[0] = GETTokenTDV.div(1 * 10 ** uint(18));
		returnint[1] = TotalGETOut.div(1 * 10 ** uint(16));
		returnint[2] = incomeBeforeUpdate.div(1 * 10 ** uint(14));
		returnint[3] = incomeLastUpdate.div(1 * 10 ** uint(14));
		returnint[4] = timeThisUpdate;
		returnint[5] = timeLastUpdate;
		returnint[6] = incomeUpdateTimes;
		
        return returnint;
    }

	//--Check input address Info For App--//
    function checkAddressInfoApp(address inputAddr) public view returns(uint[] memory){
		require(isWhitelist(inputAddr), "ECOPool : This this address is not in user list");
		uint[] memory returnint = new uint[](3);
		returnint[0] = depositInfos[inputAddr].timestamp;
		returnint[1] = depositInfos[inputAddr].GETDepositValue.div(1 * 10 ** uint(16));
		returnint[2] = depositInfos[inputAddr].GETearnValue.div(1 * 10 ** uint(14));
		
        return returnint;
    }

	//--Calculate Total Deposited Value For App--//
    function inqTotalDepositedValueForApp() public view returns(
        uint _TDV){

		uint GETTokenPrice = inqGETTokenBuyPrice();
		uint AmountInGET = uint(1 * 10 ** uint(18)).div(GETTokenPrice);
		uint ECOPoolGETValue = GETTokenTDV.div(AmountInGET).div(1 * 10 ** uint(16));
        return ECOPoolGETValue;
    }
	

	//--Check income & APR daily For App--//
    function inqECOPooldailyAPRForApp(uint _day) public view returns(uint[] memory){
		require(_day <= dayAPR, "ECOPool : Day of APR error");
		
		uint[] memory ECOPooldailyAPR = new uint[](3);
		ECOPooldailyAPR[0] = _day;
		ECOPooldailyAPR[1] = incomedaily[_day].div(1 * 10 ** uint(16));
		ECOPooldailyAPR[2] = timeUpdatedaily[_day];
		
        return ECOPooldailyAPR;
    }
}