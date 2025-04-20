// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IFlareDataFetcher.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract FlareDataFetcher is IFlareDataFetcher, Ownable, ReentrancyGuard {
    mapping(bytes32 => DataRequest) private requests;
    mapping(bytes32 => DataResponse) private responses;
    mapping(bytes32 => bool) private completedRequests;

    uint256 public constant MINIMUM_FEE = 0.01 ether; // Minimum fee for data requests
    uint256 public constant MAX_TIMEOUT = 3600; // Maximum timeout in seconds (1 hour)

    error InvalidRequest();
    error RequestNotFound();
    error RequestAlreadyCompleted();
    error InsufficientFee();
    error InvalidTimeout();

    constructor() Ownable(msg.sender) {}

    function requestData(
        DataRequest calldata _request
    ) external payable override nonReentrant returns (bytes32 requestId) {
        if (msg.value < MINIMUM_FEE) revert InsufficientFee();
        if (_request.timeout > MAX_TIMEOUT) revert InvalidTimeout();
        if (bytes(_request.url).length == 0) revert InvalidRequest();

        requestId = keccak256(
            abi.encodePacked(
                msg.sender,
                _request.url,
                _request.path,
                block.timestamp
            )
        );

        requests[requestId] = _request;

        emit DataRequestSent(
            requestId,
            msg.sender,
            _request.url,
            _request.path
        );

        // In a real implementation, this would trigger an off-chain process
        // For this example, we'll simulate a response after a delay
        // In production, this would be handled by an oracle or off-chain service

        // Transfer any excess fee back to the sender
        if (msg.value > MINIMUM_FEE) {
            payable(msg.sender).transfer(msg.value - MINIMUM_FEE);
        }

        return requestId;
    }

    // This function would be called by an oracle or off-chain service
    // to provide the response data
    function fulfillRequest(
        bytes32 _requestId,
        bytes calldata _data,
        bool _success
    ) external onlyOwner {
        if (completedRequests[_requestId]) revert RequestAlreadyCompleted();

        DataRequest memory request = requests[_requestId];
        if (request.timeout == 0) revert RequestNotFound();

        responses[_requestId] = DataResponse({
            data: _data,
            timestamp: block.timestamp,
            success: _success
        });

        completedRequests[_requestId] = true;

        emit DataResponseReceived(_requestId, _data, block.timestamp, _success);
    }

    function getResponse(
        bytes32 _requestId
    ) external view override returns (DataResponse memory) {
        if (!completedRequests[_requestId]) revert RequestNotFound();
        return responses[_requestId];
    }

    function getRequest(
        bytes32 _requestId
    ) external view override returns (DataRequest memory) {
        DataRequest memory request = requests[_requestId];
        if (request.timeout == 0) revert RequestNotFound();
        return request;
    }

    function getRequestStatus(
        bytes32 _requestId
    ) external view override returns (bool isCompleted, bool isSuccessful) {
        if (requests[_requestId].timeout == 0) revert RequestNotFound();
        return (
            completedRequests[_requestId],
            completedRequests[_requestId]
                ? responses[_requestId].success
                : false
        );
    }

    // Function to withdraw accumulated fees
    function withdrawFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
