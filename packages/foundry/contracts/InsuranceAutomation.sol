// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "dependencies/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./mock/MockTokenInsurance.sol";

/// @title InsuranceAutomation
/// @notice Handles automated tasks for insurance contracts
contract InsuranceAutomation is Ownable {
    struct AutomationTask {
        address insuranceContract;
        uint256 dueDate;
        bool executed;
    }

    mapping(bytes32 => AutomationTask) public tasks;
    mapping(address => bytes32[]) public insuranceTasks;

    event TaskCreated(
        bytes32 indexed taskId,
        address indexed insuranceContract,
        uint256 dueDate
    );
    event TaskExecuted(
        bytes32 indexed taskId,
        address indexed insuranceContract
    );
    event TaskRemoved(
        bytes32 indexed taskId,
        address indexed insuranceContract
    );

    constructor() Ownable(msg.sender) {}

    /// @notice Create a new automation task
    /// @param _insuranceContract The address of the insurance contract
    /// @param _dueDate The due date for the task
    function createTask(
        address _insuranceContract,
        uint256 _dueDate
    ) external onlyOwner {
        require(
            _insuranceContract != address(0),
            "Invalid insurance contract address"
        );
        require(_dueDate > block.timestamp, "Due date must be in the future");

        bytes32 taskId = keccak256(
            abi.encodePacked(_insuranceContract, _dueDate, block.timestamp)
        );

        tasks[taskId] = AutomationTask({
            insuranceContract: _insuranceContract,
            dueDate: _dueDate,
            executed: false
        });

        insuranceTasks[_insuranceContract].push(taskId);

        emit TaskCreated(taskId, _insuranceContract, _dueDate);
    }

    /// @notice Execute a task if it's due
    /// @param _taskId The ID of the task to execute
    function executeTask(bytes32 _taskId) external {
        AutomationTask storage task = tasks[_taskId];
        require(task.insuranceContract != address(0), "Task does not exist");
        require(!task.executed, "Task already executed");
        require(block.timestamp >= task.dueDate, "Task not due yet");

        task.executed = true;
        TokenInsurance(task.insuranceContract).callVaultHandleRWAPayment();

        emit TaskExecuted(_taskId, task.insuranceContract);
    }

    /// @notice Remove a task
    /// @param _taskId The ID of the task to remove
    function removeTask(bytes32 _taskId) external onlyOwner {
        AutomationTask storage task = tasks[_taskId];
        require(task.insuranceContract != address(0), "Task does not exist");
        require(!task.executed, "Task already executed");

        delete tasks[_taskId];

        // Remove task ID from insurance tasks array
        bytes32[] storage taskIds = insuranceTasks[task.insuranceContract];
        for (uint256 i = 0; i < taskIds.length; i++) {
            if (taskIds[i] == _taskId) {
                taskIds[i] = taskIds[taskIds.length - 1];
                taskIds.pop();
                break;
            }
        }

        emit TaskRemoved(_taskId, task.insuranceContract);
    }

    /// @notice Get all tasks for an insurance contract
    /// @param _insuranceContract The address of the insurance contract
    /// @return taskIds Array of task IDs
    function getInsuranceTasks(
        address _insuranceContract
    ) external view returns (bytes32[] memory taskIds) {
        return insuranceTasks[_insuranceContract];
    }

    /// @notice Get task details
    /// @param _taskId The ID of the task
    /// @return insuranceContract The address of the insurance contract
    /// @return dueDate The due date of the task
    /// @return executed Whether the task has been executed
    function getTaskDetails(
        bytes32 _taskId
    )
        external
        view
        returns (address insuranceContract, uint256 dueDate, bool executed)
    {
        AutomationTask storage task = tasks[_taskId];
        return (task.insuranceContract, task.dueDate, task.executed);
    }
}
