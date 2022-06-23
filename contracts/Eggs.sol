//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface Iwhitelistvouchers is IERC721{
    function checkRedeemableEggs(uint256 _tokenId)
        external
        view
        returns (uint256);

    function checkIfPreminted(uint256 _tokenId) external view returns (bool);
}

interface VoucherIncubators {
    function giveVoucherIncubator(uint256 _amountOfTickets, address _receiver)
        external;
}

contract Eggs is ERC721Enumerable,Ownable{


    IERC20 Grav;
    IERC20 USDC;

    Iwhitelistvouchers wlVoucher;
    VoucherIncubators incubator;

    struct Egg {
        uint Breed; //@notice check which Breed ( Dragon, Fish, Slime, Snake, Stone) Layer to use
        uint EggColour; //@notice check which EggColour Layer to use                                      @TODO DNA
        uint FogColour; //@notice check which Fog Layer to use                                            @TODO DNA
        uint BackgroundColour; //@notice check which Background to use                             @TODO DNA
        bool hasIncubator; //@notice check if Capsule Layer or Stonebase Layer
        uint incubatorColour; //@notice check which Capsule Layer to use                            @TODO DNA
        uint256 incubatorLevel; //@notice check which Capsule Progression Bar Layer to use
        uint256[5] TimeOfLeveling;
        bool wasPreminted;
    }


    //@dev fee in grav
    uint public incubatorFee; 

    //@dev prices in grav
    // uint public phase2;
    // uint public phase3;
    uint[2] public gravFee; 

    //@dev prices in usdc
    // uint public phase1;
    // uint public phase2;
    // uint public phase3;
    uint[3] public usdcFee = [38.5e6,44e6,55e6];

    uint tokenID;
    uint MAX_SUPPLY = 5555;
    uint PAHSE_1_SUPPLY = 1000;

    bool public Phase1;
    string public baseURI;
    string public imageFileType;

    mapping(uint=>Egg) EggsMetadata;

    //TODO: ADD NUMBERS IN THE ARRAY
    uint256[5][5] private COLOURRARITY = [[31,81,222,333,444],
                                        [31,81,222,333,444],
                                        [31,81,222,333,444],
                                        [31,81,222,333,444],
                                        [31,81,222,333,444]];
    uint256[4] private FOGRARITY = [100,555,1567,3333];
    uint256[6] private BACKGROUNDRARITY = [100,255,400,1110,1465,2225];
    uint256[5] private CAPSULERARITY = [155,400,1110,1665,2225];
    uint256[5] private BREEDRARITY = [1111,1111,1111,1111,1111];

    uint[4] public total = [5555,5555,5555,5555];

    constructor(address _grav,address _usdc) ERC721("OneVerse Eggs","EGG"){
        Grav = IERC20(_grav);
        USDC = IERC20(_usdc);
    }

    function mint(uint256[] calldata _whitelistID) external{
        require(msg.sender == tx.origin,"Contract not allowed");
        uint length = _whitelistID.length;

        for(uint i=0;i<length;i++){
            require(wlVoucher.ownerOf(_whitelistID[i])==msg.sender,"Not owner");
            uint redeemable = wlVoucher.checkRedeemableEggs(_whitelistID[i]);
            require(MAX_SUPPLY >= tokenID + redeemable,"Max supply reached");

            wlVoucher.transferFrom(msg.sender, address(this), _whitelistID[i]);

            uint price;

            if(Phase1){
                require(PAHSE_1_SUPPLY >= tokenID + redeemable,"Phase limit reached");
                price = usdcFee[0] * redeemable;
                require(USDC.transferFrom(msg.sender, address(this), price),"Price not paid");
                incubator.giveVoucherIncubator(redeemable,msg.sender);
            }else{
                //TODO add in vote based toggle
                price = gravFee[0] * redeemable;
                require(Grav.transferFrom(msg.sender, address(this), price),"Price not paid");
            }
            uint random = uint(vrf());
            for(uint k=0;k<redeemable;k++){
                tokenID++;
                _safeMint(msg.sender, tokenID);
                EggsMetadata[tokenID] = generateEgg(random, k);
            }
            
        }
    }

    function generateEgg(uint random,uint salt)
        private
        returns (Egg memory)
    {
        Egg memory newEgg;

        uint breedToAssign;
        uint eggColourToAssign;
        uint fogColourToAssign;
        uint backgroundColourToAssign;

        random = uint(keccak256(abi.encodePacked(random,salt)));

        uint randSliced = random % total[0];
        random /= 10000;
        uint cumulative = 0;

        for(uint i=0;i<BREEDRARITY.length;i++){
            if(randSliced < cumulative + BREEDRARITY[i]){
                breedToAssign = i;
                BREEDRARITY[i]--;
                total[0]--;
                break;
            }
            else{
                cumulative += BREEDRARITY[i];
            }
        }

        randSliced = random % total[1];
        random /= 10000;

        cumulative = 0;

        for (uint256 i = 0; i < COLOURRARITY.length; i++) {
            if (randSliced < cumulative + COLOURRARITY[breedToAssign][i]) 
            {
                eggColourToAssign = i;
                COLOURRARITY[breedToAssign][i]--;
                total[1]--;
                break;
            } 
            else {
                cumulative += COLOURRARITY[breedToAssign][i];
            }
        }

        randSliced = random % total[2];
        random /= 10000;
        cumulative = 0;

        for (uint256 i = 0; i < FOGRARITY.length; i++) {
            if (randSliced < cumulative + FOGRARITY[i]) 
            {
                fogColourToAssign = i;
                FOGRARITY[i]--;
                total[2]--;
                break;
            } 
            else 
            {
                cumulative += FOGRARITY[i];
            }
        }

        randSliced = random % total[3];
        random /= 10000;
        cumulative = 0;

        
        for (uint256 i = 0; i < BACKGROUNDRARITY.length; i++) {
            if (randSliced < cumulative + BACKGROUNDRARITY[i]) {
                backgroundColourToAssign = i;
                BACKGROUNDRARITY[i]--;
                total[3]--;
                break;
            } else {
                cumulative += BACKGROUNDRARITY[i];
            }
        }

        newEgg.Breed = breedToAssign;
        newEgg.EggColour = eggColourToAssign;
        newEgg.FogColour = fogColourToAssign;
        newEgg.BackgroundColour = backgroundColourToAssign;

        newEgg.hasIncubator = false;

        return newEgg;
    }

    function vrf() private view returns (bytes32 result) {
        uint256[1] memory bn;
        bn[0] = block.number;
        assembly {
            let memPtr := mload(0x40)
            if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
                invalid()
            }
            result := mload(memPtr)
        }
    }

