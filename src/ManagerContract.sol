// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./NFTContract.sol";
import "./TokenContract.sol";

contract ManagerContract {
    address public owner;
    address public platformAddress;

    struct Company {
        address nftContract;
        address tokenContract;
        bool exists;
    }

    mapping(address => Company) public companies;

    event CompanyCreated(address indexed company, address nftContract, address tokenContract);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address _platformAddress) {
        owner = msg.sender;
        platformAddress = _platformAddress;
    }

    function createCompany(string memory nftName, string memory nftSymbol, string memory tokenName, string memory tokenSymbol, uint256 initialSupply) external {
        require(!companies[msg.sender].exists, "Company already exists");

        NFTContract nftContract = new NFTContract(nftName, nftSymbol, platformAddress);
        TokenContract tokenContract = new TokenContract(tokenName, tokenSymbol, initialSupply, platformAddress);

        companies[msg.sender] = Company(address(nftContract), address(tokenContract), true);

        emit CompanyCreated(msg.sender, address(nftContract), address(tokenContract));
    }

    function getCompanyContracts(address company) external view returns (address nftContract, address tokenContract) {
        require(companies[company].exists, "Company does not exist");
        return (companies[company].nftContract, companies[company].tokenContract);
    }
}
