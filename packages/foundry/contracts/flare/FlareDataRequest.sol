// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFlareDataFetcher.sol";

/**
 * @title FlareDataRequest contract used for data fetching
 */
abstract contract FlareDataRequest is Ownable {
    IFlareDataFetcher public dataFetcher;
    address public dataFetcherAddress;

    bytes32 public s_lastRequestId;
    bool public s_settled;

    // Event to log responses
    event DataRequestSent(
        bytes32 indexed requestId,
        address indexed tokenRWA,
        string symbol
    );
    event DataResponseReceived(
        bytes32 indexed requestId,
        bytes data,
        bool success
    );
    event DataRequestFailed(bytes32 indexed requestId, string reason);

    constructor(address dataFetcherAddress_) Ownable(msg.sender) {
        require(
            dataFetcherAddress_ != address(0),
            "FlareDataRequest: dataFetcherAddress_ cannot be zero"
        );
        dataFetcherAddress = dataFetcherAddress_;
        dataFetcher = IFlareDataFetcher(dataFetcherAddress_);
    }

    function sendGetLiquidationRequest(
        address tokenRWA,
        string memory symbol
    ) public payable virtual {
        IFlareDataFetcher.DataRequest memory request = IFlareDataFetcher
            .DataRequest({
                url: "https://api.example.com/liquidation",
                path: string(abi.encodePacked("/", symbol)),
                headers: "",
                timeout: 300 // 5 minutes timeout
            });
        try dataFetcher.requestData{value: msg.value}(request) returns (
            bytes32 requestId
        ) {
            s_lastRequestId = requestId;
            emit DataRequestSent(requestId, tokenRWA, symbol);
        } catch Error(string memory reason) {
            emit DataRequestFailed(s_lastRequestId, reason);
        } catch (bytes memory) {
            emit DataRequestFailed(s_lastRequestId, "InsufficientFee");
        }
    }

    /// @notice Check if a response is available and process it
    /// @param _requestId The request ID to check
    function checkResponse(bytes32 _requestId) external {
        (bool isCompleted, bool isSuccessful) = dataFetcher.getRequestStatus(
            _requestId
        );

        if (!isCompleted) {
            return; // Response not yet available
        }

        IFlareDataFetcher.DataResponse memory response = dataFetcher
            .getResponse(_requestId);

        if (isSuccessful) {
            s_settled = abi.decode(response.data, (uint256)) == 1;
            emit DataResponseReceived(_requestId, response.data, true);

            // Process the response
            callVaultHandleRWAPayment();
        } else {
            emit DataResponseReceived(_requestId, response.data, false);
        }
    }

    /// @notice Update the data fetcher address
    /// @param _dataFetcherAddress The new data fetcher address
    function updateDataFetcher(address _dataFetcherAddress) external onlyOwner {
        require(
            _dataFetcherAddress != address(0),
            "FlareDataRequest: _dataFetcherAddress cannot be zero"
        );
        dataFetcherAddress = _dataFetcherAddress;
        dataFetcher = IFlareDataFetcher(_dataFetcherAddress);
    }

    function callVaultHandleRWAPayment() public virtual;
}
