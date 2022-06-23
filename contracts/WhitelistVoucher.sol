// SPDX-License-Identifier: UNLICENSED
//@notice DEPRECATED; going with airdrop
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";


interface AceBadgeContract {
    function getBadgeTier(uint256 _badgetocheck)
        external
        view
        returns (uint256);
}

contract voucherEggContract is ERC721Enumerable, Ownable, AceBadgeContract {
    ERC721 BadgeContract;
    AceBadgeContract deployedBadgeContract;

    struct EggVoucher {
        uint256 tokenID;
        uint256 redeemableEggs;
        uint256 IssuanceDate;
    }

    mapping(uint256 => bool) public usedBadgeHoldersWhitelist;

    function getBadgeTier(uint256 _badgetocheck) public view returns (uint256) {
        uint256 result = deployedBadgeContract.getBadgeTier(_badgetocheck);

        return result;
    }

    string oneEggArt =
        "https://gateway.pinata.cloud/ipfs/QmavoG8o8mXwYJFNJY3fbDD4b3uXUdSu7V2WvPG8r35y36";
    string threeEggArt =
        "https://gateway.pinata.cloud/ipfs/QmYDEt18Pgdyorac1vCccrcjvsAHWETwsswrE2G3ea3E5Y";
    string fiveEggArt =
        "https://gateway.pinata.cloud/ipfs/QmT7K6rKtnH1ZFEZKdVeUce16LZ8sSEYXGmyro2EuZFdjg";

    constructor(address _BadgeContractAddress)
        ERC721("OV Egg Vouchers", "V-EGG")
    {
        BadgeContract = ERC721(_BadgeContractAddress);
        deployedBadgeContract = AceBadgeContract(_BadgeContractAddress);
    }

    EggVoucher[] public VoucherList;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event newVoucherMinted(
        address indexed newVoucherHolder,
        uint256 indexed amountofRedeemableEggs
    );

    function mintWhitelistVoucherNFT(uint256 _badgeToRedeem) external {
        require(BadgeContract.balanceOf(msg.sender) > 0, "No Badge, no Entry!");

        require(
            BadgeContract.ownerOf(_badgeToRedeem) == msg.sender && !(usedBadgeHoldersWhitelist[_badgeToRedeem])
            
        );
        usedBadgeHoldersWhitelist[_badgeToRedeem] = true;

        uint256 badgeTier = getBadgeTier(_badgeToRedeem);
        uint256 _redeemableEggs;

        if (badgeTier == 0) {
            // nothing
        } else if (badgeTier == 1) {
            _redeemableEggs = 3;
        } else if (badgeTier == 2) {
            _redeemableEggs = 5;
        } else if (badgeTier == 3) {
            _redeemableEggs = 8;
        } else if (badgeTier == 4) {
            _redeemableEggs = 10;
        } else if (badgeTier == 5) {
            _redeemableEggs = 13;
        } else if (badgeTier == 6) {
            _redeemableEggs = 25;
        } else if (badgeTier == 7) {
            _redeemableEggs = 50;
        }


        uint256 newItemId = _tokenIds.current();
        for(uint i= 0; i<_redeemableEggs;i++){
            uint voucherDefaultSize = 1;


             _safeMint(msg.sender, newItemId);
              

                VoucherList.push(
            EggVoucher(newItemId, voucherDefaultSize, block.timestamp)
        );
        _tokenIds.increment();
        newItemId = _tokenIds.current();
       
       

        emit newVoucherMinted(msg.sender, voucherDefaultSize);


        }
        

    }

    function checkRedeemableEggs(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return VoucherList[_tokenId].redeemableEggs;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        EggVoucher memory VoucherAttributes = VoucherList[_tokenId];

        string memory eggsRedeemable = Strings.toString(
            VoucherAttributes.redeemableEggs
        );

        string memory title;
        string memory picture;
        string memory dateofcreation = Strings.toString(
            VoucherAttributes.IssuanceDate
        );

        if (VoucherAttributes.redeemableEggs == 1) {
            title = "Tier One Voucher Ticket";
            picture = oneEggArt;
        } else if (VoucherAttributes.redeemableEggs == 3) {
            title = "Tier Two Voucher Ticket";
            picture = threeEggArt;
        } else if (VoucherAttributes.redeemableEggs == 5) {
            title = "Tier Three Voucher Ticket";
            picture = fiveEggArt;
        }

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        title,
                        " #: ",
                        Strings.toString(_tokenId),
                        '", "description": "Redeemable for Eggs!", "image": "',
                        picture,
                        '", "attributes": [ { "trait_type": "Eggs Redeemable", "value": ',
                        eggsRedeemable,
                        '}, { "display_type" : "Date" ,"trait_type": "Issuance Date", "value": ',
                        dateofcreation,
                        "} ]}"
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }
}
