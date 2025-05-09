import Foundation
import IOBluetooth
import Logging

/// ▰▰▰ Manages system Bluetooth state ▰▰▰
public class BluetoothManager {
  private let logger: Logger

  /// Initialize with optional custom logger
  /// - Parameter logger: Logger instance to use
  public init(logger: Logger = BlueUtilLogger.logger) {
    self.logger = logger
  }

  /// Get the power state of Bluetooth
  /// - Returns: Power state as Int (0 = off, 1 = on)
  /// - Throws: BluetoothError if unable to get power state
  public func getPowerState() throws -> Int {
    logger.info("Getting power state")
    let host = IOBluetoothHostController.init()

    let raw = host.powerState.rawValue
    logger.debug("Power state raw value: \(raw)")
    return Int(raw)
  }

  /// Get the discoverable state of Bluetooth
  /// - Returns: Discoverable state as Boolean
  /// - Throws: BluetoothError if unable to get discoverable state
  public func getDiscoverableState() throws -> Bool {
    logger.info("Getting discoverable state")

    // Note: This is a placeholder as the original code didn't have
    // a real implementation. In a real implementation, we would
    // use the appropriate IOBluetooth API to get this state.
    return true
  }

  /// Get all paired devices
  /// - Returns: Array of paired IOBluetoothDevice objects
  public func getPairedDevices() -> [IOBluetoothDevice] {
    logger.info("Getting paired devices")
    if let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
      logger.debug("Found \(pairedDevices.count) paired devices")
      return pairedDevices
    } else {
      logger.warning("Could not retrieve paired devices, returning empty array")
      return []
    }
  }

  /// Get all connected devices
  /// - Returns: Array of connected IOBluetoothDevice objects
  public func getConnectedDevices() -> [IOBluetoothDevice] {
    logger.info("Getting connected devices")
    let pairedDevices = getPairedDevices()
    let connectedDevices = pairedDevices.filter { $0.isConnected() }
    logger.debug("Found \(connectedDevices.count) connected devices")
    return connectedDevices
  }
}
