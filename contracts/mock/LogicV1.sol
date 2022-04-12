// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract LogicV1 is OwnableUpgradeable {
    uint public data;

    function initialize() initializer public {
        __Ownable_init();
    }

    function set(uint val) virtual external {
        data = val;
    }
}
