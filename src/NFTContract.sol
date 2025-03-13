// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTContract is ERC721URIStorage, Ownable {
    uint256 private _tokenIds;
    address public platformAddress;

    struct TransferRequest {
        address to;
        uint256 tokenId;
        bool userApproved;
        bool platformApproved;
        bool exists;
    }

    mapping(uint256 => TransferRequest) public transferRequests;

    event TransferRequested(address indexed from, address indexed to, uint256 indexed tokenId);
    event TransferApproved(uint256 indexed tokenId, address indexed approvedBy);
    event TransferRejected(uint256 indexed tokenId, address indexed rejectedBy);
    event TransferExecuted(uint256 indexed tokenId, address indexed newOwner);
    event MetadataUpdated(uint256 indexed tokenId, string tokenURI);

    constructor(string memory name, string memory symbol, address _platformAddress) ERC721(name, symbol) {
        platformAddress = _platformAddress;
    }

    /// @notice Cria um novo NFT e define seus metadados (tokenURI)
    /// @param recipient Endereço que receberá o NFT
    /// @param tokenURI URI dos metadados do NFT
    function mint(address recipient, string memory tokenURI) external onlyOwner {
        _tokenIds++;
        _mint(recipient, _tokenIds);
        _setTokenURI(_tokenIds, tokenURI);

        emit MetadataUpdated(_tokenIds, tokenURI);
    }

    /// @notice Atualiza os metadados de um NFT (caso seja permitido)
    function updateMetadata(uint256 tokenId, string memory tokenURI) external onlyOwner {
        require(_exists(tokenId), "NFT does not exist");
        _setTokenURI(tokenId, tokenURI);

        emit MetadataUpdated(tokenId, tokenURI);
    }

    /// @notice Usuário solicita a transferência de um NFT
    /// @param tokenId ID do NFT a ser transferido
    /// @param to Endereço que receberá o NFT
    function requestTransfer(uint256 tokenId, address to) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(!transferRequests[tokenId].exists, "Transfer already requested");

        transferRequests[tokenId] = TransferRequest(to, tokenId, false, false, true);
        emit TransferRequested(msg.sender, to, tokenId);
    }

    /// @notice Aprovação de uma transferência de NFT por usuário ou plataforma
    /// @param tokenId ID do NFT cuja transferência foi solicitada
    function approveTransfer(uint256 tokenId) external {
        require(transferRequests[tokenId].exists, "No transfer requested");

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

    /// @notice Permite que o usuário ou a plataforma rejeitem uma transferência pendente
    function rejectTransfer(uint256 tokenId) external {
        require(transferRequests[tokenId].exists, "No transfer requested");
        require(msg.sender == ownerOf(tokenId) || msg.sender == platformAddress, "Unauthorized rejection");

        delete transferRequests[tokenId];
        emit TransferRejected(tokenId, msg.sender);
    }
}
