import ArgumentParser
import BlueKit
import Foundation
import IOBluetooth
import Logging

struct ListCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list",
    abstract: "List Bluetooth devices",
    subcommands: [
      Inquiry.self,
      Paired.self,
      Connected.self,
    ],
    defaultSubcommand: Paired.self
  )
}

struct Inquiry: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "inquiry",
    abstract: "Inquiry devices in range"
  )

  @Argument(
    help: "Inquiry duration in seconds (default: 10)"
  )
  var duration: Int?

  func run() throws {
    let logger = BlueUtilLogger.logger
    let deviceManager = DeviceManager(logger: logger)
    let timeout = Double(duration ?? 10)
    logger.info("Inquiring for \(timeout) seconds")
    let devices = try deviceManager.getDevicesInRange(timeout: timeout)
    let opts = defaultPrintOptions()
    printDevices(devices, with: opts)
  }
}

struct Paired: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "paired",
    abstract: "List paired devices"
  )

  func run() throws {
    let logger = BlueUtilLogger.logger
    let bt = BluetoothManager(logger: logger)
    logger.info("Listing paired devices")
    let devices = bt.getPairedDevices()
    var opts = defaultPrintOptions()
    opts.showPairing = false
    printDevices(devices, with: opts)
  }
}

struct Connected: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "connected",
    abstract: "List connected devices"
  )

  func run() throws {
    let logger = BlueUtilLogger.logger
    let bt = BluetoothManager(logger: logger)
    logger.info("Listing connected devices")
    let devices = bt.getConnectedDevices()
    var opts = defaultPrintOptions()
    opts.showConnected = false
    printDevices(devices, with: opts)
  }
}

private func defaultPrintOptions() -> DevicePrintOptions {
  DevicePrintOptions(
    showAddress: true,
    showName: true,
    showConnected: true,
    showRSSI: true,
    showPairing: true,
    showIsIncoming: true
  )
}

private func printDevices(
  _ devices: [IOBluetoothDevice],
  with options: DevicePrintOptions
) {
  let logger = BlueUtilLogger.logger
  logger.debug("Listing \(devices.count) devices")

  guard !devices.isEmpty else {
    print("No devices found.")
    return
  }

  for device in devices {
    var pieces = [String]()
    autoreleasepool {
      if options.showAddress, let addr = device.addressString {
        pieces.append("Address: \(addr)")
      }
      if options.showName {
        let name = device.nameOrAddress ?? "-"
        pieces.append("Name: \(name)")
      }
      if options.showConnected {
        let c = device.isConnected() ? "Yes" : "No"
        pieces.append("Connected: \(c)")
      }
      if options.showRSSI {
        pieces.append("RSSI: \(device.rawRSSI()) dbm")
      }
      if options.showPairing {
        let p = device.isPaired() ? "Yes" : "No"
        pieces.append("Paired: \(p)")
      }
      if options.showIsIncoming {
        let i = device.isIncoming() ? "Yes" : "No"
        pieces.append("Incoming: \(i)")
      }
    }
    print(pieces.joined(separator: ", "))
  }
}
