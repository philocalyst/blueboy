import ArgumentParser
import BlueKit
import Foundation
import Logging

/// ▰▰▰ Get command for retrieving system Bluetooth states ▰▰▰
struct GetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get Bluetooth system states"
    )

    @Flag(
        name: [.short, .customLong("discoverable")],
        help: "Output discoverable state as 1 or 0"
    )
    var discoverableStateOutput: Bool = false

    @Flag(
        name: [.short, .customLong("power")],
        help: "Output power status as 1 or 0"
    )
    var powerStateOutput: Bool = false

    func run() throws {
        let logger = BlueUtilLogger.logger
        let bluetoothManager = BluetoothManager(logger: logger)

        logger.info("Running Get command")

        if discoverableStateOutput {
            try getDiscoverableState(bluetoothManager: bluetoothManager)
        }

        if powerStateOutput {
            try getPowerState(bluetoothManager: bluetoothManager)
        }

        if !discoverableStateOutput && !powerStateOutput {
            logger.warning("No state retrieval specified")
            print("No state retrieval specified")
        }
    }

    private func getDiscoverableState(bluetoothManager: BluetoothManager) throws {
        let isDiscoverable = try bluetoothManager.getDiscoverableState()
        print(isDiscoverable ? "1" : "0")
    }

    private func getPowerState(bluetoothManager: BluetoothManager) throws {
        let powerState = try bluetoothManager.getPowerState()
        print(powerState)
    }
}
