# upgradeable-token

Upgradeable token is a token tan can be upgraded, retaining its source of data

It uses IntelligentStorage to accomplish this (https://github.com/juanlive/intelligent-storage)

It is an ERC20 token with three extra functions:

- registerToken registers its two mappings into IntelligentStorage
- upgradeToken transfers ownership of storage to a new address, which should have the confirm function in order to accept ownership
- confirm is called by upgradeToken of an old token to transfer the keys to manage storage


Usage

registerToken(bytes32 _balances,bytes32 _allowed)

_balances and _allowed can be any bytes32 value (it can be converted from a string) thas has not been yet registered at IntteligentStorage. 

upgradeToken(address _newAddress)

When a new version of the token has been deployed, this will transfer ownership of storage to the new version. The new version should have a "confirm" function that will register the two keys needed to contact with IntelligentStorage

