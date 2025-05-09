import ArgumentParser
import BlueKit
import Foundation
import IOBluetooth
import Logging

/// ▰▰▰ List command for listing Bluetooth devices ▰▰▰
struct ListCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list",
    abstract: "List Bluetooth devices"
  )

  @Option(help: "Inquiry devices in range, duration in seconds (default 10)")
  var inquiry: Int?

  @Flag(help: "List paired devices")
  var paired: Bool = false

  @Flag(help: "List connected devices")
  var connected: Bool = false

  func run() throws {
    let logger = BlueUtilLogger.logger
    let deviceManager = DeviceManager(logger: logger)
    let bluetoothManager = BluetoothManager(logger: logger)

    logger.info("Running List command")

    // Default options for device printing
    var printOptions = DevicePrintOptions(
      showAddress: true,
      showName: true,
      showConnected: true,
      showRSSI: true,
      showPairing: true,
      showIsIncoming: true
    )

    if let duration = inquiry {
      logger.info("Inquiring for \(duration) seconds")
      let devices = try deviceManager.getDevicesInRange(duration: Double(duration))
      let deviceInfo = listDevices(devices, options: printOptions)
      for line in deviceInfo {
        print(line)
      }
    } else if paired {
      logger.info("Listing paired devices")
      let pairedDevices = bluetoothManager.getPairedDevices()
      printOptions.showPairing = false
      let deviceInfo = deviceManager.listDevices(pairedDevices, options: printOptions)
      for line in deviceInfo {
        print(line)
      }
    } else if connected {
      logger.info("Listing connected devices")
      let connectedDevices = bluetoothManager.getConnectedDevices()
      printOptions.showConnected = false
      let deviceInfo = deviceManager.listDevices(connectedDevices, options: printOptions)
      for line in deviceInfo {
        print(line)
      }
    } else {
      logger.info("No specific list option selected, showing paired devices")
      let pairedDevices = bluetoothManager.getPairedDevices()
      let deviceInfo = deviceManager.listDevices(pairedDevices, options: printOptions)
      for line in deviceInfo {
        print(line)
      }
    }
  }
}

/// List devices with specified print options
/// - Parameters:
///   - devices: Array of IOBluetoothDevice instances
///   - options: DevicePrintOptions defining what information to show
func listDevices(_ devices: [IOBluetoothDevice], options: DevicePrintOptions) -> [String] {
  let logger = BlueUtilLogger.logger
  logger.debug("Listing \(devices.count) devices")

  var output = [String]()

  if devices.isEmpty {
    output.append("No devices found.")
    return output
  }

  for device in devices {
    do {
      var deviceInfo = [String]()

      try autoreleasepool {
        if options.showAddress, let addressString = device.addressString {
          deviceInfo.append("Address: \(addressString)")
        }

        if options.showName {
          let nameOrAddress = device.nameOrAddress ?? "-"
          deviceInfo.append("Name: \(nameOrAddress)")
        }

        if options.showConnected {
          let isConnected = device.isConnected()
          deviceInfo.append("Connected: \(isConnected ? "Yes" : "No")")
        }

        if options.showRSSI {
          deviceInfo.append("RSSI: \(device.rawRSSI()) dbm")
        }

        if options.showPairing {
          deviceInfo.append("Paired: \(device.isPaired() ? "Yes" : "No")")
        }

        if options.showIsIncoming {
          deviceInfo.append("Incoming: \(device.isIncoming() ? "Yes" : "No")")
        }
      }

      output.append(deviceInfo.joined(separator: ", "))
    } catch {
      logger.error("Error processing device: \(error.localizedDescription)")
    }
  }

  return output
}
