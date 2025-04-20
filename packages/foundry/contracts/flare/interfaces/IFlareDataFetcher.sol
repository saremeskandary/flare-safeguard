// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IFlareDataFetcher {
    function MINIMUM_FEE() external view returns (uint256);

    struct DataRequest {
        string url;
        string path;
        bytes headers;
        uint256 timeout;
    }

    struct DataResponse {
        bytes data;
        uint256 timestamp;
        bool success;
    }

    event DataRequestSent(
        bytes32 indexed requestId,
        address indexed requester,
        string url,
        string path
    );

    event DataResponseReceived(
        bytes32 indexed requestId,
        bytes data,
        uint256 timestamp,
        bool success
    );

    function requestData(
        DataRequest calldata _request
    ) external payable returns (bytes32 requestId);

    function getResponse(
        bytes32 _requestId
    ) external view returns (DataResponse memory);

    function getRequest(
        bytes32 _requestId
    ) external view returns (DataRequest memory);

    function getRequestStatus(
        bytes32 _requestId
    ) external view returns (bool isCompleted, bool isSuccessful);
}
