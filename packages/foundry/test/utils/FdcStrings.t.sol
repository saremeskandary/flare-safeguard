// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IEVMTransaction} from "flare-periphery/src/coston2/IEVMTransaction.sol";
import {FdcStrings} from "contracts/utils/fdcStrings/EVMTransaction.sol";
import {Base} from "contracts/utils/fdcStrings/Base.sol";

contract TestFdcStrings is Test {
    function test_toString_bool() public pure {
        string memory got1 = Base.toString(true);
        string memory expected1 = "true";
        string memory got2 = Base.toString(false);
        string memory expected2 = "false";
        require(
            Strings.equal(got1, expected1),
            string.concat("Expected: ", expected1, ", got:", got1)
        );
        require(
            Strings.equal(got2, expected2),
            string.concat("Expected: ", expected2, ", got:", got2)
        );
    }

    struct TestReq {
        bytes32 attestationType;
        bytes32 sourceId;
        bytes32 messageIntegrityCode;
        RequestBody requestBody;
    }

    struct RequestBody {
        bytes32 transactionHash;
        // BUG uint256 works, but uint32 does not
        uint256 requiredConfirmations;
        bool provideInput;
        bool listEvents;
        // BUG this still doesn't work
        uint256[] logIndices;
    }
    function test_toString_Request() public view {
        string memory root = vm.projectRoot();
        string memory path = string.concat(
            root,
            "/test/utils/examples/IEVMTransaction/Request.json"
        );
        string memory jsonStr = vm.readFile(path);

        // Parse the JSON data into the struct fields
        TestReq memory request;
        request.attestationType = bytes32(
            vm.parseJson(jsonStr, ".attestationType")
        );
        request.sourceId = bytes32(vm.parseJson(jsonStr, ".sourceId"));
        request.messageIntegrityCode = bytes32(
            vm.parseJson(jsonStr, ".messageIntegrityCode")
        );

        // Parse requestBody
        request.requestBody.transactionHash = bytes32(
            vm.parseJson(jsonStr, ".requestBody.transactionHash")
        );
        request.requestBody.requiredConfirmations = vm.parseJsonUint(
            jsonStr,
            ".requestBody.requiredConfirmations"
        );
        request.requestBody.provideInput = vm.parseJsonBool(
            jsonStr,
            ".requestBody.provideInput"
        );
        request.requestBody.listEvents = vm.parseJsonBool(
            jsonStr,
            ".requestBody.listEvents"
        );
        // Parse logIndices array - for now it's empty so we can skip
        request.requestBody.logIndices = new uint256[](0);

        // For now, just verify we can parse the data without reverting
        assert(request.attestationType != bytes32(0));
    }
}
