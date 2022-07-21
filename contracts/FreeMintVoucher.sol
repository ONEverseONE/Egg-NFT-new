//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract FreeMintVoucher is ERC721Enumerable,Ownable{

    uint tokenID;
    mapping(address=>bool) public approvedAddress;
    string commonURI;

    constructor() ERC721("OneVerse Free Egg Mint Voucher","FEV"){}

    function mint(uint _amount) external {
        require(msg.sender == owner() || approvedAddress[msg.sender],"Not owner or approved");
        for(uint i=1;i<=_amount;i++){
            _mint(msg.sender,tokenID+i);
        }
        tokenID += _amount;
    }

    function mintTo(address[] memory users) external {
        require(msg.sender == owner() || approvedAddress[msg.sender],"Not owner or approved");
        uint length = users.length;
        for(uint i=0;i<length;i++){
            _mint(users[i],tokenID+i+1);
        }
        tokenID += length;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return commonURI;
    }

    function setURI(string memory _uri) external onlyOwner{
        commonURI = _uri;
    }

    function setApproved(address _toApprove,bool _isApproved) external onlyOwner{
        approvedAddress[_toApprove] = _isApproved;
    }

}