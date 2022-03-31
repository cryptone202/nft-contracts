// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title HexarchiaWarlords
 * HexarchiaWarlords - Smart contract for Hexarchia Warlords characters
 */
contract HexarchiaWarlords is ERC721, Ownable {
    mapping(uint256 => bool) private _revealedNFTs;
    mapping(address => bool) private _minters;
    address openseaProxyAddress;
    address umiProxyAddress;
    string public contract_ipfs_json;
    string public contract_base_uri;
    string private baseURI;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    bool public is_collection_revealed = false;
    string public notrevealed_nft = "https://api.hexarchia.com/warlords/awakening.json";
    uint256 HARD_CAP = 7680;

    constructor(
        address _openseaProxyAddress,
        string memory _name,
        string memory _ticker,
        string memory _contract_ipfs,
        address _umiProxyAddress
    ) ERC721(_name, _ticker) {
        openseaProxyAddress = _openseaProxyAddress;
        umiProxyAddress = _umiProxyAddress;
        contract_ipfs_json = _contract_ipfs;
        contract_base_uri = "https://api.hexarchia.com/warlords/";
    }

    function _baseURI() internal override view returns (string memory) {
        return contract_base_uri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if(is_collection_revealed == true){
            string memory _tknId = Strings.toString(_tokenId);
            return string(abi.encodePacked(contract_base_uri, _tknId, ".json"));
        } else {
            if(_revealedNFTs[_tokenId] == true) {
                string memory _tknId = Strings.toString(_tokenId);
                return string(abi.encodePacked(contract_base_uri, _tknId, ".json"));
            } else {
                return notrevealed_nft;
            }
        }
    }

    function contractURI() public view returns (string memory) {
        return contract_ipfs_json;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalWarlords = totalSupply();
            uint256 resultIndex = 0;
            uint256 warlordId;

            for (warlordId = 1; warlordId <= totalWarlords; warlordId++) {
                if (ownerOf(warlordId) == _owner) {
                    result[resultIndex] = warlordId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /*
        This method will mint the token to provided user, can be called just by the proxy address.
    */
    function proxyMintNFT(address _to)
        public
    {
        require(isMinter(msg.sender), "Hexarchia: Only minters can mint");
        uint256 reached = _tokenIdCounter.current() + 1;
        require(reached <= HARD_CAP, "Hexarchia: Hard cap reached");
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _mint(_to, newTokenId);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /*
        This method will allow owner to fix the contract details
     */

    function fixContractDescription(string memory newDescription) public onlyOwner {
        contract_ipfs_json = newDescription;
    }

    /*
        This method will allow owner to fix the contract baseURI
     */

    function fixBaseURI(string memory newURI) public onlyOwner {
        contract_base_uri = newURI;
    }

    /*
        These methods will add or remove minting roles.
    */
    function isMinter(address _toCheck) public view returns (bool) {
        return _minters[_toCheck] == true;
    }

    function addMinter(address _toAdd) public onlyOwner {
        _minters[_toAdd] = true;
    }

    function removeMinter(address _toRemove) public onlyOwner {
        _minters[_toRemove] = false;
    }

    /*
        This method will allow owner reveal the collection
     */

    function revealCollection() public onlyOwner {
        is_collection_revealed = true;
    }

    /*
        This method will reveal the NFT
    */
    function revealNFT(uint256 _tokenId) public returns (bool) {
        require(ownerOf(_tokenId) == msg.sender, "Hexarchia Warlords: You must own the NFT");
        _revealedNFTs[_tokenId] = true;
        return true;
    }

    function isRevealed(uint256 _tokenId) public view returns (bool) {
        return _revealedNFTs[_tokenId];
    }

    /**
     * Override isApprovedForAll to whitelist proxy accounts
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        override
        view
        returns (bool isOperator)
    {
        // Approving for UMi and Opensea address
        if (
            _operator == address(openseaProxyAddress)
        ) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }
}
