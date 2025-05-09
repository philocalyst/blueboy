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
      InRange.self,
      Paired.self,
      Connected.self,
    ]
  )
}

struct InRange: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "in-range",
    abstract: "Inquire devices in range"
  )

  @Argument(
    help: "Inquiry duration in seconds (default: 10)"
  )
  var duration: Int?

  @MainActor
  func run() throws {
    let logger = BlueBoyLogger.logger
    let deviceManager = DeviceManager()
    let timeout = Double(duration ?? 10)
    logger.info("Inquiring for \(timeout) seconds")
    let devices = try deviceManager.getDevicesInRange(timeout: timeout)
    let opts = DevicePrintOptions.basic
    printDevices(devices, with: opts)
  }
}

struct Paired: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "paired",
    abstract: "List paired devices"
  )

  @MainActor
  func run() throws {
    let logger = BlueBoyLogger.logger
    let bt = BluetoothManager()
    logger.info("Listing paired devices")
    let devices = bt.getPairedDevices()
    var opts = DevicePrintOptions.basic
    opts.showPairing = false
    printDevices(devices, with: opts)
  }
}

struct Connected: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "connected",
    abstract: "List connected devices"
  )

  @MainActor
  func run() throws {
    let logger = BlueBoyLogger.logger
    let bt = BluetoothManager()
    logger.info("Listing connected devices")
    let devices = bt.getConnectedDevices()
    var opts = DevicePrintOptions.basic
    opts.showConnected = false
    printDevices(devices, with: opts)
  }
}
