import Foundation

/// ▰▰▰ Bluetooth-related errors ▰▰▰ //
public enum BluetoothError: Error, LocalizedError {
  /// Invalid device identifier format
  case invalidIdentifier(identifier: String)

  /// Device not found with the given identifier
  case deviceNotFound(identifier: String)

  /// Failed to establish connection with device
  case connectionFailed(String)

  /// Required data was missing
  case missingData(String)

  /// Operation could not be completed
  case operationFailed(String)

  /// Operation timed out
  case timeoutError(String)

  /// Bluetooth in invalid state for operation
  case invalidState(String)

  /// Invalid argument provided
  case invalidArgument(String)

  public var errorDescription: String? {
    switch self {
    case .invalidIdentifier(let identifier):
      return "Invalid device identifier: \(identifier)"
    case .deviceNotFound(let identifier):
      return "Device not found: \(identifier)"
    case .connectionFailed(let message):
      return "Connection failed: \(message)"
    case .missingData(let message):
      return "Missing data: \(message)"
    case .operationFailed(let message):
      return "Operation failed: \(message)"
    case .timeoutError(let message):
      return "Operation timed out: \(message)"
    case .invalidState(let message):
      return "Invalid state: \(message)"
    case .invalidArgument(let message):
      return "Invalid argument: \(message)"
    }
  }
}
