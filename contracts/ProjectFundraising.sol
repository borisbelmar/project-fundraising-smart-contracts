// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ProjectFundraising {
  enum Status { Open, Paused, Closed }
    
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
  Status status;
  uint256 balance;
  
  mapping(address => uint256) funds;
  AddressSet funders;
  
  constructor(string memory _name, uint256 _goal) {
    project = Project(_name, _goal, payable(msg.sender));
    status = Status.Open;
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
      status != Status.Paused,
      "Project is paused for fund raising. Stay tuned!"
    );
    require(
      status != Status.Closed,
      "Project is closed for fund raising"
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
      status = Status.Closed;
      project.owner.transfer(project.goal);
      emit closed(msg.sender, msg.value);
    }
  }

  function getProject() public view returns (Project memory) {
    return project;
  }
  
  function getOwner() public view returns (address) {
    return project.owner;
  }
  
  function totalFunders() public view returns (uint256) {
    return funders.values.length;
  }
  
  function getStatus() public view returns (string memory) {
    if (status == Status.Open) return "The project is open";
    if (status == Status.Closed) return "The project is closed";
    if (status == Status.Paused) return "The project is paused";
    return "";
  }

  function isClosed() public view returns (bool) {
    return status == Status.Closed;
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

  function pauseProject() onlyOwner public {
    require(
      status == Status.Open,
      "This project is not open and cant be paused"
    );
    status = Status.Paused;
  }
  
  function resumeProject() onlyOwner public {
    require(
      status == Status.Paused,
      "This project is not paused and cant be resumed"
    );
    status = Status.Open;
  }

  function closeProject() public onlyOwner {
    require(
      status != Status.Closed,
      "This project is already closed"
    );
    status = Status.Closed;
    emit closed(msg.sender, 0);
    
    for(uint8 i; i < funders.values.length; i++) {
      funders.values[i].transfer(funds[funders.values[i]]);
    }
  }
}