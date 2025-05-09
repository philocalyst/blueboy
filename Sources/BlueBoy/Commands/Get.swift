import ArgumentParser
import BlueKit
import Foundation
import Logging

struct GetCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get",
    abstract: "Retrieve Bluetooth system states",
    subcommands: [Power.self]
  )

  func run() throws {
    // no-op: prints help by default
  }
}

struct Power: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "power",
    abstract: "Output power status as 1 or 0"
  )

  @MainActor
  func run() throws {
    let logger = BlueBoyLogger.logger
    let manager = BluetoothManager(logger: logger)

    logger.info("Retrieving power state")
    let state = try manager.getPowerState()
    // `state` is 1 or 0
    print(state)
  }
}
