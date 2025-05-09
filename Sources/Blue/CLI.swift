import ArgumentParser
import BlueKit
import Foundation
import Logging

/// ▰▰▰ Root command for BlueUtil CLI ▰▰▰
@main
struct RootCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "blueutil",
    abstract: "A command-line utility for controlling Bluetooth on macOS.",
    version: "2.12.0",
    subcommands: [
      DeviceCommand.self,
      GetCommand.self,
      ListCommand.self,
    ]
  )

  @Flag(name: .customLong("debug"), help: "Enable debug logging")
  var debug: Bool = false

  @Flag(name: .customLong("verbose"), help: "Enable verbose logging (implies debug)")
  var verbose: Bool = false

  func run() throws {
    // Configure logging based on debug/verbose flags
    BlueUtilLogger.configure(debug: debug, verbose: verbose)
  }
}
