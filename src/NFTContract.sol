// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract NFTContract is ERC721, Ownable {
    uint256 private _tokenIds;
    address public platformAddress;
    
    struct TransferRequest {
        address to;
        uint256 tokenId;
        bool userApproved;
        bool platformApproved;
    }

    mapping(uint256 => TransferRequest) public transferRequests;

    event TransferRequested(address indexed from, address indexed to, uint256 indexed tokenId);
    event TransferApproved(uint256 indexed tokenId, address indexed approvedBy);
    event TransferExecuted(uint256 indexed tokenId, address indexed newOwner);

    constructor(string memory name, string memory symbol, address _platformAddress) ERC721(name, symbol) {
        platformAddress = _platformAddress;
    }

    function mint(address recipient) external onlyOwner {
        _tokenIds++;
        _mint(recipient, _tokenIds);
    }

    function requestTransfer(uint256 tokenId, address to) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        transferRequests[tokenId] = TransferRequest(to, tokenId, false, false);
        emit TransferRequested(msg.sender, to, tokenId);
    }

    function approveTransfer(uint256 tokenId) external {
        require(transferRequests[tokenId].tokenId == tokenId, "Invalid transfer request");
        if (msg.sender == ownerOf(tokenId)) {
            transferRequests[tokenId].userApproved = true;
        } else if (msg.sender == platformAddress) {
            transferRequests[tokenId].platformApproved = true;
        } else {
            revert("Unauthorized approval");
        }
        emit TransferApproved(tokenId, msg.sender);

        if (transferRequests[tokenId].userApproved && transferRequests[tokenId].platformApproved) {
            _transfer(ownerOf(tokenId), transferRequests[tokenId].to, tokenId);
            emit TransferExecuted(tokenId, transferRequests[tokenId].to);
            delete transferRequests[tokenId];
        }
    }
}
