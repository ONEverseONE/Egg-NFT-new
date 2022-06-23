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

interface VoucherIncubators is IERC721{
    function giveVoucherIncubator(uint256 _amountOfTickets, address _receiver)
        external;
}

contract Eggs is ERC721Enumerable,Ownable{


    IERC20 Grav;
    IERC20 USDC;

    Iwhitelistvouchers wlVoucher;
    VoucherIncubators incubator;

    address public paymentReceiver;

    bool USDCAllowed;
    bool GravAllowed;

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
    bool public wlPhase;
    bool public incubatorSale;

    string public baseURI;
    string public imageFileType;

    mapping(uint=>Egg) EggsMetadata;

    uint256[5][5] public COLOURRARITY = [[31,81,222,333,444],
                                        [31,81,222,333,444],
                                        [31,81,222,333,444],
                                        [31,81,222,333,444],
                                        [31,81,222,333,444]];
    uint256[4] public FOGRARITY = [100,555,1567,3333];
    uint256[6] public BACKGROUNDRARITY = [100,255,400,1110,1465,2225];
    uint256[5] public CAPSULERARITY = [155,400,1110,1665,2225];
    uint256[5] public BREEDRARITY = [1111,1111,1111,1111,1111];

    string[5] public EggColor = ["gold","purple","red","blue","gray"];
    string[4] public FogColor = ["green","purple","white","none"];
    string[5] public BreedName = ["draconesh","ichthia","khusatzal","lasseateran","mixoteran"];
    string[5] public CapsuleColor = ["gold","purple","red","blue","gray"];
    string[6] public BgColor = ["purple","green","red","pink","gray","black"];

    uint[5] public total = [5555,5555,5555,5555,5555];

    bool paused;

    constructor(address _grav,address _usdc,address _wlvoucher,address _incubators,address _paymentReceiver) ERC721("OneVerse Eggs","EGG"){
        Grav = IERC20(_grav);
        USDC = IERC20(_usdc);
        wlVoucher = Iwhitelistvouchers(_wlvoucher);
        incubator = VoucherIncubators(_incubators);
        wlPhase = true;
        Phase1 = true;
        paymentReceiver = _paymentReceiver;
    }

    modifier notPaused {
        require(!paused,"Execution paused");
        _;
    }

    function mint(uint256[] calldata _whitelistID,bool USDC_Payment) external notPaused{
        require(msg.sender == tx.origin,"Contract not allowed");
        require(wlPhase,"Neither phase 1 or 2");
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
                require(USDC.transferFrom(msg.sender, paymentReceiver, price),"Price not paid");
                incubator.giveVoucherIncubator(redeemable,msg.sender);
            }else{
                if(USDC_Payment && USDCAllowed){
                    require(USDC.transferFrom(msg.sender,paymentReceiver,usdcFee[1]*redeemable),"Not paid");
                }
                else if(!USDC_Payment && GravAllowed){
                    require(Grav.transferFrom(msg.sender,paymentReceiver,gravFee[0]*redeemable),"Not paid");
                }
                else{
                    revert("Invalid payment option");
                }
            }
            uint random = uint(vrf());
            for(uint k=0;k<redeemable;k++){
                tokenID++;
                _safeMint(msg.sender, tokenID);
                EggsMetadata[tokenID] = generateEgg(random, k);
            }
            
        }
    }

    function publicMint(uint256 _mintAmount, bool USDC_Payment) external notPaused{
        require(_mintAmount <= 10,"Only max 10 mints at once");
        require(!wlPhase,"Phase 3 not started yet");
        require(MAX_SUPPLY >= tokenID + _mintAmount,"Max supply reached");
        require(msg.sender == tx.origin,"Contract not allowed");
        if(USDC_Payment && USDCAllowed){
            require(USDC.transferFrom(msg.sender,paymentReceiver,usdcFee[2]*_mintAmount),"Not paid");
        }
        else if(!USDC_Payment && GravAllowed){
            require(Grav.transferFrom(msg.sender,paymentReceiver,gravFee[1]*_mintAmount),"Not paid");
        }
        else{
            revert("Invalid payment option");
        }
        uint random = uint(vrf());
        for(uint k=0;k<_mintAmount;k++){
            tokenID++;
            _safeMint(msg.sender, tokenID);
            EggsMetadata[tokenID] = generateEgg(random, k);
        }
    }

    function buyIncubator(uint256[] calldata _tokenIdsEggs) external{
        require(msg.sender == tx.origin, "Contracts not allowed!");
        require(incubatorSale,"Sale not started");
        uint length = _tokenIdsEggs.length;
        uint random = uint(vrf());
        for(uint i=0;i<length;i++){
            require(ownerOf(_tokenIdsEggs[i]) == msg.sender,"Not owner");
            require(!EggsMetadata[_tokenIdsEggs[i]].hasIncubator,"already incubated");
            generateIncubator(_tokenIdsEggs[i], random, i);            
        }
        Grav.transferFrom(msg.sender,paymentReceiver,incubatorFee*_tokenIdsEggs.length);
    }

    function redeemIncubator(
        uint256[] calldata _tokenIdsEggs,
        uint256[] calldata _tokenIdsVouchers
    ) external {
        require(msg.sender == tx.origin,"Contract not allowed");
        require(incubatorSale,"Sale not started");
        require(_tokenIdsEggs.length == _tokenIdsVouchers.length,"Length mismatch");
        uint length = _tokenIdsEggs.length;
        uint random = uint(vrf());
        for(uint i=0;i<length;i++){
            require(ownerOf(_tokenIdsEggs[i])==msg.sender,"Not egg owner");
            require(incubator.ownerOf(_tokenIdsVouchers[i])==msg.sender,"Not voucher owner");
            require(!EggsMetadata[_tokenIdsEggs[i]].hasIncubator,"Already incubated");
            incubator.transferFrom(msg.sender,address(this),_tokenIdsVouchers[i]);
            generateIncubator(_tokenIdsEggs[i], random, i);
        }
    }

    function generateIncubator(uint tokenId,uint random,uint salt) private {
            random = uint(keccak256(abi.encodePacked(random,salt)));

            uint randSliced = random % total[4];
            uint cumulative = 0;

            for(uint j=0;j<CAPSULERARITY.length;j++){
                if(randSliced < cumulative + CAPSULERARITY[j]){
                    EggsMetadata[tokenId].incubatorColour = j;
                    CAPSULERARITY[j]--;
                    total[4]--;
                    break;
                }
                else{
                    cumulative += CAPSULERARITY[j];
                }
            }
            EggsMetadata[tokenId].hasIncubator = true;
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

        string memory eggcolor = EggColor[EggAttributes.EggColour];
        string memory fogcolor = FogColor[EggAttributes.FogColour];
        string memory breedtype = BreedName[EggAttributes.Breed];
        string memory incubatorColor = EggAttributes.hasIncubator ? CapsuleColor[EggAttributes.incubatorColour] : "N/A";
        string memory backgroundcolor = BgColor[EggAttributes.BackgroundColour];

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

    function toggleWLPhase() external onlyOwner{
        wlPhase = !wlPhase;
    }

    function setGrav(address _grav) external onlyOwner{
        Grav = IERC20(_grav);
    }

    function setUSDC(address _usdc) external onlyOwner{
        USDC = IERC20(_usdc);
    }

    function setWLVoucher(address _voucher) external onlyOwner{
        wlVoucher = Iwhitelistvouchers(_voucher);
    }

    function setIncubator(address _incubator) external onlyOwner{
        incubator = VoucherIncubators(_incubator);
    }

    function setPaymentReceiver(address _receiver) external onlyOwner{
        paymentReceiver = _receiver;
    }

    function setImageURI(string memory base,string memory fileType) external onlyOwner{
        baseURI = base;
        imageFileType = fileType;
    }

    function togglePaused() external onlyOwner{
        paused = !paused;
    }

    function toggleUSDCPayment() external onlyOwner{
        USDCAllowed = !USDCAllowed;
    }

    function toggleGravPayment() external onlyOwner{
        GravAllowed = !GravAllowed;
    }

    function toggleIncubatorSale() external onlyOwner{
        incubatorSale = !incubatorSale;
    }

    function togglePhase1() external onlyOwner{
        Phase1 = !Phase1;
    }

}