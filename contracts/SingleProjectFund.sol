// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SingleProjectFund {
    
  struct AddressSet {
    address payable[] values;
    mapping (address => bool) exists;
  }

  struct Project {
    string name;
    uint256 goal;
    address payable owner;
  }
  
  Project project;
  bool isOpen;
  uint256 balance;
  
  mapping(address => uint256) funds;
  AddressSet funders;
  
  constructor(string memory _name, uint256 _goal) {
    project = Project(_name, _goal, payable(msg.sender));
    isOpen = true;
    balance = 0;
  }
  
  event funded(
    address sender,
    uint256 sent
  );
  
  event closed(
    address sender,
    uint256 sent
  );

  modifier onlyOwner {
    require(
      msg.sender == project.owner,
      "Just the owner can modify this project"
    );
    _;
  }
  
  modifier notOwner {
    require(
      msg.sender != project.owner,
      "As onwer you cant fund your own project"
    );
    _;
  }
  
  function _addFunder(address _funder) private {
    if(!funders.exists[_funder]) {
      funders.values.push(payable(_funder));
      funders.exists[_funder] = true;
    }
  }

  function fundProject() payable public notOwner {
    require(
      isOpen,
      "Project is not open for fund raising"
    );
    require(
      uint(msg.value) > 0,
      "Amount must be greater than 0"
    );
    require(
      balance + uint(msg.value) <= project.goal,
      "Amount exceeds goal"
    );
    
    funds[msg.sender] += msg.value;
    _addFunder(msg.sender);
    
    emit funded(msg.sender, msg.value);
    
    balance += uint(msg.value);
    
    if (balance == project.goal) {
      isOpen = false;
      project.owner.transfer(project.goal);
      emit closed(msg.sender, msg.value);
    }
  }
  
  function getOwner() public view returns (address) {
    return project.owner;
  }
  
  function totalFunders() public view returns (uint256) {
    return funders.values.length;
  }

  function isClosed() public view returns (bool) {
    return !isOpen;
  }

  function getRemaining() public view returns (uint256) {
    return project.goal - balance;
  }
  
  function getName() public view returns (string memory) {
    return project.name;
  }

  function setName(string calldata _name) onlyOwner public {
    project.name = _name;
  }
  
  function getMyContribution() notOwner public view returns (uint256) {
    return funds[msg.sender];
  }

  function closeProject() public onlyOwner {
    isOpen = false;
    emit closed(msg.sender, 0);
    
    for(uint8 i; i < funders.values.length; i++) {
      funders.values[i].transfer(funds[funders.values[i]]);
    }
  }
}