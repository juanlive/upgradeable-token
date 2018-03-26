pragma solidity ^0.4.15;

/*********************************************************************************
 *********************************************************************************
 *
 * Name of the project: ERC20 Basic Token
 * Author: Juan Livingston 
 *
 *********************************************************************************
 ********************************************************************************/

 /* New ERC20 contract interface */

contract ERC20Basic {
	uint256 public totalSupply;
	function balanceOf(address who) constant returns (uint256);
	function transfer(address to, uint256 value) returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

// New upgraded token that has to accept confirmation of its existence
contract UpgToken {
	function confirm(bytes32 _balances,bytes32 _allowed) returns(bool);
	event TokenUpgraded(address _oldAddress,address _newAddress);
}

// Interface for Storage
contract GlobalStorageMultiId { 
	uint256 public regPrice;
	function registerUser(bytes32 _id) payable returns(bool);
	function changeAddress(bytes32 _id , address _newAddress) returns(bool);
	function setUint(bytes32 _id , bytes32 _key , uint256 _data , bool _overwrite) returns(bool);
	function getUint(bytes32 _id , bytes32 _key) constant returns(uint _data);
	function setString(bytes32 _id , bytes32 _key , string _data , bool _overwrite) returns(bool);
	function getString(bytes32 _id , bytes32 _key) constant returns(string _data);
	event Error(string _string);
	event RegisteredUser(address _address , bytes32 _id);
	event ChangedAdd(bytes32 _id , address _old , address _new);
}


// The Token
contract UpgradeableToken {

	// Token public variables
	string public name;
	string public symbol;
	uint8 public decimals; 
	string public version;
	uint256 public totalSupply;
	bool public locked;
	address public storageAddress;

	address public rootAddress;
	address public Owner;
	uint multiplier;
	bool registered;

	bytes32 public balances;
	bytes32 public allowed;

	//mapping(address => uint256) balances;
	//mapping(address => mapping(address => uint256)) allowed;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event TokenUpgraded(address _oldAddress,address _newAddress);


	// Modifiers

	modifier onlyOwner() {
		if ( msg.sender != rootAddress && msg.sender != Owner ) revert();
		_;
	}

	modifier onlyRoot() {
		if ( msg.sender != rootAddress ) revert();
		_;
	}

	modifier isUnlocked() {
		if ( locked && msg.sender != rootAddress && msg.sender != Owner ) revert();
		_;    	
	}


	// Safe math
	function safeAdd(uint x, uint y) internal returns (uint z) {
		require((z = x + y) >= x);
	}
	function safeSub(uint x, uint y) internal returns (uint z) {
		require((z = x - y) <= x);
	}


	// Token constructor
	function UpgradeableToken() {        
		locked = false;
		name = 'Upgradeable Token'; 
		symbol = 'UPT'; 
		decimals = 18; 
		version = "v1";
		multiplier = 10 ** uint(decimals);
		totalSupply = 1000000 * multiplier; // 1,000,000 tokens
		rootAddress = msg.sender;        
		Owner = msg.sender;
		storageAddress = 0xb94cde73d07e0fcd7768cd0c7a8fb2afb403327a; // Rinkeby
		// storageAddress = 0x8f49722c61a9398a1c5f5ce6e5feeef852831a64; // Mainnet
	}

	function getRegPrice() onlyOwner constant returns(uint) {
		// Returns value necessary to register token
		GlobalStorageMultiId Storage = GlobalStorageMultiId(storageAddress);
		return Storage.regPrice() * 2;
	}

	function registerToken(bytes32 _balances, bytes32 _allowed) onlyOwner payable {
		// To register Token in globalStorage. bytes32 can be anything that has not be already used by IS
		require(!registered); // It only does it one time
		balances = _balances;
		allowed = _allowed;
		GlobalStorageMultiId Storage = GlobalStorageMultiId(storageAddress);
		uint _value = Storage.regPrice();
		Storage.registerUser.value(_value)(_balances);
		Storage.registerUser.value(_value)(_allowed);
		Storage.setUint(balances,bytes32(rootAddress),totalSupply,true);
		registered = true;
	}

	function upgradeToken(address _newAddress) onlyOwner {
		// This is to update token to a new address and transfer ownership of Storage to the new address
		UpgToken newToken = UpgToken(_newAddress);
		require(newToken.confirm(balances,allowed));
		GlobalStorageMultiId Storage = GlobalStorageMultiId(storageAddress);
		Storage.changeAddress(balances,_newAddress);
		Storage.changeAddress(allowed,_newAddress);
	}


	function confirm(bytes32 _balances, bytes32 _allowed) returns(bool) {
		// This is called from older version, to register keys for IntelligentStorage
		require(!registered);
		balances = _balances;
		allowed = _allowed;
		registered = true;
		TokenUpgraded(msg.sender,this);
		return true;
	}

	// Only root function
	function changeRoot(address _newrootAddress) onlyRoot returns(bool){
		rootAddress = _newrootAddress;
		return true;
	}

	// Only owner functions

	// To send ERC20 tokens sent accidentally
	function sendToken(address _token,address _to , uint _value) onlyOwner returns(bool) {
		ERC20Basic Token = ERC20Basic(_token);
		require(Token.transfer(_to, _value));
		return true;
	}

	function changeOwner(address _newOwner) onlyOwner returns(bool) {
		Owner = _newOwner;
		return true;
	}
	   
	function unlock() onlyOwner returns(bool) {
		locked = false;
		return true;
	}

	function lock() onlyOwner returns(bool) {
		locked = true;
		return true;
	}


	function burn(uint256 _value) onlyOwner returns(bool) {
		GlobalStorageMultiId Storage = GlobalStorageMultiId(storageAddress);
		if ( Storage.getUint(balances,bytes32(rootAddress)) < _value ) revert();
		Storage.setUint(balances,bytes32(rootAddress), safeSub( Storage.getUint(balances,bytes32(rootAddress)) , _value ) , true);
		totalSupply = safeSub( totalSupply,  _value );
		Transfer(rootAddress, 0x0, _value);
		return true;
	}


	// Public getters

	function isLocked() constant returns(bool) {
		return locked;
	}


	// Standard function transfer
	function transfer(address _to, uint _value) isUnlocked returns (bool success) {
		GlobalStorageMultiId Storage = GlobalStorageMultiId(storageAddress);
		if (Storage.getUint(balances,bytes32(msg.sender)) < _value) return false;
		Storage.setUint(balances,bytes32(msg.sender), safeSub(Storage.getUint(balances,bytes32(msg.sender)), _value) , true); // balances[msg.sender] = safeSub(balances[msg.sender], _value);
		Storage.setUint(balances,bytes32(_to), safeAdd(Storage.getUint(balances,bytes32(_to)), _value) , true); // balances[_to] = safeAdd(balances[_to], _value);
		Transfer(msg.sender,_to,_value);
		return true;
		}


	function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
		GlobalStorageMultiId Storage = GlobalStorageMultiId(storageAddress);
		bytes32 _bytes = bytes32(uint(_from) + uint(msg.sender));
		if ( locked && msg.sender != Owner && msg.sender != rootAddress ) return false; 
		if ( Storage.getUint(balances,bytes32(_from)) < _value ) return false; // Check if the sender has enough
		if ( _value > Storage.getUint(allowed,_bytes) ) return false; // Check allowance

		Storage.setUint(balances,bytes32(_from), safeSub(Storage.getUint(balances,bytes32(_from)) , _value) , true); // balances[_from] = safeSub(balances[_from] , _value);
		Storage.setUint(balances,bytes32(_to), safeAdd(Storage.getUint(balances,bytes32(_to)) , _value) , true); // balances[_to] = safeAdd(balances[_to] , _value);

		Storage.setUint(allowed,_bytes, safeSub( Storage.getUint(allowed,_bytes) , _value ) , true); // allowed[_from][msg.sender] = safeSub( allowed[_from][msg.sender] , _value );

		Transfer(_from , _to , _value);
		return true;
	}


	function balanceOf(address _owner) constant returns(uint256 balance) {
		GlobalStorageMultiId Storage = GlobalStorageMultiId(storageAddress);
		return Storage.getUint(balances,bytes32(_owner));
	}


	function approve(address _spender, uint _value) returns(bool) {
		GlobalStorageMultiId Storage = GlobalStorageMultiId(storageAddress);
		bytes32 _bytes = bytes32(uint(msg.sender) + uint(_spender));
		Storage.setUint(allowed,_bytes, _value , true); // allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}


	function allowance(address _owner, address _spender) constant returns(uint256) {
		GlobalStorageMultiId Storage = GlobalStorageMultiId(storageAddress);
		bytes32 _bytes = bytes32(uint(_owner) + uint(_spender));
		return Storage.getUint(allowed,_bytes);
	}
}
