// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Wise is Ownable {

    enum Status { SUBMITTED, ACCEPTED, MERGED, REJECTED, SPAM }

    struct Submission {
        string data_cid;
        address submitter;
        Status status;
        uint256 stake;
    }

    Submission[] public submissions;
    IERC20 public tkn;
    uint256 public stakeRequired = 0;

    event StatusChanged(uint indexed _index, Status indexed _status);

    constructor() {
        tkn = IERC20(0x98F219b94D0BC0948D0Cc15D42A8497540F3747f);
    }

    function createSubmission(string calldata data) public payable {
        require(msg.value >= stakeRequired, "Stake Ether to create a submission.");
        submissions.push(Submission(data, msg.sender, Status.SUBMITTED, msg.value));
        emit StatusChanged(submissions.length - 1, Status.SUBMITTED);
    }

    function approveSubmission(uint256 submissionIndex) public onlyOwner {
        require(submissionIndex < submissions.length, "Invalid submission index");
        submissions[submissionIndex].status = Status.ACCEPTED;
        emit StatusChanged(submissionIndex, Status.ACCEPTED);
    }

    function rejectSubmission(uint256 submissionIndex) public onlyOwner {
        require(submissionIndex < submissions.length, "Invalid submission index");
        submissions[submissionIndex].status = Status.REJECTED;
        emit StatusChanged(submissionIndex, Status.REJECTED);

    }

    function mergeSubmission(uint256 submissionIndex) public onlyOwner {
        mergeSubmissionAndPayout(submissionIndex, 0);
    }

    function mergeSubmissionAndPayout(uint256 submissionIndex, uint256 reward) public payable onlyOwner {
        require(submissionIndex < submissions.length, "Invalid submission index");
        submissions[submissionIndex].status = Status.MERGED;
        emit StatusChanged(submissionIndex, Status.MERGED);

        if (reward != 0) {
            Submission memory submission = submissions[submissionIndex];
            tkn.transfer(payable(submission.submitter), reward);
        }
    }

    // View Functions
    function getSubmissionsAtPage(uint256 page) external view returns (Submission[] memory) {
        uint pageLength = 10;
        uint paginationIndex = page * pageLength;
        uint arrAlloc = Math.min(pageLength, submissions.length - paginationIndex);

        Submission[] memory result = new Submission[](arrAlloc);

        for (uint i = 0; i < arrAlloc; i++) {
            result[i] = submissions[paginationIndex + i];
        }

        return result;
    }

    function getDescSubmissionsAtPage(uint256 page) external view returns (Submission[] memory) {
        uint pageLength = 5;
        uint paginationIndex = submissions.length - (pageLength * (page + 1));
        uint arrAlloc = Math.min(pageLength, submissions.length - paginationIndex);

        Submission[] memory result = new Submission[](arrAlloc);
        uint index = 0;

        for (uint i = 0; i < arrAlloc; i++) {
            Submission storage submission = submissions[paginationIndex + i];
            if (submission.status != Status.SPAM) {
                result[index++] = submission;
            }
        }
        return result;
    }
    
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


    function retrieveTokens() public onlyOwner {
        uint256 balance = tkn.balanceOf(address(this));
        tkn.transfer(payable(owner()), balance);
    }

    function markSubmissionAsSpam(uint256 submissionIndex) public onlyOwner {
        require(submissionIndex < submissions.length, "Invalid submission index");
        submissions[submissionIndex].status = Status.SPAM;
        emit StatusChanged(submissionIndex, Status.SPAM);
    }

    function changeSubmissionStake(uint256 _stakeRequired) public onlyOwner {
        stakeRequired = _stakeRequired;
    }

    // TESTS
    function getSubmissionAtIndex(uint256 submissionIndex) public view returns(Submission memory) {
        require(submissionIndex < submissions.length, "Invalid submission index");
        return submissions[submissionIndex];
    }
}
