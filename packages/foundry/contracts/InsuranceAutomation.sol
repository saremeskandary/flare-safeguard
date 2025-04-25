// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./mock/MockTokenInsurance.sol";

/**
 * @title Insurance Automation
 * @dev Handles automated tasks for insurance contracts
 *
 * The Insurance Automation contract is designed to:
 * - Schedule and execute automated tasks for insurance contracts
 * - Manage recurring payments and operations for RWA token insurance
 * - Provide a mechanism for time-based automation of insurance processes
 * - Enable decentralized execution of scheduled insurance operations
 *
 * This contract works with TokenInsurance contracts to automate:
 * - Premium payments
 * - Coverage renewals
 * - Policy expirations
 * - Automated claim processing triggers
 * - Other time-sensitive insurance operations
 *
 * The automation system uses a task-based approach where each task
 * represents a specific operation to be performed at a scheduled time.
 */
contract InsuranceAutomation is Ownable {
    // Custom errors
    error InvalidInsuranceContractAddress();
    error DueDateMustBeInFuture();
    error TaskDoesNotExist();
    error TaskAlreadyExecuted();
    error TaskNotDueYet();

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

    /**
     * @dev Constructor initializes the contract with the deployer as owner
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @notice Create a new automation task
     * @param _insuranceContract The address of the insurance contract
     * @param _dueDate The due date for the task
     *
     * This function allows the owner to schedule a new automation task for
     * a specific insurance contract. The task will be executed when the
     * current time reaches the due date. Tasks are identified by a unique
     * hash generated from the contract address, due date, and creation timestamp.
     */
    function createTask(
        address _insuranceContract,
        uint256 _dueDate
    ) external onlyOwner {
        if (_insuranceContract == address(0))
            revert InvalidInsuranceContractAddress();
        if (_dueDate <= block.timestamp) revert DueDateMustBeInFuture();

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

    /**
     * @notice Execute a task if it's due
     * @param _taskId The ID of the task to execute
     *
     * This function executes a scheduled task if the current time has reached
     * or passed the due date. It calls the appropriate function on the
     * insurance contract, such as handling RWA payments or processing claims.
     * Once executed, a task cannot be executed again.
     */
    function executeTask(bytes32 _taskId) external {
        AutomationTask storage task = tasks[_taskId];
        if (task.insuranceContract == address(0)) revert TaskDoesNotExist();
        if (task.executed) revert TaskAlreadyExecuted();
        if (block.timestamp < task.dueDate) revert TaskNotDueYet();

        task.executed = true;
        TokenInsurance(task.insuranceContract).callVaultHandleRWAPayment();

        emit TaskExecuted(_taskId, task.insuranceContract);
    }

    /**
     * @notice Remove a task
     * @param _taskId The ID of the task to remove
     *
     * This function allows the owner to cancel a scheduled task before it
     * is executed. It removes the task from storage and updates the
     * associated insurance contract's task list.
     */
    function removeTask(bytes32 _taskId) external onlyOwner {
        AutomationTask storage task = tasks[_taskId];
        if (task.insuranceContract == address(0)) revert TaskDoesNotExist();
        if (task.executed) revert TaskAlreadyExecuted();

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

    /**
     * @notice Get all tasks for an insurance contract
     * @param _insuranceContract The address of the insurance contract
     * @return taskIds Array of task IDs
     *
     * This function returns all task IDs associated with a specific
     * insurance contract, allowing for easy tracking of scheduled operations.
     */
    function getInsuranceTasks(
        address _insuranceContract
    ) external view returns (bytes32[] memory taskIds) {
        return insuranceTasks[_insuranceContract];
    }

    /**
     * @notice Get task details
     * @param _taskId The ID of the task
     * @return insuranceContract The address of the insurance contract
     * @return dueDate The due date of the task
     * @return executed Whether the task has been executed
     *
     * This function returns the details of a specific task, including
     * the associated insurance contract, due date, and execution status.
     */
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