function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        Egg memory EggAttributes = EggsMetadata[_tokenId];

        string memory hasIncubator = EggAttributes.hasIncubator ? "yes" : "no";

        string memory eggcolor;
        if (uint8(EggAttributes.EggColour) == 0) {
            eggcolor = "gold";
        } else if (uint8(EggAttributes.EggColour) == 1) {
            eggcolor = "purple";
        } else if (uint8(EggAttributes.EggColour) == 2) {
            eggcolor = "red";
        } else if (uint8(EggAttributes.EggColour) == 3) {
            eggcolor = "blue";
        } else if (uint8(EggAttributes.EggColour) == 4) {
            eggcolor = "gray";
        }

        string memory fogcolor;
        if (uint8(EggAttributes.FogColour) == 0) {
            fogcolor = "green";
        } else if (uint8(EggAttributes.FogColour) == 1) {
            fogcolor = "purple";
        } else if (uint8(EggAttributes.FogColour) == 2) {
            fogcolor = "white";
        } else if (uint8(EggAttributes.FogColour) == 3) {
            fogcolor = "none";
        }

        string memory breedtype;
        if (uint8(EggAttributes.Breed) == 0) {
            breedtype = "draconesh";
        } else if (uint8(EggAttributes.Breed) == 1) {
            breedtype = "ichthia";
        } else if (uint8(EggAttributes.Breed) == 2) {
            breedtype = "khusatzal";
        } else if (uint8(EggAttributes.Breed) == 3) {
            breedtype = "lasseateran";
        } else if (uint8(EggAttributes.Breed) == 4) {
            breedtype = "mixoteran";
        }

        string memory incubatorColor;
        if (
            uint8(EggAttributes.incubatorColour) == 0 &&
            EggAttributes.hasIncubator
        ) {
            incubatorColor = "gold";
        } else if (uint8(EggAttributes.incubatorColour) == 1) {
            incubatorColor = "purple";
        } else if (uint8(EggAttributes.incubatorColour) == 2) {
            incubatorColor = "red";
        } else if (uint8(EggAttributes.incubatorColour) == 3) {
            incubatorColor = "blue";
        } else if (uint8(EggAttributes.incubatorColour) == 4) {
            incubatorColor = "gray";
        } else {
            incubatorColor = "N/A";
        }
        string memory backgroundcolor;
        if (uint8(EggAttributes.BackgroundColour) == 0) {
            backgroundcolor = "purple";
        } else if (uint8(EggAttributes.BackgroundColour) == 1) {
            backgroundcolor = "green";
        } else if (uint8(EggAttributes.BackgroundColour) == 2) {
            backgroundcolor = "red";
        } else if (uint8(EggAttributes.BackgroundColour) == 3) {
            backgroundcolor = "pink";
        } else if (uint8(EggAttributes.BackgroundColour) == 4) {
            backgroundcolor = "gray";
        } else if (uint8(EggAttributes.BackgroundColour) == 5) {
            backgroundcolor = "black";
        }

        string memory title = "Egg";
        string memory picture = string.concat(
            baseURI,
            Strings.toString(_tokenId),
            imageFileType
        );

        string memory level = Strings.toString(EggAttributes.incubatorLevel);

        string memory json = Base64.encode(
            bytes(
                string.concat(
                    string(
                        abi.encodePacked(
                            '{"name": "',
                            title,
                            " #: ",
                            Strings.toString(_tokenId),
                            '", "description": "One of the few surviving Eggs from Home!", "image": "',
                            picture,
                            '", "attributes": [ { "trait_type": "Breed", "value": "',
                            breedtype,
                            '"}, { "trait_type": "Body Color", "value": "',
                            eggcolor,
                            '"}, { "trait_type": "Fog Color", "value": "',
                            fogcolor,
                            '"}, { "trait_type": "Background Color", "value": "',
                            backgroundcolor
                        )
                    ),
                    string(
                        abi.encodePacked(
                            '"}, { "trait_type": "has Incubator", "value": "',
                            hasIncubator,
                            '"}, { "trait_type": "Incubator Color", "value": "',
                            incubatorColor,
                            '"}, { "trait_type": "Incubator Stage", "value": ',
                            '"',
                            level,
                            '"',
                            "} ]}"
                        )
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function setIncubatorFee(uint _fee) external onlyOwner{
        incubatorFee = _fee;
    }

    function setGravFee(uint[2] memory _fee) external onlyOwner{
        gravFee = _fee;
    }

    function setUSDCFee(uint[2] memory _fee) external onlyOwner{
        usdcFee = _fee;
    }

    function setMaxSupply(uint _supply) external onlyOwner{
        MAX_SUPPLY = _supply;
    }

    function setPhase1Supply(uint _supply) external onlyOwner{
        PAHSE_1_SUPPLY = _supply;
    }

    function setImageURI(string memory base,string memory fileType) external onlyOwner{
        baseURI = base;
        imageFileType = fileType;
    }



}