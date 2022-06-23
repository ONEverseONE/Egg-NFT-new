//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @author Ace

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFT is ERC721Enumerable{

    uint tokenId;

    constructor() ERC721("test NFT","NFT"){}

    function mint(uint amount) external{
        for(uint i=0;i<amount;i++){
            tokenId++;
            _safeMint(msg.sender,tokenId);
        }
    }

}