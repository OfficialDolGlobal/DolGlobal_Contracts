// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { ERC20Burnable } from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';

contract DolGlobal is ERC20, ERC20Burnable {
    constructor() ERC20('DolGlobal', 'DOL') {
        _mint(msg.sender, 300000000 * 10 ** decimals());
    }
}
