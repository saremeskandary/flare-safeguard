import { BaseError as BaseViemError, ContractFunctionRevertedError } from "viem";
import { formatErrorName } from "./formatErrorName";

/**
 * Parses an viem/wagmi error to get a displayable string
 * @param e - error object
 * @returns parsed error string
 */
export const getParsedError = (error: any): string => {
  const parsedError = error?.walk ? error.walk() : error;

  if (parsedError instanceof BaseViemError) {
    if (parsedError.details) {
      return parsedError.details;
    }

    if (parsedError.shortMessage) {
      if (
        parsedError instanceof ContractFunctionRevertedError &&
        parsedError.data &&
        parsedError.data.errorName !== "Error"
      ) {
        const customErrorArgs = parsedError.data.args?.toString() ?? "";
        const formattedErrorName = formatErrorName(parsedError.data.errorName);
        return `${parsedError.shortMessage.replace(/reverted\.$/, "reverted with the following reason:")}\n${formattedErrorName}(${customErrorArgs})`;
      }

      return parsedError.shortMessage;
    }

    return parsedError.message ?? parsedError.name ?? "An unknown error occurred";
  }

  return parsedError?.message ?? "An unknown error occurred";
};
