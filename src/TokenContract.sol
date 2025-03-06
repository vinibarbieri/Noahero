// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TokenContract is ERC20, Ownable {
    address public platformAddress;

    struct TransferRequest {
        address to;
        uint256 amount;
        bool userApproved;
        bool platformApproved;
    }

    mapping(address => TransferRequest) public transferRequests;

    event TransferRequested(address indexed from, address indexed to, uint256 amount);
    event TransferApproved(address indexed user, address indexed approvedBy);
    event TransferExecuted(address indexed user, address indexed to, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 initialSupply, address _platformAddress) 
        ERC20(name, symbol) 
    {
        _mint(msg.sender, initialSupply);
        platformAddress = _platformAddress;
    }

    function requestTransfer(address to, uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        transferRequests[msg.sender] = TransferRequest(to, amount, false, false);
        emit TransferRequested(msg.sender, to, amount);
    }

    function approveTransfer(address user) external {
        require(transferRequests[user].amount > 0, "No transfer requested");
        if (msg.sender == user) {
            transferRequests[user].userApproved = true;
        } else if (msg.sender == platformAddress) {
            transferRequests[user].platformApproved = true;
        } else {
            revert("Unauthorized approval");
        }
        emit TransferApproved(user, msg.sender);

        if (transferRequests[user].userApproved && transferRequests[user].platformApproved) {
            _transfer(user, transferRequests[user].to, transferRequests[user].amount);
            emit TransferExecuted(user, transferRequests[user].to, transferRequests[user].amount);
            delete transferRequests[user];
        }
    }
}
