/**
 * Formats an error name from the ABI into a more readable format
 * @param errorName - The error name from the ABI
 * @returns Formatted error name
 */
export const formatErrorName = (errorName: string): string => {
  // If the error name is already in a readable format (contains spaces), return it as is
  if (errorName.includes(" ")) {
    return errorName;
  }

  // Handle camelCase
  if (/[a-z][A-Z]/.test(errorName)) {
    return errorName
      .replace(/([a-z])([A-Z])/g, "$1 $2")
      .replace(/([A-Z])([A-Z][a-z])/g, "$1 $2");
  }

  // Handle snake_case
  if (errorName.includes("_")) {
    return errorName
      .split("_")
      .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join(" ");
  }

  // Handle PascalCase
  return errorName
    .replace(/([A-Z])/g, " $1")
    .trim()
    .replace(/^./, str => str.toUpperCase());
}; 