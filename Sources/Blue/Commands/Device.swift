import ArgumentParser
import BlueKit
import Foundation
import Logging

struct DeviceCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "device",
    abstract: "Manage Bluetooth devices"
  )

  @Argument(help: "Device ID (address or name)")
  var id: String

  @Argument(help: "An action to perform")
  var action: Action

  @Option(
    name: .long,
    help: "PIN for pairing (only used with `pair` action)"
  )
  var pin: String?

  enum Action: String, CaseIterable, ExpressibleByArgument {
    case info
    case isConnected = "is-connected"
    case connect
    case disconnect
    case pair
    case unpair
  }

  func run() throws {
    let logger = BlueUtilLogger.logger
    let mgr = DeviceManager(logger: logger)

    switch action {
    case .info:
      try showInfo(mgr)
    case .isConnected:
      try checkConnected(mgr)
    case .connect:
      try doConnect(mgr)
    case .disconnect:
      try doDisconnect(mgr)
    case .pair:
      try doPair(mgr)
    case .unpair:
      try doUnpair(mgr)
    }
  }

  private func showInfo(_ mgr: DeviceManager) throws {
    BlueUtilLogger.logger.info("Showing info for \(id)")
    let device = try mgr.getDevice(identifier: id)
    print("Device Information:")
    listDevices([device], options: .all)
      .forEach { print($0) }
  }

  private func checkConnected(_ mgr: DeviceManager) throws {
    let connected = try mgr.isDeviceConnected(id)
    print(connected ? "1" : "0")
  }

  private func doConnect(_ mgr: DeviceManager) throws {
    try mgr.connectToDevice(id)
    print("Successfully connected to device \(id)")
  }

  private func doDisconnect(_ mgr: DeviceManager) throws {
    try mgr.disconnectFromDevice(id)
    print("Successfully disconnected from device \(id)")
  }

  private func doPair(_ mgr: DeviceManager) throws {
    try mgr.pairWithDevice(id, pin: pin)
    print("Successfully paired with device \(id)")
  }

  private func doUnpair(_ mgr: DeviceManager) throws {
    try mgr.unpairDevice(id)
    print("Successfully unpaired device \(id)")
  }
}
