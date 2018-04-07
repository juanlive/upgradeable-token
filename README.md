# upgradeable-token

Upgradeable token is a token tan can be upgraded, retaining its source of data

It uses IntelligentStorage to accomplish this (https://github.com/juanlive/intelligent-storage)

It is an ERC20 token with three extra functions:

- registerToken registers its two mappings into IntelligentStorage
- upgradeToken transfers ownership of storage to a new address, which should have the confirm function in order to accept ownership
- confirm is called by upgradeToken of an old token to transfer the keys to manage storage

----

There is a token deployed in Kovan network at 
0x6c971a10ed693958bd9cba13a2489e10ada1e97a

https://kovan.etherscan.io/address/0x6c971a10ed693958bd9cba13a2489e10ada1e97a

You can check the code and the balance for the rootAddress, and check some transaction details and event logs. You can also ask me for some tokens to try it.

-----

Usage

The token should be registered at Intelligent Storage for first time either manually or through a previous version. To do it manually, there is the registerToken function. It will initialize the token with Intelligent Storage.

registerToken(bytes32 _balances,bytes32 _allowed)

_balances and _allowed can be any bytes32 value (it can be converted from a string) thas has not been yet registered at IntelligentStorage. 

To do it from a previous version, there is the function upgradeToken at the old version, which will transfer access to Intelligent Storage to the new version and will send it the keys.

upgradeToken(address _newAddress)

The new version should have a "confirm" function that will receive the two keys needed to contact with IntelligentStorage.

----------

Measurements

Approx gas consumed by functions:

This Upgradeable ERC20 token:
First transfer: 66,074
Further transfers to the same address: 51,079

Common ERC20 token:
First transfer: 52,341
Further tfs: 37,341


