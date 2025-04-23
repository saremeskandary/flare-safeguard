// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../../lib/flare-periphery-0.0.22/src/coston2/FtsoV2Interface.sol";

contract MockFtsoV2Interface is FtsoV2Interface {
    function getFeedById(
        bytes21 _feedId
    )
        external
        payable
        returns (uint256 _value, int8 _decimals, uint64 _timestamp)
    {
        return (1000 ether, 18, uint64(block.timestamp));
    }

    function getFeedByIdInWei(
        bytes21 _feedId
    ) external payable returns (uint256 _value, uint64 _timestamp) {
        return (1000 ether, uint64(block.timestamp));
    }

    function getFeedByIndex(
        uint256 _index
    )
        external
        payable
        returns (uint256 _value, int8 _decimals, uint64 _timestamp)
    {
        return (1000 ether, 18, uint64(block.timestamp));
    }

    function getFeedByIndexInWei(
        uint256 _index
    ) external payable returns (uint256 _value, uint64 _timestamp) {
        return (1000 ether, uint64(block.timestamp));
    }

    function getFeedId(uint256 _index) external view returns (bytes21 _feedId) {
        return bytes21(uint168(0x123456789012345678901234567890123456789012));
    }

    function getFeedIndex(
        bytes21 _feedId
    ) external view returns (uint256 _index) {
        return 0;
    }

    function getFeedsById(
        bytes21[] calldata _feedIds
    )
        external
        payable
        returns (
            uint256[] memory _values,
            int8[] memory _decimals,
            uint64 _timestamp
        )
    {
        _values = new uint256[](_feedIds.length);
        _decimals = new int8[](_feedIds.length);

        for (uint256 i = 0; i < _feedIds.length; i++) {
            _values[i] = 1000 ether;
            _decimals[i] = 18;
        }
        return (_values, _decimals, uint64(block.timestamp));
    }

    function getFeedsByIdInWei(
        bytes21[] calldata _feedIds
    ) external payable returns (uint256[] memory _values, uint64 _timestamp) {
        _values = new uint256[](_feedIds.length);

        for (uint256 i = 0; i < _feedIds.length; i++) {
            _values[i] = 1000 ether;
        }
        return (_values, uint64(block.timestamp));
    }

    function getFeedsByIndex(
        uint256[] calldata _indices
    )
        external
        payable
        returns (
            uint256[] memory _values,
            int8[] memory _decimals,
            uint64 _timestamp
        )
    {
        _values = new uint256[](_indices.length);
        _decimals = new int8[](_indices.length);

        for (uint256 i = 0; i < _indices.length; i++) {
            _values[i] = 1000 ether;
            _decimals[i] = 18;
        }
        return (_values, _decimals, uint64(block.timestamp));
    }

    function getFeedsByIndexInWei(
        uint256[] calldata _indices
    ) external payable returns (uint256[] memory _values, uint64 _timestamp) {
        _values = new uint256[](_indices.length);

        for (uint256 i = 0; i < _indices.length; i++) {
            _values[i] = 1000 ether;
        }
        return (_values, uint64(block.timestamp));
    }

    function verifyFeedData(
        FeedDataWithProof calldata _feedData
    ) external view returns (bool) {
        return true;
    }
}
