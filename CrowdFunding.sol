// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//This is a Crowd funding contract 
//This smart contract collects money/ether from users and uses it for charity, projects, businesses, etc.
//The owner of the contract sets rthe deadline, targets and minimum contibution limit for the contract.
//It the targets aren't accomplished or the project is aborted, the contributors can withdraw their funds or ether anytime.

contract CrowdFunding{
//First we define all the necessary variable required for the smart contract.
    mapping(address=>uint) public contributors;
    address public manager;
    uint public minimumContribution;    
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors; 

//Here we use structure to request money/ether.
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool)voters;
    }
//Here this mapping is done in order to know that's the request made for.
    mapping(uint=>Request) public requests;
    uint public numRequests;
    

    constructor(uint _target, uint _deadline){
//here cinstructor is the first function which is executed when deployed.        
        target=_target;
        deadline=block.timestamp + _deadline; 
        //while deploying, we set deadline in terms of seconds.
        //block.timestamp is a global variable through which we get to know the timestamp of current block.
        minimumContribution=100 wei;
        manager=msg.sender;
    }

    function sendEth() public payable{
        require(block.timestamp < deadline, "The deadline has passes and you cannot donate anymore.");
        require(msg.value >= minimumContribution, "The minimum cintribution is 100 wei.");

        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
//here we use this if function because we want the code to detect multiple contributions from a single contributor and count them under a single address of contributor.
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;       
    }

    function getContractBalance() public view returns (uint){
        return address(this).balance;    
    }

    function refund() public{
        require(block.timestamp>deadline && raisedAmount<target, "You are not eligible for refund.");
        require(contributors[msg.sender]>0);
        address payable user = payable(msg.sender);
//First we use 'payable' in order to transfer the refundable amount to users address.
        user.transfer(contributors[msg.sender]);
//here we transfer the value in contributors[msg.sender] to the user.
        contributors[msg.sender]=0;
    }

    modifier onlyManager(){
        require(msg.sender==manager,"Only manager can call this function.");
        _;
    }
    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests[numRequests];
//Here newRequest has Request as a data type, hence we use the keyword storage instead of memory.   
        numRequests++;
        newRequest.description=_description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.completed= false;
        newRequest.noOfVoters=0;
    }

    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0, "You have to contribute in order to vote.");
        Request storage thisRequest = requests[_requestNo];
        require (thisRequest.voters[msg.sender]==false, "You have already voted.");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++; 
    }

    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount>target);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed==false, "The request has been completed.");
        require(thisRequest.noOfVoters>noOfContributors/2,"Majority of the people does not support.");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }

}